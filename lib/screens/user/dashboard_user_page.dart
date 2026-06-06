import 'package:flutter/material.dart';
import '../../services/api_services.dart';
class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna background modern yang soft
      
      // 1. HEADER & SEARCH BAR (Pengganti area biru di web)
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GREETING
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Halo, Arya12 👋", 
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Cari hotel idamanmu", 
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        // Avatar
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFE2E8F0),
                          child: Icon(Icons.person, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SEARCH BAR MODERN (Material 3 Style)
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Ketik nama hotel...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF0083B0)),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0083B0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune, color: Color(0xFF0083B0), size: 20), // Ikon Filter
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. DAFTAR HOTEL (Sama persis dengan data PDF, UI jauh lebih eyecatching)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Rekomendasi Terbaik", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Urutkan ▼", style: TextStyle(color: Color(0xFF0083B0))),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ITEM 1: Renaissance
                  _buildHotelCard(
                    nama: "Renaissance Bali Nusa Dua",
                    harga: "Rp 2.625.000",
                    rating: "9.2",
                    fasilitas: "13 Fasilitas",
                    diskon: "8% OFF",
                    imageUrl: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500",
                  ),
                  // ITEM 2: The 101 Bali Fontana
                  _buildHotelCard(
                    nama: "The 101 Bali Fontana Seminyak",
                    harga: "Rp 1.822.004",
                    rating: "8.6",
                    fasilitas: "7 Fasilitas",
                    diskon: "8% OFF",
                    imageUrl: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=500",
                  ),
                  // ITEM 3: Seminyak Townhouse
                  _buildHotelCard(
                    nama: "Seminyak Townhouse Bali",
                    harga: "Rp 1.279.689",
                    rating: "8.2",
                    fasilitas: "5 Fasilitas",
                    diskon: "53% OFF",
                    imageUrl: "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=500",
                  ),
                  // ITEM 4: Siesta Legian
                  _buildHotelCard(
                    nama: "Siesta Legian Hotel",
                    harga: "Rp 652.717",
                    rating: "8.7",
                    fasilitas: "6 Fasilitas",
                    diskon: "", // Tidak ada diskon di PDF
                    imageUrl: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=500",
                  ),
                  const SizedBox(height: 80), // Spacing untuk Bottom Navigation
                ]),
              ),
            ),
          ],
        ),
      ),

      // 3. BOTTOM NAVIGATION BAR (Pengganti Menu Atas)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: const Color(0xFF0083B0).withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.hotel_outlined), selectedIcon: Icon(Icons.hotel), label: 'Hotel'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'POI'),
          // Tab Evaluasi MABAC kita buat mencolok
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Evaluasi DSS'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  // WIDGET CARD HOTEL ADAPTASI MODERN
  Widget _buildHotelCard({
    required String nama,
    required String harga,
    required String rating,
    required String fasilitas,
    required String diskon,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Gambar Hotel Kotak Melengkung
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 110,
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 110,
                      width: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                  // Floating Rating Badge (seperti di Traveloka/Agoda)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0083B0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                          Text(rating, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Detail Hotel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.room_service_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(fasilitas, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Row Harga & Diskon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (diskon.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Text(diskon, style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          Text(
                            harga,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0083B0)),
                          ),
                        ],
                      ),
                      // Tombol Booking/Pilih kecil
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("Pilih", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}