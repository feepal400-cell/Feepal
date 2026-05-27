import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VoucherPdfService {
  /// Generates a 3-part Fee Voucher PDF (Bank, School, Student Copies)
  static Future<pw.Document> generateVoucher({
    required Map<String, dynamic> schoolData,
    required Map<String, dynamic> studentData,
    required Map<String, dynamic> feeData,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();

    // Load fonts for better Urdu support or just clean styling
    // Using standard Helvetica/Courier for now, but adding a nice sans font if possible
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Business Logic: Terminology mapping
    final baseFeeLabel = "Base Fee"; // Replaced from Tuition Fee
    final additionalChargesLabel = "Additional Charges"; // Replaced from Other Charges

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              _buildVoucherCopy(
                title: "BANK COPY",
                schoolData: schoolData,
                studentData: studentData,
                feeData: feeData,
                font: font,
                fontBold: fontBold,
                logoBytes: logoBytes,
                baseFeeLabel: baseFeeLabel,
                additionalChargesLabel: additionalChargesLabel,
              ),
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 1, color: PdfColors.grey, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 2),
              _buildVoucherCopy(
                title: "SCHOOL COPY",
                schoolData: schoolData,
                studentData: studentData,
                feeData: feeData,
                font: font,
                fontBold: fontBold,
                logoBytes: logoBytes,
                baseFeeLabel: baseFeeLabel,
                additionalChargesLabel: additionalChargesLabel,
              ),
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 1, color: PdfColors.grey, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 2),
              _buildVoucherCopy(
                title: "STUDENT COPY",
                schoolData: schoolData,
                studentData: studentData,
                feeData: feeData,
                font: font,
                fontBold: fontBold,
                logoBytes: logoBytes,
                baseFeeLabel: baseFeeLabel,
                additionalChargesLabel: additionalChargesLabel,
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildVoucherCopy({
    required String title,
    required Map<String, dynamic> schoolData,
    required Map<String, dynamic> studentData,
    required Map<String, dynamic> feeData,
    required pw.Font font,
    required pw.Font fontBold,
    Uint8List? logoBytes,
    required String baseFeeLabel,
    required String additionalChargesLabel,
  }) {
    final isInstallment = feeData['paymentType'] == 'Installment';
    final totalAmount = double.tryParse(feeData['totalAmount']?.toString() ?? '0') ?? 0.0;
    final baseFee = double.tryParse(feeData['baseFee']?.toString() ?? '0') ?? 0.0;
    final additionalCharges = double.tryParse(feeData['additionalCharges']?.toString() ?? '0') ?? 0.0;
    final lateFee = double.tryParse(feeData['lateFeeAmount']?.toString() ?? '0') ?? 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoBytes != null)
                pw.Image(pw.MemoryImage(logoBytes), width: 30, height: 30)
              else
                pw.SizedBox(width: 30, height: 30),
              pw.Column(
                children: [
                  pw.Text(schoolData['schoolName'] ?? 'FEEPAL SCHOOL', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.Text(schoolData['schoolAddress'] ?? '', style: pw.TextStyle(font: font, fontSize: 7)),
                  pw.Text("Contact: ${schoolData['phoneNumber'] ?? ''}", style: pw.TextStyle(font: font, fontSize: 7)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 9)),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          
          // Bank Details
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(2),
            color: PdfColors.grey100,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Bank: ${schoolData['bankName'] ?? 'N/A'}", style: pw.TextStyle(font: font, fontSize: 8)),
                pw.Text("A/C Title: ${schoolData['accountTitle'] ?? 'N/A'}", style: pw.TextStyle(font: font, fontSize: 8)),
                pw.Text("A/C No: ${schoolData['accountNumber'] ?? 'N/A'}", style: pw.TextStyle(font: fontBold, fontSize: 9)),
              ],
            ),
          ),
          pw.SizedBox(height: 3),

          // Student Info & Voucher Meta
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow("Student Name", studentData['studentName'], font, fontBold),
                    _infoRow("Father Name", studentData['parentName'], font, fontBold),
                    _infoRow("Roll No", studentData['rollNumber'], font, fontBold),
                    _infoRow("Class", studentData['class'], font, fontBold),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Voucher ID: ${feeData['voucherId'] ?? 'N/A'}", style: pw.TextStyle(font: font, fontSize: 8)),
                    pw.Text("Month: ${feeData['feeMonth'] ?? 'N/A'}", style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.Text("Due Date: ${feeData['dueDate'] ?? 'N/A'}", style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.red)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),

          // Fee Breakdown Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text("Description", style: pw.TextStyle(font: fontBold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text("Amount (Rs)", style: pw.TextStyle(font: fontBold, fontSize: 8), textAlign: pw.TextAlign.right)),
                ],
              ),
              if (!isInstallment) ...[
                _tableRow(baseFeeLabel, baseFee.toInt().toString(), font),
                _tableRow(additionalChargesLabel, additionalCharges.toInt().toString(), font),
              ] else ...[
                _tableRow("Installment ${feeData['installmentNumber'] ?? '1'} of ${feeData['totalInstallments'] ?? '2'}", totalAmount.toInt().toString(), font),
                _tableRow("Breakdown (Monthly Share)", "${(baseFee + additionalCharges).toInt()}", font, isItalic: true),
              ],
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text("TOTAL PAYABLE (BY DUE DATE)", style: pw.TextStyle(font: fontBold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text("Rs. ${totalAmount.toInt()}", style: pw.TextStyle(font: fontBold, fontSize: 9), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text("Late Fee After ${feeData['dueDate']}", style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey700))),
                  pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text("Rs. ${lateFee.toInt()}", style: pw.TextStyle(font: font, fontSize: 7), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text("TOTAL PAYABLE (AFTER DUE DATE)", style: pw.TextStyle(font: fontBold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text("Rs. ${(totalAmount + lateFee).toInt()}", style: pw.TextStyle(font: fontBold, fontSize: 9), textAlign: pw.TextAlign.right)),
                ],
              ),
            ],
          ),
          
          pw.SizedBox(height: 30),
          // Footer Instructions
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text("Note: This is a computer generated voucher.", style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey600)),
              pw.Container(
                width: 110,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(width: 0.5)),
                ),
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text("Authorized Sign", style: pw.TextStyle(font: font, fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String? value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 60, child: pw.Text("$label:", style: pw.TextStyle(font: font, fontSize: 8))),
          pw.Text(value ?? 'N/A', style: pw.TextStyle(font: fontBold, fontSize: 8)),
        ],
      ),
    );
  }

  static pw.TableRow _tableRow(String label, String value, pw.Font font, {bool isItalic = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8, fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal))),
        pw.Padding(padding: const pw.EdgeInsets.all(1), child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 8), textAlign: pw.TextAlign.right)),
      ],
    );
  }

  /// Triggers the Print/Preview Dialog
  static Future<void> printVoucher(pw.Document pdf, String fileName) async {
    debugPrint("📄 [PDF DEBUG] Starting PDF save process...");
    final Uint8List bytes = await pdf.save();
    
    debugPrint("📊 [PDF DEBUG] PDF Generated. Size: ${bytes.length} bytes");
    
    if (bytes.isEmpty) {
      debugPrint("❌ [PDF DEBUG] ABORT: PDF is empty (0 bytes)!");
      return;
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: fileName,
    );
    debugPrint("✅ [PDF DEBUG] Printing layout triggered for: $fileName");
  }
}
