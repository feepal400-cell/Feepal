import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class OcrValidationResult {
  final bool success;
  final String? errorMessage;
  final String? transactionId;

  OcrValidationResult({required this.success, this.errorMessage, this.transactionId});
}

class OcrService {

  /// Helper to get common acronyms for Pakistani banks
  static String? _getBankAcronym(String bankName) {
    final lowerBank = bankName.toLowerCase();
    if (lowerBank.contains('habib bank') || lowerBank.contains('hbl')) return 'HBL';
    if (lowerBank.contains('united bank') || lowerBank.contains('ubl')) return 'UBL';
    if (lowerBank.contains('mcb')) return 'MCB';
    if (lowerBank.contains('allied bank') || lowerBank.contains('abl')) return 'ABL';
    if (lowerBank.contains('national bank') || lowerBank.contains('nbp')) return 'NBP';
    // Add others if needed
    return null;
  }

  /// Validates a physical bank voucher using on-device OCR and business rules.
  /// 
  /// [imageFile]: The image file of the physical voucher.
  /// [currentVoucher]: The voucher data from Firestore currently being verified.
  /// [allVouchers]: All vouchers belonging to the student to check for past dues.
  /// [expectedAmount]: The exact expected amount (including any additional/late fees, or divided for installment).
  /// [adminBankName]: The bank name saved in the Admin's profile.
  static Future<OcrValidationResult> validateVoucher({
    required File imageFile,
    required Map<String, dynamic> currentVoucher,
    required List<Map<String, dynamic>> allVouchers,
    required double expectedAmount,
    required String adminBankName,
    int? currentInstallmentNumber,
    String? schoolName,
    String? schoolAddress,
    String? voucherType,
  }) async {
    try {
      // ----------------------------------------------------------------------
      // Rule A: Past Dues Priority
      // Check all previous chronological monthly documents.
      // ----------------------------------------------------------------------
      final String? currentMonthYearStr = currentVoucher['monthYear'];
      if (currentMonthYearStr != null && currentMonthYearStr != 'N/A') {
        try {
          final DateTime currentVoucherDate = DateFormat('MM-yyyy').parse(currentMonthYearStr);

          for (var voucher in allVouchers) {
            final String? vMonthYear = voucher['monthYear'];
            if (vMonthYear == null || vMonthYear == 'N/A') continue;

            final DateTime vDate = DateFormat('MM-yyyy').parse(vMonthYear);
            
            // Check if this voucher is strictly older chronologically
            if (vDate.isBefore(currentVoucherDate)) {
              // Check if it's unpaid
              final String status = voucher['status']?.toString().toLowerCase() ?? 'unpaid';
              if (status == 'unpaid' || status == 'pending_manual') {
                return OcrValidationResult(
                  success: false,
                  errorMessage: "Error: Past dues must be cleared before paying current installments.",
                );
              }
              
              // Also check if any installments within that older voucher are unpaid
              if (voucher['installments'] != null && voucher['installments'] is List) {
                final List installments = voucher['installments'] as List;
                bool hasUnpaidInstallment = installments.any((inst) {
                  final String instStatus = inst['status']?.toString().toLowerCase() ?? 'unpaid';
                  return instStatus == 'unpaid' || instStatus == 'pending_manual';
                });
                
                if (hasUnpaidInstallment) {
                   return OcrValidationResult(
                    success: false,
                    errorMessage: "Error: Past dues must be cleared before paying current installments.",
                  );
                }
              }
            }
          }
        } catch (e) {
          debugPrint("OCR Rule A error parsing dates: $e");
        }
      }

      // ----------------------------------------------------------------------
      // Execute Gatekeeper (OCR only)
      // ----------------------------------------------------------------------
      final inputImage = InputImage.fromFile(imageFile);
      
      final ocrResult = await _verifyOCRText(
        inputImage, 
        currentMonthYearStr ?? '', 
        allVouchers, 
        currentInstallmentNumber,
        schoolName: schoolName,
        schoolAddress: schoolAddress,
        voucherType: voucherType,
        expectedAmount: expectedAmount.toStringAsFixed(0),
      );
      if (!ocrResult.success) {
        return ocrResult;
      }

      return ocrResult;

    } catch (e) {
      debugPrint("OCR Processing Error: $e");
      return OcrValidationResult(
        success: false,
        errorMessage: "Error: An unexpected error occurred while processing the image. Please try again.",
      );
    }
  }

  static Future<OcrValidationResult> _verifyOCRText(
    InputImage inputImage, 
    String expectedMonth, 
    List<Map<String, dynamic>> allVouchers, 
    int? currentInstallmentNumber, {
    String? schoolName,
    String? schoolAddress,
    String? voucherType,
    String? expectedAmount,
  }) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final fullText = recognizedText.text.toUpperCase();
      
      debugPrint("--- OCR EXTRACTED TEXT ---");
      debugPrint(fullText);
      debugPrint("--------------------------");
      
      // Regex 1: Keywords
      final keywordRegex = RegExp(r'(PAID|RECEIVED|CASH|TRX ID|STAN)');
      if (!keywordRegex.hasMatch(fullText)) {
        return OcrValidationResult(success: false, errorMessage: "Voucher validation failed. Please ensure the bank print/stamp is clearly visible.");
      }
      
