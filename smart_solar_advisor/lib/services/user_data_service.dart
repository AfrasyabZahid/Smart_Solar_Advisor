import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles all user-data persistence calls to the Flask backend.
/// Every feature (calculator, chat, profile, activity) goes through here.
class UserDataService {
  static const String _baseUrl = 'http://localhost:5000/api';

  // ── Calculator ─────────────────────────────────────────────────────────────

  static Future<bool> saveCalculation({
    required String userEmail,
    required double energyUsageKwh,
    required double rooftopAreaSqm,
    required String location,
    required double loadSheddingHours,
    required double systemSizeKw,
    required double systemCostPkr,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/save_calculation'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_email': userEmail,
              'energy_usage_kwh': energyUsageKwh,
              'rooftop_area_sqm': rooftopAreaSqm,
              'location': location,
              'load_shedding_hours': loadSheddingHours,
              'system_size_kw': systemSizeKw,
              'system_cost_pkr': systemCostPkr,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      print('Error saving calculation: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getCalculations(
      String userEmail) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/get_calculations?email=${Uri.encodeComponent(userEmail)}&limit=20'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['calculations']);
      }
    } catch (e) {
      print('Error getting calculations: $e');
    }
    return [];
  }

  // ── Chat ───────────────────────────────────────────────────────────────────

  static Future<bool> saveChatSession({
    required String userEmail,
    required List<Map<String, String>> messages,
    required String sessionStartedAt,
  }) async {
    try {
      // Skip saving if only the bot greeting is present (nothing meaningful)
      final userMessages =
          messages.where((m) => m['role'] == 'user').toList();
      if (userMessages.isEmpty) return false;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/save_chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_email': userEmail,
              'messages': messages,
              'session_started_at': sessionStartedAt,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      print('Error saving chat session: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(
      String userEmail) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/get_chats?email=${Uri.encodeComponent(userEmail)}&limit=10'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['sessions']);
      }
    } catch (e) {
      print('Error getting chat history: $e');
    }
    return [];
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateProfile({
    required String email,
    String? name,
    String? city,
  }) async {
    try {
      final body = <String, dynamic>{'email': email};
      if (name != null) body['name'] = name;
      if (city != null) body['city'] = city;

      final response = await http
          .put(
            Uri.parse('$_baseUrl/update_profile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print('Error updating profile: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/change_password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print('Error changing password: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ── Activity Log ───────────────────────────────────────────────────────────

  static Future<void> logActivity({
    required String userEmail,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/log_activity'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_email': userEmail,
              'action': action,
              'details': details ?? {},
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getActivityLog(
      String userEmail) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/get_activity?email=${Uri.encodeComponent(userEmail)}&limit=20'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['activities']);
      }
    } catch (e) {
      print('Error getting activity log: $e');
    }
    return [];
  }
}
