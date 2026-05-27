import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  final String _baseUrl = 'https://api.resend.com/emails';
  final String _fromEmail = 'FeePal <notifications@system.feepal.online>';
  final String _userAgent = 'FeePal/1.0';

  String get _apiKey => dotenv.env['RESEND_API_KEY'] ?? '';


  Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint('❌ EmailService: API Key is missing. Check your .env file.');
      return false;
    }

    final String finalToAddress = to;
    final String finalSubject = subject;

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
              'User-Agent': _userAgent,
            },
            body: jsonEncode({
              'from': _fromEmail,
              'to': finalToAddress,
              'subject': finalSubject,
              'html': html,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '✅ EmailService: Email sent successfully to $finalToAddress',
        );
        return true;
      } else {
        // 🔥 Senior Engineer Debugging: Print full response body for troubleshooting
        debugPrint(
          '❌ EmailService Error (${response.statusCode}): ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ EmailService Exception: $e');
      return false;
    }
  }

  String _getBaseTemplate(String content, {String primaryColor = '#2168F8'}) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f7fa; }
        .container { max-width: 600px; margin: 20px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); }
        .header { background: $primaryColor; padding: 30px; text-align: center; color: #ffffff; }
        .content { padding: 40px; }
        .footer { background: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8; }
        .button { display: inline-block; padding: 12px 24px; background-color: $primaryColor; color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: bold; margin-top: 20px; }
        .info-card { background: #f1f5f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .alert { color: #ef4444; font-weight: bold; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1 style="margin:0;">FeePal </h1>
        </div>
        <div class="content">
          $content
        </div>
        <div class="footer">
          &copy; 2026 FeePal Team. All rights reserved.<br>
          Making school management effortless.
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Scenario 1: Welcome Email
  Future<bool> sendWelcomeEmail(
    String toEmail,
    String role,
    String name,
  ) async {
    final isParent = role.toLowerCase() == 'parent';
    final primaryColor = isParent ? '#00D4FF' : '#2168F8';

    final content =
        '''
      <h2>Welcome to FeePal, $name!</h2>
      <p>We're thrilled to have you join our platform. FeePal is designed to make school fee management simple, transparent, and fast.</p>
      <div class="info-card">
        <strong>Role:</strong> $role<br>
        <strong>Next Steps:</strong> ${isParent ? 'View your child\'s fee status and download vouchers.' : 'Set up your school profile and start managing students.'}
      </div>
      <p>If you have any questions, our support team is always here to help.</p>
      <a href="#" class="button">Go to Dashboard</a>
    ''';

    return await _sendEmail(
      to: toEmail,
      subject: 'Welcome to FeePal!',
      html: _getBaseTemplate(content, primaryColor: primaryColor),
    );
  }

  // Scenario 2: Subscription Proof Uploaded
  Future<bool> sendSubscriptionProofAlert(
    String schoolName,
    String adminEmail,
  ) async {
    final content =
        '''
      <h2>New Subscription Proof Uploaded</h2>
      <p>A school administrator has uploaded a payment voucher for verification.</p>
      <div class="info-card">
        <strong>School:</strong> $schoolName<br>
        <strong>Admin Email:</strong> $adminEmail<br>
        <strong>Status:</strong> Pending Verification
      </div>
      <p>Please log in to the Super Admin Dashboard to review the payment proof and activate the subscription.</p>
      <a href="#" class="button">Review Proof</a>
    ''';

    return await _sendEmail(
      to: 'notifications@system.feepal.online', // Target: FeePal Team
      subject: 'Action Required: New Subscription Proof for $schoolName',
      html: _getBaseTemplate(content),
    );
  }

  // Scenario 3: Subscription Activated
  Future<bool> sendSubscriptionActivated(
    String adminEmail,
    String schoolName,
  ) async {
    final content =
        '''
      <h2>Congratulations!</h2>
      <p>Your FeePal premium subscription for <strong>$schoolName</strong> has been successfully activated.</p>
      <div class="info-card">
        <strong>Account Status:</strong> Active<br>
        <strong>Plan:</strong> Premium Tier
      </div>
      <p>You now have full access to all features, including automated fee generation and parent notifications.</p>
      <a href="#" class="button">Explore Features</a>
    ''';

    return await _sendEmail(
      to: adminEmail,
      subject: 'Your FeePal Subscription is Active!',
      html: _getBaseTemplate(
        content,
        primaryColor: '#10b981',
      ), // Green for success
    );
  }

  // Scenario 4: Fee Generated for Parent
  Future<bool> sendFeeGeneratedEmail({
    required String parentEmail,
    required String studentName,
    required double totalFee,
    required String dueDate,
    required bool canDoInstallments,
    required bool hasOldDues,
  }) async {
    final content =
        '''
      <h2>New Fee Voucher Generated</h2>
      <p>A new fee voucher has been issued for <strong>$studentName</strong>.</p>
      <div class="info-card">
        <h3 style="margin-top:0;">Payment Summary</h3>
        <strong>Total Amount:</strong> Rs. ${totalFee.toStringAsFixed(2)}<br>
        <strong>Due Date:</strong> $dueDate<br>
        <hr style="border:0; border-top: 1px solid #cbd5e1; margin: 10px 0;">
        <strong>Installments:</strong> ${canDoInstallments ? 'Allowed' : 'Not Available'}<br>
        ${hasOldDues ? '<p class="alert">⚠️ Warning: You have outstanding arrears. Previous dues must be cleared first.</p>' : ''}
      </div>
      <p>Please download the voucher from the FeePal app and upload the payment proof once paid.</p>
      <a href="#" class="button" style="background-color: #00D4FF;">View Voucher</a>
    ''';

    return await _sendEmail(
      to: parentEmail,
      subject: 'Fee Voucher for $studentName - Action Required',
      html: _getBaseTemplate(content, primaryColor: '#00D4FF'),
    );
  }

  // Scenario 5: Parent Uploads Voucher
  Future<bool> sendParentVoucherAlert(
    String adminEmail,
    String studentName,
    String month,
  ) async {
    final content =
        '''
      <h2>Payment Proof Received</h2>
      <p>A parent has uploaded a paid voucher for <strong>$studentName</strong> for the month of <strong>$month</strong>.</p>
      <div class="info-card">
        <strong>Student:</strong> $studentName<br>
        <strong>Month:</strong> $month<br>
        <strong>Status:</strong> Payment Uploaded
      </div>
      <p>Please verify the payment in your Admin Dashboard to update the student's fee status.</p>
      <a href="#" class="button">Verify Payment</a>
    ''';

    return await _sendEmail(
      to: adminEmail,
      subject: 'New Payment Proof: $studentName ($month)',
      html: _getBaseTemplate(content),
    );
  }

  // Scenario 5.1: OCR Verification Success
  Future<bool> sendOcrSuccessEmail(
    String parentEmail,
    String messageTemplate,
  ) async {
    final content =
        '''
      <h2>Payment Verified Successfully</h2>
      <div class="info-card" style="border-left: 4px solid #10b981;">
        <p style="font-size: 16px; margin: 0;">$messageTemplate</p>
      </div>
      <p>Thank you for using FeePal!</p>
    ''';

    return await _sendEmail(
      to: parentEmail,
      subject: 'Fee Payment Verified',
      html: _getBaseTemplate(content, primaryColor: '#10b981'),
    );
  }

  // Scenario 6: Priority Reminders
  Future<bool> sendPriorityReminder(
    String parentEmail,
    String studentName,
    String customMessage,
  ) async {
    final content =
        '''
      <h2 style="color: #ef4444;">Urgent Priority Reminder</h2>
      <p>This is an important notification regarding <strong>$studentName</strong>.</p>
      <div class="info-card" style="border-left: 4px solid #ef4444;">
        <p style="margin:0;">$customMessage</p>
      </div>
      <p>Please address this matter immediately to avoid any inconvenience.</p>
      <a href="#" class="button" style="background-color: #ef4444;">Take Action Now</a>
    ''';

    return await _sendEmail(
      to: parentEmail,
      subject: 'Urgent: Priority Notification for $studentName',
      html: _getBaseTemplate(content, primaryColor: '#ef4444'),
    );
  }

  // Scenario 7: Verification OTP (Generic)
  Future<bool> sendVerificationOTP({
    required String userEmail,
    required String otpCode,
    String? reason,
  }) async {
    final String instruction = reason ?? 'identity verification';
    final content =
        '''
      <div style="text-align: center;">
        <h2>Verify Your Identity</h2>
        <p>You are performing <strong>$instruction</strong>. Please use the following 6-digit code to proceed:</p>
        <div style="background: #f1f5f9; padding: 25px; border-radius: 12px; margin: 30px 0; border: 2px dashed #2168F8;">
          <span style="font-size: 42px; font-weight: bold; letter-spacing: 10px; color: #2168F8; display: block; -webkit-user-select: all; user-select: all;">$otpCode</span>
        </div>
        <p style="color: #64748b; font-size: 14px;"><strong>Tip:</strong> You can tap the code above to select it, then copy it. The app will auto-verify it when you switch back.</p>
        <p style="color: #64748b; font-size: 14px;">This code will expire in <strong style="color: #ef4444;">10 minutes</strong>.</p>
        <p style="color: #64748b; font-size: 14px; margin-top: 20px;">If you didn't request this, you can safely ignore this email.</p>
      </div>
    ''';

    return await _sendEmail(
      to: userEmail,
      subject: '$otpCode is your FeePal verification code',
      html: _getBaseTemplate(content),
    );
  }

  // Scenario 8: Password Reset Link (Custom Firebase Flow)
  Future<bool> sendPasswordResetLink(String userEmail, String resetLink) async {
    final content =
        '''
      <h2>Reset Your Password</h2>
      <p>We received a request to reset your FeePal password. Click the button below to choose a new one:</p>
      <div style="text-align: center; margin: 30px 0;">
        <a href="$resetLink" class="button" style="background-color: #2168F8; color: white; text-decoration: none; padding: 12px 30px; border-radius: 6px; font-weight: bold; display: inline-block;">
          Reset Password
        </a>
      </div>
      <p style="color: #64748b; font-size: 14px;">If the button doesn't work, copy and paste this link into your browser:</p>
      <p style="color: #2168F8; font-size: 12px; word-break: break-all;">$resetLink</p>
      <p style="color: #64748b; font-size: 14px; margin-top: 20px;">This link will expire soon for security. If you didn't request this, no action is needed.</p>
    ''';

    return await _sendEmail(
      to: userEmail,
      subject: 'Reset your FeePal password',
      html: _getBaseTemplate(content),
    );
  }

  // Scenario 9: New Fee Issued Alert
  Future<bool> sendFeeAlert({
    required String parentEmail,
    required String studentName,
    required String rollNo,
    String? studentClass,
    double? baseFee,
    double? additionalCharges,
    double? latePenaltyFee,
    String? dueDate,
    bool? isInstallmentAvailable,
  }) async {
    final double totalBase = (baseFee ?? 0) + (additionalCharges ?? 0);
    final double totalPayable = totalBase + (latePenaltyFee ?? 0);

    final content =
        '''
      <h2 style="color: #2168F8;">Fee Alert</h2>
      <p>Greetings, a new fee voucher has been issued for <strong>$studentName</strong> (Roll No: $rollNo).</p>
      
      <div class="info-card">
        <h3 style="margin-top:0; color: #1e293b;">Voucher Summary</h3>
        <table style="width: 100%; border-collapse: collapse;">
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Student:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right;">$studentName</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Roll Number:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right;">$rollNo</td>
          </tr>
          ${studentClass != null ? '''
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Class:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right;">$studentClass</td>
          </tr>
          ''' : ''}
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Total Fees:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right;">Rs. ${totalBase.toStringAsFixed(2)}</td>
          </tr>
          ${dueDate != null ? '''
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Due Date:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right; color: #ef4444;">$dueDate</td>
          </tr>
          ''' : ''}
          ${latePenaltyFee != null && latePenaltyFee > 0 ? '''
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Late Fee Penalty:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right; color: #ef4444;">Rs. ${latePenaltyFee.toStringAsFixed(2)}</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Payable After Late Fee:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right; color: #ef4444;">Rs. ${totalPayable.toStringAsFixed(2)}</td>
          </tr>
          ''' : ''}
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Installments:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right; color: ${isInstallmentAvailable == true ? '#10b981' : '#64748b'};">
              ${isInstallmentAvailable == true ? 'Available' : 'Not Available'}
            </td>
          </tr>
        </table>
      </div>

      <p>To avoid any <strong>late fee penalties</strong>, we kindly request you to clear the outstanding dues before the due date. You can easily view, download the voucher through the FeePal mobile application.</p>
      
      <p style="margin-top: 30px; font-size: 13px; color: #64748b; text-align: center;">
        Thank you for your timely cooperation and for being a valued part of our community.
      </p>
    ''';

    return await _sendEmail(
      to: parentEmail,
      subject: 'Fee Alert: $studentName (Roll No: $rollNo)',
      html: _getBaseTemplate(content, primaryColor: '#2168F8'),
    );
  }

  // Scenario 10: Subscription Approved
  Future<bool> sendSubscriptionApproved(
    String adminEmail,
    String schoolName,
  ) async {
    final content =
        '''
      <h2>Subscription Alert: Congratulations!</h2>
      <p>Your FeePal Subscription for <strong>$schoolName</strong> has been approved.</p>
      <div class="info-card">
        <p>Welcome to the FeePal family! We're here to make your fee management easier and more efficient.</p>
      </div>
      <p>Log in now to start managing your students and fees.</p>
    ''';

    return await _sendEmail(
      to: adminEmail,
      subject: 'Subscription Alert: Approved!',
      html: _getBaseTemplate(content, primaryColor: '#10b981'),
    );
  }

  // Scenario 11: Subscription Denied
  Future<bool> sendSubscriptionDenied(
    String adminEmail,
    String schoolName, {
    String? rejectionReason,
  }) async {
    final content = '''
      <h2>Subscription Status Update</h2>
      <p>Regarding your subscription request for <strong>$schoolName</strong>.</p>
      <div class="info-card" style="border-left: 4px solid #ef4444;">
        <p>Unfortunately, your subscription request could not be approved at this time.</p>
        ${rejectionReason != null ? '<p><strong>Reason:</strong> $rejectionReason</p>' : '<p>This may be due to incomplete payment proof or incorrect documentation.</p>'}
      </div>
      <p>Please review your submission and try again.</p>
      <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
      <p><strong>Contact Support for Assistance:</strong></p>
      <p style="margin: 5px 0;">Email: <a href="mailto:feepal400@gmail.com">feepal400@gmail.com</a></p>
      <p style="margin: 5px 0;">WhatsApp/Phone: +92 313 4469206</p>
    ''';

    return await _sendEmail(
      to: adminEmail,
      subject: 'Subscription Status Update: $schoolName',
      html: _getBaseTemplate(content, primaryColor: '#ef4444'),
    );
  }

  // Scenario 12: Automated Fee Reminder
  Future<bool> sendAutomatedReminder({
    required String parentEmail,
    required String studentName,
    required String rollNo,
    required bool isOverdue,
    String? studentClass,
    double? baseFee,
    double? additionalCharges,
    double? latePenaltyFee,
    String? dueDate,
    bool? isInstallmentAvailable,
  }) async {
    final double totalBase = (baseFee ?? 0) + (additionalCharges ?? 0);
    final double totalPayable = totalBase + (latePenaltyFee ?? 0);

    final content =
        '''
      <h2 style="color: ${isOverdue ? '#ef4444' : '#2168F8'};">${isOverdue ? 'Urgent: Overdue Fee Notice' : 'Fee Payment Reminder'}</h2>
      <p>This is a notification regarding the fee status of <strong>$studentName</strong> (Roll No: $rollNo).</p>
      
      <div class="info-card" style="${isOverdue ? 'border-left: 4px solid #ef4444;' : ''}">
        <h3 style="margin-top:0; color: #1e293b;">Dues Information</h3>
        <table style="width: 100%; border-collapse: collapse;">
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Student:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right;">$studentName</td>
          </tr>
          ${studentClass != null ? '''
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Class:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right;">$studentClass</td>
          </tr>
          ''' : ''}
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Total Fees:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right;">Rs. ${totalBase.toStringAsFixed(2)}</td>
          </tr>
          ${dueDate != null ? '''
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Due Date:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right; color: #ef4444;">$dueDate</td>
          </tr>
          ''' : ''}
          ${latePenaltyFee != null && latePenaltyFee > 0 ? '''
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Late Fee Penalty:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right; color: #ef4444;">Rs. ${latePenaltyFee.toStringAsFixed(2)}</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Payable After Late Fee:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right; color: #ef4444;">Rs. ${totalPayable.toStringAsFixed(2)}</td>
          </tr>
          ''' : ''}
          <tr>
            <td style="padding: 8px 0; color: #64748b;">Installments:</td>
            <td style="padding: 8px 0; font-weight: bold; text-align: right; color: ${isInstallmentAvailable == true ? '#10b981' : '#64748b'};">
              ${isInstallmentAvailable == true ? 'Available' : 'Not Available'}
            </td>
          </tr>
        </table>
      </div>

      <p>Please ensure that all pending dues are cleared before the <strong>${dueDate ?? 'specified date'}</strong> to maintain a smooth academic record and avoid late payment surcharges.</p>
      

      
      <p style="margin-top: 30px; font-size: 13px; color: #64748b; font-style: italic;">
        Note: If you have already paid, please ignore this message. It can take up to 24 hours for the system to reflect your payment status.
      </p>
    ''';

    return await _sendEmail(
      to: parentEmail,
      subject: '${isOverdue ? 'URGENT' : 'Reminder'}: Fee Payment for $studentName (Roll No: $rollNo)',
      html: _getBaseTemplate(content, primaryColor: isOverdue ? '#ef4444' : '#2168F8'),
    );
  }
}
