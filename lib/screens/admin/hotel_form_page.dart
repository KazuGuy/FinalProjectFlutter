import 'package:flutter/material.dart';
import '../../services/api_services.dart';

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
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _facCountController = TextEditingController();
  final TextEditingController _facDetailController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  String _selectedType = 'hotel';
  bool _isLoading = false;
  bool _isEditMode = false;

  final List<String> _types = ['resort', 'villa', 'hotel', 'apartment', 'guesthouse'];

  @override
  void initState() {
    super.initState();
    // Cek apakah ada data hotel yang dikirim (Mode Edit)
    if (widget.hotelData != null) {
      _isEditMode = true;
      _nameController.text = widget.hotelData!['name']?.toString() ?? '';
      _priceController.text = widget.hotelData!['price']?.toString() ?? '';
      _ratingController.text = widget.hotelData!['rating']?.toString() ?? '';
      _facCountController.text = widget.hotelData!['facilities_count']?.toString() ?? '';
      _facDetailController.text = widget.hotelData!['facilities_detail']?.toString() ?? '';
      _discountController.text = widget.hotelData!['discount']?.toString() ?? '';
      _latController.text = widget.hotelData!['latitude']?.toString() ?? '';
      _lngController.text = widget.hotelData!['longitude']?.toString() ?? '';
      
      String dbType = widget.hotelData!['type']?.toString().toLowerCase() ?? 'hotel';
      if (_types.contains(dbType)) {
        _selectedType = dbType;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _facCountController.dispose();
    _facDetailController.dispose();
    _discountController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // Fungsi simpan data ke API
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, String> data = {
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'price': _priceController.text.trim(),
      'rating': _ratingController.text.trim(),
      'facilities_count': _facCountController.text.trim(),
      'facilities_detail': _facDetailController.text.trim(),
      'discount': _discountController.text.trim().isEmpty ? '0' : _discountController.text.trim(),
      'latitude': _latController.text.trim(),
      'longitude': _lngController.text.trim(),
    };

    try {
      bool success;
      if (_isEditMode) {
        int id = int.parse(widget.hotelData!['id'].toString());
        success = await _apiService.updateHotel(id, data);
        if (success) {
          _showSnackbar("Data hotel berhasil diperbarui!", Colors.green);
        }
      } else {
        success = await _apiService.addHotel(data);
        if (success) {
          _showSnackbar("Hotel baru berhasil ditambahkan!", Colors.green);
        }
      }

      if (success) {
        Navigator.pop(context, true); // Kembali ke halaman sebelumnya dengan sinyal refresh
      } else {
        _showSnackbar("Gagal menyimpan data ke database. Cek validasi server.", Colors.red);
      }
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
    const Color travelokaBlue = Color(0xFF0194F3);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEditMode ? "Edit Hotel" : "Tambah Hotel",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: travelokaBlue,
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
                      "Lengkapi semua parameter kriteria untuk perangkingan MABAC.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // INPUT NAMA HOTEL
                    _buildTextField(
                      controller: _nameController,
                      label: "Nama Hotel (Ciri Fisik / Brand)",
                      hint: "Masukkan nama hotel",
                      icon: Icons.hotel_rounded,
                      validator: (val) => val!.isEmpty ? "Nama hotel wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    // TIPE PENGINAPAN
                    const Text("Tipe Akomodasi (C6)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: travelokaBlue, size: 30),
                          items: _types.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedType = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // INPUT HARGA PER MALAM
                    _buildTextField(
                      controller: _priceController,
                      label: "Harga per Malam (C1 - Cost)",
                      hint: "Contoh: 500000",
                      icon: Icons.money_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val!.isEmpty) return "Harga wajib diisi";
                        if (double.tryParse(val) == null) return "Harga harus berupa angka desimal/bulat";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // RATING (0 - 10)
                    _buildTextField(
                      controller: _ratingController,
                      label: "Skor Review / Rating (C2 - Benefit, Nilai 0.0 - 10.0)",
                      hint: "Contoh: 8.5",
                      icon: Icons.star_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val!.isEmpty) return "Rating wajib diisi";
                        final rating = double.tryParse(val);
                        if (rating == null) return "Rating harus berupa angka desimal";
                        if (rating < 0 || rating > 10) return "Skor rating harus di kisaran 0.0 sampai 10.0";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // JUMLAH FASILITAS
                    _buildTextField(
                      controller: _facCountController,
                      label: "Jumlah Fasilitas Utama (C4 - Benefit)",
                      hint: "Contoh: 8",
                      icon: Icons.room_service_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val!.isEmpty) return "Jumlah fasilitas wajib diisi";
                        if (int.tryParse(val) == null) return "Jumlah fasilitas harus berupa angka bulat";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // DETAIL FASILITAS
                    _buildTextField(
                      controller: _facDetailController,
                      label: "Rincian Detail Fasilitas (Koma separated)",
                      hint: "Contoh: AC, Wi-Fi, Kolam Renang, Spa, Sarapan Gratis",
                      icon: Icons.list_alt_rounded,
                      maxLines: 2,
                      validator: (val) => val!.isEmpty ? "Rincian fasilitas wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    // DISKON
                    _buildTextField(
                      controller: _discountController,
                      label: "Promo Diskon % (C5 - Benefit, Nilai 0 - 100)",
                      hint: "Contoh: 10 (tulis 0 jika tidak ada)",
                      icon: Icons.percent_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          final disc = int.tryParse(val);
                          if (disc == null) return "Diskon harus berupa angka bulat";
                          if (disc < 0 || disc > 100) return "Diskon berada di kisaran 0% - 100%";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // MAP COORDINATES
                    const Text("Koordinat Lokasi (Untuk Kriteria C3 - Jarak POI)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: _inputDecorationStyle("Latitude", Icons.location_on_outlined),
                            validator: (val) {
                              if (val!.isEmpty) return "Wajib diisi";
                              if (double.tryParse(val) == null) return "Harus angka";
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: _inputDecorationStyle("Longitude", Icons.location_on_outlined),
                            validator: (val) {
                              if (val!.isEmpty) return "Wajib diisi";
                              if (double.tryParse(val) == null) return "Harus angka";
                              return null;
                            },
                          ),
                        ),
                      ],
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
                          backgroundColor: travelokaBlue,
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
          decoration: _inputDecorationStyle(hint, icon),
        ),
      ],
    );
  }

  InputDecoration _inputDecorationStyle(String hint, IconData icon) {
    const Color travelokaBlue = Color(0xFF0194F3);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: travelokaBlue),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: travelokaBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }
}
