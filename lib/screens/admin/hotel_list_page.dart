import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import 'hotel_form_page.dart';

class HotelListPage extends StatefulWidget {
  const HotelListPage({super.key});

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _hotelListFuture;

  @override
  void initState() {
    super.initState();
    _refreshHotelList(); // Memuat data pertama kali
  }

  // Fungsi untuk memicu reload/refresh data dari API
  void _refreshHotelList() {
    setState(() {
      _hotelListFuture = _apiService.getHotels();
    });
  }

  // Fungsi untuk menangani hapus data hotel
  void _handleDelete(int id) async {
    try {
      await _apiService.deleteHotel(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hotel berhasil dihapus!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _refreshHotelList(); // Refresh tampilan setelah berhasil hapus
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menghapus data: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Kelola Data Hotel", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0083B0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshHotelList, // Tombol refresh manual di pojok kanan atas
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _hotelListFuture,
        builder: (context, snapshot) {
          // 1. Kondisi Loading saat ambil data dari API CI4
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 2. Kondisi jika terjadi Error (misal server CI4 mati)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      "Gagal terhubung ke server:\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshHotelList,
                      child: const Text("Coba Lagi"),
                    )
                  ],
                ),
              ),
            );
          }

          // 3. Kondisi jika data kosong atau null
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Belum ada data hotel. Silakan tambah baru."),
            );
          }

          // 4. Kondisi Berhasil: Menampilkan list hotel dengan Card modern
          List hotels = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              var hotel = hotels[index];
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hotel_rounded, color: Color(0xFF0083B0)),
                  ),
                  title: Text(
                    hotel['name'] ?? 'Tanpa Nama',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Harga: Rp ${hotel['price'] ?? 0} / malam"),
                      Text(
                        hotel['address'] ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Edit (Kirim data hotel ke HotelFormPage)
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.orange),
                        onPressed: () async {
                          bool? isRefreshed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HotelFormPage(hotelData: hotel),
                            ),
                          );
                          if (isRefreshed == true) _refreshHotelList();
                        },
                      ),
                      // Tombol Hapus dengan Konfirmasi Dialog (Nilai plus dari dosen)
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                        onPressed: () => _showDeleteDialog(hotel['id'], hotel['name']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Tombol Tambah Data (+) di pojok kanan bawah
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0083B0),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          bool? isRefreshed = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HotelFormPage()),
          );
          if (isRefreshed == true) _refreshHotelList();
        },
      ),
    );
  }

  // Fungsi memunculkan pop-up konfirmasi sebelum benar-benar menghapus data
  void _showDeleteDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Hotel?"),
        content: Text("Apakah Anda yakin ingin menghapus hotel '$name'? Data tidak dapat dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              _handleDelete(id);     // Jalankan hapus API
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}