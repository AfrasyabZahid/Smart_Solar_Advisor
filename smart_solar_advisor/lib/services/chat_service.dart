import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _baseUrl = 'http://localhost:5000/api';

  static Future<Map<String, dynamic>> sendMessage(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': messages,
        }),
      ).timeout(const Duration(seconds: 30)); // 30 seconds timeout for AI generation

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'reply': data['reply'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get response',
        };
      }
    } catch (e) {
      print('Error sending message: $e');
      return {
        'success': false,
        'message': 'Network error: Could not connect to AI service',
      };
    }
  }
}
