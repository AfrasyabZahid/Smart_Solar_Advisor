import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Chatbot',
          style: TextStyle(color: AppColors.textWhite),
        ),
      ),
      body: const Center(
        child: Text(
          'Chatbot Screen',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}