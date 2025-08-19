import 'package:flutter/material.dart';

class AnimeTheme {
  // 莫兰迪色系调色板 - 更青春时尚
  static const Color primaryColor = Color(0xFF9DB5CC); // 莫兰迪蓝
  static const Color secondaryColor = Color(0xFFB5A8CC); // 莫兰迪紫
  static const Color accentColor = Color(0xFFCC9BA8); // 莫兰迪粉
  static const Color backgroundColor = Color(0xFFF0F4F8); // 淡灰蓝背景
  static const Color cardColor = Color(0xFFFFFFFF); // 纯白卡片
  static const Color textColor = Color(0xFF5C6B73); // 深灰蓝文字
  
  // 柔和的辅助色
  static const Color lightPrimaryColor = Color(0xFFC7D3E0); // 浅蓝
  static const Color lightSecondaryColor = Color(0xFFD8D0E3); // 浅紫
  static const Color lightAccentColor = Color(0xFFE3C7D0); // 浅粉

  // 动漫风格按钮主题
  static ButtonStyle get animeButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.3),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  // 圆形按钮样式
  static ButtonStyle get animeCircleButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(15),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.3),
    );
  }

  // 卡片主题
  static CardTheme get animeCardTheme {
    return const CardTheme(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
    );
  }

  // 应用栏主题
  static AppBarTheme get animeAppBarTheme {
    return const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      elevation: 2,
    );
  }

  // 对话框主题
  static DialogTheme get animeDialogTheme {
    return DialogTheme(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 16,
        color: textColor,
      ),
    );
  }

  // 文本主题
  static TextTheme get animeTextTheme {
    return const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: secondaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: accentColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        color: textColor,
      ),
    );
  }
}