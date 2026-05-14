import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: AppColors.textWhite),
        ),
      ),
      body: const Center(
        child: Text(
          'Profile Screen',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}