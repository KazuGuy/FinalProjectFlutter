import 'package:flutter/material.dart';
import '../../services/api_services.dart'; // Pastikan path ke ApiService sudah benar
import '../admin/dashboard_admin_page.dart';        // Halaman Dashboard Admin
import '../user/dashboard_user_page.dart';   // Halaman Dashboard User

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Status penentu: true = Tampilan Login, false = Tampilan Register
  bool _isLoginView = true;

  // Controller Input Form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;

  // ==========================================
  // 1. LOGIKA PROSES LOGIN (KONEKSI API)
  // ==========================================
  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Email dan Password tidak boleh kosong", Colors.orange);
      return;
    }

    _showLoadingDialog();

    final ApiService apiService = ApiService();
    var response = await apiService.login(email, password);

    Navigator.pop(context); // Tutup loading dialog

    if (response != null && response['status'] == 200) {
      var userData = response['data'];
      String role = userData['role'];

      _showSnackBar("Selamat Datang, ${userData['name']}!", Colors.green);

      // Navigasi otomatis berdasarkan Role dari Database MySQL
      if (role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardAdminPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardUserPage()),
        );
      }
    } else {
      _showSnackBar("Login Gagal! Akun salah atau tidak terdaftar.", Colors.red);
    }
  }

  // ==========================================
  // 2. LOGIKA PROSES REGISTER (KONEKSI API)
  // ==========================================
  void _handleRegister() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Semua kolom wajib diisi untuk mendaftar", Colors.orange);
      return;
    }

    _showLoadingDialog();

    final ApiService apiService = ApiService();
    var response = await apiService.register(name, email, password);

    Navigator.pop(context); // Tutup loading dialog

    if (response != null && response['status'] == 201) {
      _showSnackBar("Pendaftaran Berhasil! Silakan masuk.", Colors.green);
      
      // Bersihkan form dan kembalikan tampilan ke form Login
      setState(() {
        _nameController.clear();
        _passwordController.clear();
        _isLoginView = true; 
      });
    } else {
      String msg = response?['message'] ?? "Pendaftaran Gagal!";
      _showSnackBar(msg, Colors.red);
    }
  }

  // ==========================================
  // HELPER WIDGETS (LOADING & SNACKBAR)
  // ==========================================
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  // ==========================================
  // UI LAYOUT (KEDUA FORM DISATUKAN DI SINI)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ANIMASI TOGGLE JUDUL UTAMA
                Text(
                  _isLoginView ? "Welcome Back" : "Create Account",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  _isLoginView ? "Sign in to continue your session" : "Sign up to get started with BaliStay",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // FIELD NAMA (Hanya muncul jika sedang di halaman REGISTER)
                if (!_isLoginView) ...[
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration('Full Name', Icons.person_outline_rounded),
                  ),
                  const SizedBox(height: 16),
                ],

                // FIELD EMAIL (Selalu Muncul)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email Address', Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                // FIELD PASSWORD (Selalu Muncul)
                TextField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: _inputDecoration('Password', Icons.lock_outline_rounded).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // TOMBOL UTAMA (Bisa berubah fungsi berdasarkan state tampilan)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoginView ? _handleLogin : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0083B0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Text(
                      _isLoginView ? "Sign In" : "Sign Up",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // TOMBOL TOGGLE UNTUK SAKLAR PINDAH HALAMAN (LOGIN <-> REGISTER)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLoginView = !_isLoginView;
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        text: _isLoginView ? "Don't have an account? " : "Already have an account? ",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        children: [
                          TextSpan(
                            text: _isLoginView ? "Sign Up" : "Sign In",
                            style: const TextStyle(color: Color(0xFF0083B0), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}