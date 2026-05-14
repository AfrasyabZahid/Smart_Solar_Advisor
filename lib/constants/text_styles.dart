import 'package:flutter/material.dart';
import 'colors.dart';
import 'dimensions.dart';

class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: AppDimensions.textXXLarge,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: AppDimensions.textXLarge,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: AppDimensions.textLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppDimensions.textLarge,
    color: AppColors.textDark,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppDimensions.textMedium,
    color: AppColors.textDark,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: AppDimensions.textSmall,
    color: AppColors.textGrey,
  );
  
  // Special Styles
  static const TextStyle labelStyle = TextStyle(
    fontSize: AppDimensions.textMedium,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  static const TextStyle hintStyle = TextStyle(
    fontSize: AppDimensions.textMedium,
    color: AppColors.textGrey,
  );
  
  static const TextStyle resultNumber = TextStyle(
    fontSize: AppDimensions.textHuge,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );
  
  static const TextStyle resultLabel = TextStyle(
    fontSize: AppDimensions.textMedium,
    color: AppColors.textWhite,
  );
  
  static const TextStyle costValue = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: AppColors.costGreen,
  );
}