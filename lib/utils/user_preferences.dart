import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserName = 'userName';
  static const String _keyUsername = 'username';
  static const String _keyUserPassword = 'userPassword';
  static const String _keyEmailVerified = 'emailVerified';

  // Save user registration data
  static Future<bool> registerUser({
    required String username,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user already exists
      String? existingEmail = prefs.getString(_keyUserEmail);
      if (existingEmail == email) {
        return false; // User already exists
      }

      await prefs.setString(_keyUsername, username);
      await prefs.setString(_keyUserName, name);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserPassword, password);
      await prefs.setBool(_keyEmailVerified, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user email already exists
  static Future<bool> isUserEmailExists(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? existingEmail = prefs.getString(_keyUserEmail);
      return existingEmail == email;
    } catch (e) {
      return false;
    }
  }

  // Check if email is verified
  static Future<bool> isEmailVerified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyEmailVerified) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Login user
  static Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? savedEmail = prefs.getString(_keyUserEmail);
      String? savedPassword = prefs.getString(_keyUserPassword);

      // Check if credentials match
      if (savedEmail == email && savedPassword == password) {
        await prefs.setBool(_keyIsLoggedIn, true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // Get username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  // Logout user
  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  // Check if user is registered
  static Future<bool> isUserRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString(_keyUserEmail);
    return email != null && email.isNotEmpty;
  }
}