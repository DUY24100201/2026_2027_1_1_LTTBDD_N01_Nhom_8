import 'package:flutter/material.dart';
import 'screens/auth/welcome/welcome_screen.dart';

void main() {
  runApp(const MelodyApp());
}

// Widget chính của ứng dụng
class MelodyApp extends StatelessWidget {
  const MelodyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Ẩn chữ DEBUG
      title: 'Melody',
      theme: ThemeData.dark(), // Giao diện tối
      home: const WelcomeScreen(), // Mở màn hình Welcome
    );
  }
}