import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';

void main() {
  runApp(const MelodyApp());
}

class MelodyApp extends StatelessWidget {
  const MelodyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
