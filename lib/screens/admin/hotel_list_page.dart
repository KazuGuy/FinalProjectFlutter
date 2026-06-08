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
      final success = await _apiService.deleteHotel(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Hotel berhasil dihapus!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshHotelList(); // Refresh tampilan setelah berhasil hapus
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menghapus hotel."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  String _formatPrice(dynamic price) {
    if (price == null) return "0";
    final p = double.tryParse(price.toString())?.toInt() ?? 0;
    return p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color travelokaBlue = Color(0xFF0194F3);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Kelola Data Hotel", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: travelokaBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshHotelList, // Tombol refresh manual
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _hotelListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
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
                      style: ElevatedButton.styleFrom(backgroundColor: travelokaBlue, foregroundColor: Colors.white),
                      child: const Text("Coba Lagi"),
                    )
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Belum ada data hotel. Silakan tambah baru."),
            );
          }

          List hotels = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              var hotel = hotels[index];
              int discount = int.tryParse(hotel['discount']?.toString() ?? '0') ?? 0;
              double rating = double.tryParse(hotel['rating']?.toString() ?? '0.0') ?? 0.0;
              String type = hotel['type']?.toString().toUpperCase() ?? 'HOTEL';

              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leading Icon / Hotel Type
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.hotel_rounded, color: travelokaBlue, size: 28),
                      ),
                      const SizedBox(width: 14),

                      // Hotel Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    hotel['name'] ?? 'Tanpa Nama',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (discount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFECE0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "$discount% OFF",
                                      style: const TextStyle(
                                        color: Color(0xFFFF6D00),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "(${hotel['facilities_count']} fas.)",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Rp ${_formatPrice(hotel['price'])} / malam",
                              style: const TextStyle(
                                color: travelokaBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Koordinat: ${hotel['latitude'] ?? '0.0'}, ${hotel['longitude'] ?? '0.0'}",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Actions Column
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.orange, size: 22),
                            onPressed: () async {
                              bool? isRefreshed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HotelFormPage(hotel: hotel),
                                ),
                              );
                              if (isRefreshed == true) _refreshHotelList();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 22),
                            onPressed: () => _showDeleteDialog(
                              int.parse(hotel['id'].toString()),
                              hotel['name'] ?? '',
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: travelokaBlue,
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
