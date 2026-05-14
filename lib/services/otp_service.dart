import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OTPService {
  // SMTP credentials (user will replace these with actual credentials)
  static const String _senderEmail = 'your_email@gmail.com';
  static const String _senderPassword = 'your_app_password'; // Use Gmail App Password
  static const String _smtpServer = 'smtp.gmail.com';
  static const int _smtpPort = 587;

  // Generate 6-digit OTP
  static String generateOTP() {
    final random = Random();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  // Send OTP via email
  static Future<bool> sendOTPEmail({
    required String email,
    required String otp,
    required String username,
  }) async {
    try {
      final smtpServer = gmail(_senderEmail, _senderPassword);

      final message = Message()
        ..from = Address(_senderEmail, 'Smart Solar Advisor')
        ..recipients.add(email)
        ..subject = 'Verify Your Email - OTP Code'
        ..html = '''
          <html>
            <body style="font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px;">
              <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                <div style="text-align: center; margin-bottom: 30px;">
                  <h1 style="color: #FF8C00; margin: 0;">Smart Solar Advisor</h1>
                  <p style="color: #666; margin: 10px 0 0 0;">Email Verification</p>
                </div>
                
                <h2 style="color: #333; text-align: center; margin-bottom: 20px;">Verify Your Email Address</h2>
                
                <p style="color: #555; font-size: 16px; line-height: 1.6;">
                  Hello <strong>$username</strong>,
                </p>
                
                <p style="color: #555; font-size: 16px; line-height: 1.6;">
                  Thank you for signing up with Smart Solar Advisor. To complete your registration, please use the following One-Time Password (OTP) to verify your email address:
                </p>
                
                <div style="text-align: center; margin: 30px 0;">
                  <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; border: 2px solid #FF8C00;">
                    <p style="font-size: 12px; color: #999; margin: 0 0 10px 0;">Your OTP Code</p>
                    <p style="font-size: 36px; font-weight: bold; color: #FF8C00; margin: 0; letter-spacing: 5px;">$otp</p>
                  </div>
                </div>
                
                <p style="color: #555; font-size: 16px; line-height: 1.6;">
                  <strong>Important:</strong> This OTP is valid for 10 minutes. Do not share this code with anyone.
                </p>
                
                <p style="color: #555; font-size: 16px; line-height: 1.6;">
                  If you didn't create this account, please ignore this email or contact us immediately.
                </p>
                
                <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                
                <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
                  © 2026 Smart Solar Advisor. All rights reserved.
                </p>
              </div>
            </body>
          </html>
        ''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Error sending OTP: \$e');
      return false;
    }
  }

  // Resend OTP
  static Future<bool> resendOTP({
    required String email,
    required String otp,
    required String username,
  }) async {
    return await sendOTPEmail(
      email: email,
      otp: otp,
      username: username,
    );
  }
}
