import 'package:flutter/material.dart';
// Import file Anda dari path yang benar
import '../admin/dashboard_admin_page.dart';
import '../user/dashboard_user_page.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Tambahkan controller untuk mengambil teks input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;

  // Fungsi Logic Login (Ditempatkan di dalam class)
  void _handleLogin() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Logika Pemisahan Role (Nanti diganti dengan API hit)
    if (email == "admin@hotel.com" && password == "admin123") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardAdminPage()),
      );
    } else if (email == "user@example.com" && password == "password") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserDashboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email atau password salah")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    height: 200, width: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.travel_explore_rounded, size: 100, color: Color(0xFF0083B0)),
                  ),
                ),
                const SizedBox(height: 40),
                const Text("Sign in", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                // FIELD EMAIL (Tambahkan controller)
                TextField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email', Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                // FIELD PASSWORD (Tambahkan controller)
                TextField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                
                // TOMBOL LOGIN (Panggil fungsi _handleLogin)
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0083B0)),
                    child: const Text("Sign in", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
                // ... (Sisa widget lainnya tetap sama)
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper agar kode tidak redundan
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint, filled: true, fillColor: const Color(0xFFF5F7FA),
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}