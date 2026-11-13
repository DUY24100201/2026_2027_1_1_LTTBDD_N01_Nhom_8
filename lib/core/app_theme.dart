import 'package:material_ui/material_ui.dart';

import 'constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get melody => ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
      onPrimary: AppColors.white,
      onSurface: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.border,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: TextStyle(color: AppColors.white),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: AppColors.secondaryText),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(color: AppColors.secondaryText),
    ),
  );
}