      // Cross-School Security Constraints
      if (schoolName != null && schoolName.isNotEmpty) {
        // Just checking some part of the school name to avoid false negatives due to minor OCR errors
        List<String> nameParts = schoolName.toUpperCase().split(' ').where((s) => s.length > 3).toList();
        bool foundName = false;
        if (nameParts.isEmpty) {
          foundName = fullText.contains(schoolName.toUpperCase().replaceAll(' ', ''));
        } else {
          for (String part in nameParts) {
            if (fullText.contains(part)) {
              foundName = true;
              break;
            }
          }
        }
        if (!foundName && nameParts.isNotEmpty) {
           // As a fallback, check if any 4-letter sequence matches
           foundName = fullText.contains(schoolName.toUpperCase().substring(0, schoolName.length > 4 ? 4 : schoolName.length));
        }
        if (!foundName && schoolName.length > 3) {
          return OcrValidationResult(success: false, errorMessage: "Error: Cross-school validation failed. The school name on the voucher does not match.");
        }
      }

      if (expectedAmount != null && expectedAmount.isNotEmpty) {
         if (!fullText.contains(expectedAmount)) {
             return OcrValidationResult(success: false, errorMessage: "Error: Amount validation failed. The paid amount on the voucher does not match the expected amount (Rs. $expectedAmount).");
         }
      }

      if (voucherType != null && voucherType.isNotEmpty) {
         if (voucherType.toUpperCase() == 'INSTALLMENT' && !fullText.contains('INST')) {
            // Optional strict check
         }
      }
      
      // Regex 2: Transaction ID (10 to 16 alphanumeric characters, MUST contain at least one digit)
      final trxRegex = RegExp(r'\b(?=.*\d)[A-Z0-9]{10,16}\b');
      final trxMatches = trxRegex.allMatches(fullText);
      if (trxMatches.isEmpty) {
        return OcrValidationResult(success: false, errorMessage: "Voucher validation failed. Please ensure the bank print/stamp is clearly visible.");
      }
      
      String extractedTrxId = trxMatches.first.group(0)!;
      
      // Deduplication Check
      for (var match in trxMatches) {
          String potentialTrx = match.group(0)!;
          for (var v in allVouchers) {
             if (v['transactionId'] == potentialTrx) {
                 return OcrValidationResult(success: false, errorMessage: "Error: This transaction proof has already been submitted for a previous installment. Duplicated proofs are not allowed.");
             }
             if (v['installments'] != null && v['installments'] is List) {
                 for (var inst in v['installments']) {
                     if (inst['transactionId'] == potentialTrx) {
                         return OcrValidationResult(success: false, errorMessage: "Error: This transaction proof has already been submitted for a previous installment. Duplicated proofs are not allowed.");
                     }
                 }
             }
          }
      }

      // Explicit Installment Text Matching
      if (currentInstallmentNumber != null) {
          final mismatchRegex = RegExp(r'\b(?:INST|INSTALLMENT|INSTALL)\s*(0?[1-9])\b|\b(0?[1-9])(?:ST|ND|RD|TH)\s*(?:INST|INSTALLMENT|INSTALL)\b', caseSensitive: false);
          final matches = mismatchRegex.allMatches(fullText);
          for (var match in matches) {
              String? digitStr = match.group(1) ?? match.group(2);
              if (digitStr != null) {
                  int digit = int.parse(digitStr);
                  if (digit != currentInstallmentNumber) {
                       return OcrValidationResult(success: false, errorMessage: "Error: Installment mismatch. You are uploading a proof for a different installment than the one selected.");
                  }
              }
          }
      }
      
      // Regex 3: Date Matching
      final dateMatches = RegExp(r'\b(\d{2})[-/\s]([A-Z]{3,}|\d{2})[-/\s](\d{2,4})\b', caseSensitive: false).allMatches(fullText);
      bool hasValidDate = false;
      
      List<String> parts = expectedMonth.split('-');
      if (parts.length == 2) {
         String expM = parts[0];
         String expY = parts[1];
         String expMonthName = _getMonthName(expM);
         
         for (var match in dateMatches) {
            String m = match.group(2)!.toUpperCase();
            String y = match.group(3)!;
            
            // Allow matching 2-digit years (e.g. 26 for 2026)
            if (y == expY || y == expY.substring(2)) {
               // Allow matching '06' or 'JUN'
               if (m == expM || (expMonthName.isNotEmpty && m.startsWith(expMonthName))) {
                  hasValidDate = true;
                  break;
               }
            }
         }
      }
      
      if (!hasValidDate) {
        return OcrValidationResult(success: false, errorMessage: "Voucher validation failed. Please ensure the bank print/stamp is clearly visible.");
      }

      // Regex 4: Authorized Sign
      final signRegex = RegExp(r'(SIGN|AUTHORIZED|AUTHORISED)', caseSensitive: false);
      if (!signRegex.hasMatch(fullText)) {
        return OcrValidationResult(success: false, errorMessage: "Voucher validation failed. Missing Authorized Sign.");
      }
      
      return OcrValidationResult(success: true, transactionId: extractedTrxId);
    } finally {
      textRecognizer.close();
    }
  }

  static String _getMonthName(String mm) {
    switch(mm) {
      case '01': return 'JAN';
      case '02': return 'FEB';
      case '03': return 'MAR';
      case '04': return 'APR';
      case '05': return 'MAY';
      case '06': return 'JUN';
      case '07': return 'JUL';
      case '08': return 'AUG';
      case '09': return 'SEP';
      case '10': return 'OCT';
      case '11': return 'NOV';
      case '12': return 'DEC';
      default: return '';
    }
  }

  static void dispose() {
    // Left for backwards compatibility if called elsewhere
  }
}
