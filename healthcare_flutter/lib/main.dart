import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'RegisterScreen.dart';
import 'home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hệ Thống Y Tế Health Life',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Dùng Splash là trang đầu
      home: const SplashScreen(),

      // Khai báo route để điều hướng bằng tên
      routes: {
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home':     (_) => const HomeScreen(),
      },
    );
  }
}
