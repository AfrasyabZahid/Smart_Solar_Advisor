import 'package:flutter/foundation.dart';

class ApiConstants {
  // The local IP of the machine running the backend.
  // Ensure both your computer and mobile phone are connected to the same Wi-Fi network.
  static const String localIp = '192.168.0.101';
  static const String port = '5000';

  // If you deploy your backend to a public server (e.g., Render, Fly.io, Heroku),
  // replace this with your public domain URL (e.g. 'https://my-backend.onrender.com/api').
  static const String productionUrl = '';

  static String get baseUrl {
    if (productionUrl.isNotEmpty) {
      return productionUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:$port/api';
    }
    // For mobile devices (Android/iOS) to connect to your local backend server
    return 'http://$localIp:$port/api';
  }
}
