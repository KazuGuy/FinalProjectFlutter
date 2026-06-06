import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart'; // Memanggil file login yang sudah kita buat

void main() {
  // Ini adalah fungsi pertama yang dijalankan Flutter
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaliStay DSS',
      debugShowCheckedModeBanner: false, // Menghilangkan pita "DEBUG" merah di pojok kanan atas
      theme: ThemeData(
        // Menyesuaikan tema warna dasar dengan palet UI kita (Biru BaliStay)
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0083B0)),
        useMaterial3: true, // Mengaktifkan gaya UI Android modern
        fontFamily: 'Roboto', // Default font yang bersih
      ),
      // Di sinilah kita mengatur halaman pertama yang muncul saat aplikasi dibuka
      home: const LoginPage(), 
    );
  }
}