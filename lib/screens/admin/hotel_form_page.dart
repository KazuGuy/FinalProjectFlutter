import 'package:flutter/material.dart';
import '../../services/api_services.dart'; // Sesuaikan path jika berbeda

class HotelFormPage extends StatefulWidget {
  final Map<String, dynamic>? hotelData; // Jika null = Tambah, Jika ada isi = Edit

  const HotelFormPage({super.key, this.hotelData});

  @override
  State<HotelFormPage> createState() => _HotelFormPageState();
}

class _HotelFormPageState extends State<HotelFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controller untuk menangkap input teks
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Cek apakah ada data hotel yang dikirim (Mode Edit)
    if (widget.hotelData != null) {
      _isEditMode = true;
      _nameController.text = widget.hotelData!['name'] ?? '';
      _priceController.text = widget.hotelData!['price']?.toString() ?? '';
      _addressController.text = widget.hotelData!['address'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Fungsi simpan data ke API
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, String> data = {
      'name': _nameController.text.trim(),
      'price': _priceController.text.trim(),
      'address': _addressController.text.trim(),
    };

    try {
      if (_isEditMode) {
        // Mode Edit: Ambil ID hotel dan kirim ke API Update
        int id = widget.hotelData!['id'];
        // Catatan: Pastikan di ApiService Anda nanti ditambahkan fungsi updateHotel
        // await _apiService.updateHotel(id, data); 
        
        _showSnackbar("Data hotel berhasil diperbarui!", Colors.green);
      } else {
        // Mode Tambah Baru
        await _apiService.addHotel(data);
        _showSnackbar("Hotel baru berhasil ditambahkan!", Colors.green);
      }

      // Kembali ke halaman sebelumnya dan memberi sinyal untuk refresh list
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackbar("Gagal menyimpan data: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEditMode ? "Edit Hotel" : "Tambah Hotel",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0083B0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Informasi Hotel",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(
                      "Lengkapi formulir di bawah ini dengan benar.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // INPUT NAMA HOTEL
                    _buildTextField(
                      controller: _nameController,
                      label: "Nama Hotel",
                      hint: "Masukkan nama hotel",
                      icon: Icons.hotel_rounded,
                      validator: (val) => val!.isEmpty ? "Nama hotel wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    // INPUT HARGA PER MALAM
                    _buildTextField(
                      controller: _priceController,
                      label: "Harga per Malam",
                      hint: "Contoh: 500000",
                      icon: Icons.money_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val!.isEmpty) return "Harga wajib diisi";
                        if (int.tryParse(val) == null) return "Harga harus berupa angka";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // INPUT ALAMAT
                    _buildTextField(
                      controller: _addressController,
                      label: "Alamat / Lokasi",
                      hint: "Masukkan alamat lengkap hotel",
                      icon: Icons.location_on_rounded,
                      maxLines: 3,
                      validator: (val) => val!.isEmpty ? "Alamat wajib diisi" : null,
                    ),
                    const SizedBox(height: 32),

                    // TOMBOL SIMPAN
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          _isEditMode ? "Perbarui Data" : "Simpan Hotel",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0083B0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget pembantu untuk merapikan textfield dekorasi ala Android Modern
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: const Color(0xFF0083B0)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF0083B0), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}