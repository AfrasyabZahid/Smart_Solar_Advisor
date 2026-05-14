import 'package:flutter/material.dart';
import '../constants/colors.dart';

class VendorsScreen extends StatelessWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Vendors',
          style: TextStyle(color: AppColors.textWhite),
        ),
      ),
      body: const Center(
        child: Text(
          'Vendors Screen',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}