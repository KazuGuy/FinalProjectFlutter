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
  bool _isLoginView = true;

  // Controller Input Form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;

  // ==========================================
  // LOGIKA PROSES LOGIN (KONEKSI API)
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

    if (!mounted) return;
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
        // DI SINI DIEDIT: Kirimkan isGuest: false karena ini adalah user resmi yang berhasil login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardUserPage(isGuest: false),
          ),
        );
      }
    } else {
      _showSnackBar("Login Gagal! Akun salah atau tidak terdaftar.", Colors.red);
    }
  }

  // ==========================================
  // LOGIKA PROSES REGISTER (KONEKSI API)
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

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading dialog

    if (response != null && response['status'] == 201) {
      _showSnackBar("Pendaftaran Berhasil! Silakan masuk.", Colors.green);
      
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

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight,
          child: Stack(
            children: [
              // 1. BACKGROUND LENGKUNGAN UNGU/BIRU GRADASI (Sesuai one.jpg)
              ClipPath(
                clipper: CurveClipper(),
                child: Container(
                  height: screenHeight * 0.48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF6B73FF), // Ungu Cerah Atas
                        Color(0xFF000DFF), // Biru Ungu Pekat Bawah
                      ],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Text(
                        _isLoginView ? "Login" : "Register",
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. KONTEN INPUT FORM MENGAMBANG DI ATAS CARD PUTIH SOFT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.38), // Mengatur posisi vertical form
                    
                    // Card Wadah Form dengan Shadow Lembut
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Field Nama (Hanya Muncul Saat Register)
                          if (!_isLoginView) ...[
                            TextField(
                              controller: _nameController,
                              decoration: _inputDecoration("Full Name"),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Field Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration("Email or Phone number"),
                          ),
                          const SizedBox(height: 18),

                          // Field Password
                          TextField(
                            controller: _passwordController,
                            obscureText: _isObscure,
                            decoration: _inputDecoration("Password").copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () => setState(() => _isObscure = !_isObscure),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // 3. TOMBOL UTAMA GRADASI UNGU ELEGAN
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8E94F2),
                            Color(0xFF6B73FF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B73FF).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoginView ? _handleLogin : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _isLoginView ? "Login" : "Register",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. TOMBOL TAMBAHAN: GUEST MODE (Hanya Tampil Saat Login View)
                   if (_isLoginView) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            // Mengirimkan data 'isGuest: true' ke halaman DashboardUserPage
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardUserPage(isGuest: true),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            "Continue as Guest",
                            style: TextStyle(fontSize: 15, color: Color(0xFF6B73FF), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),

                    // 5. TOMBOL SAKLAR PINDAH HALAMAN (MENGGANTIKAN FORGOT PASSWORD)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginView = !_isLoginView;
                        });
                      },
                      child: Text(
                        _isLoginView ? "Don't have an account? Sign Up" : "Already have an account? Sign In",
                        style: const TextStyle(
                          color: Color(0xFF8E94F2),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      floatingLabelStyle: const TextStyle(color: Color(0xFF6B73FF)),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6B73FF), width: 2),
      ),
    );
  }
}

// ===========================================================================
// CUSTOM CLIPPER UNTUK MEMBENTUK KURVA GELOMBANG LEMBUT (WARNA UNGU ATAS)
// ===========================================================================
class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.75);

    // Titik kontrol lengkungan bawah ombak
    var firstControlPoint = Offset(size.width * 0.25, size.height * 0.70);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.82);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.94);
    var secondEndPoint = Offset(size.width, size.height * 0.88);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}