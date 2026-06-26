import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/user_preferences.dart';

class AuthService {
  // Use 10.0.2.2 for Android emulator, or localhost/127.0.0.1 for Web/iOS simulator.
  // Assuming the Python backend runs on port 5000.
  // Note: if you are testing on a real device, you need to use your machine's local IP address.
  static const String _baseUrl = 'https://smart-solar-advisor.onrender.com/api';

  static Future<Map<String, dynamic>> checkEmail({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/check_email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exists': data['exists']};
      } else {
        return {'exists': false}; // Fallback or handle error
      }
    } catch (e) {
      print('Error checking email: $e');
      return {'exists': false};
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        // Optionally save to UserPreferences for local state persistence
        await UserPreferences.saveUser(
          name: name,
          email: email,
          password: password,
        );
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('Error during registration: $e');
      return {'success': false, 'message': 'Network error: Could not connect to backend'};
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Save current user locally so the app stays logged in
        await UserPreferences.saveUser(
          name: data['user']['name'],
          email: data['user']['email'],
          password: password, // usually shouldn't save password locally, but maintaining existing flow
        );
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Error during login: $e');
      return {'success': false, 'message': 'Network error: Could not connect to backend'};
    }
  }
}
