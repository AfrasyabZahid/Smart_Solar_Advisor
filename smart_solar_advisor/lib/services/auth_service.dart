import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/user_preferences.dart';
import '../constants/api_constants.dart';
import 'user_data_service.dart';

class AuthService {
  // Use centralized API constants configuration
  static final String _baseUrl = ApiConstants.baseUrl;

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
          password: password,
        );
        // Also persist city returned from DB
        final city = data['user']['city'] ?? '';
        if (city.isNotEmpty) {
          await UserPreferences.updateUserCity(city);
        }
        // Log login activity to MongoDB
        await UserDataService.logActivity(
          userEmail: email,
          action: 'login',
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

  /// Call this on logout to notify the backend and log the activity.
  static Future<void> logoutUser(String email) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
