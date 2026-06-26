import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OTPService {
  // Backend API endpoint - change to your actual server URL
  static const String _backendUrl = 'https://smart-solar-advisor.onrender.com/api';

  // Generate 6-digit OTP (for verification purposes only)
  static String generateOTP() {
    final random = Random();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  // Send OTP via backend API
  static Future<Map<String, dynamic>> sendOTPEmail({
    required String email,
    required String username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'otp': data['otp'], // For testing
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      print('Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOTP({
    required String email,
    required String username,
  }) async {
    return await sendOTPEmail(
      email: email,
      username: username,
    );
  }
}
