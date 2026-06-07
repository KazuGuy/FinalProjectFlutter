import 'package:flutter/material.dart';
import '../../services/api_services.dart'; // Pastikan path ke ApiService Anda sudah benar
import '../auth/login_page.dart';

class DashboardUserPage extends StatefulWidget {
  const DashboardUserPage({super.key});

  @override
  State<DashboardUserPage> createState() => _DashboardUserPageState();
}

class _DashboardUserPageState extends State<DashboardUserPage> {
  int _selectedIndex = 0;

  // Navigasi Tab Utama User
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const UserHomeTab(),         // Tab 1: Daftar Hotel Real-Time dari MySQL
      const UserRecommendationTab(), // Tab 2: Wadah Perhitungan SPK (Teman Anda)
      const UserPoiTab(),          // Tab 3: Wadah Data Wisata POI (Teman Anda)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("BaliStay DSS", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0083B0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF0083B0)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF0083B0)),
            label: 'Rekomendasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: Color(0xFF0083B0)),
            label: 'Wisata (POI)',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: USER HOME - MENAMPILKAN LIST HOTEL DARI API
// ==========================================
class UserHomeTab extends StatelessWidget {
  const UserHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();

    return FutureBuilder<List<dynamic>>(
      future: apiService.getHotels(), // Hit API langsung ke MySQL
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Gagal memuat data hotel.\nPastikan backend/CORS aktif.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Tidak ada penginapan yang tersedia saat ini."),
          );
        }

        List hotels = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Selamat Datang di BaliStay!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Text(
                "Berikut adalah daftar hotel yang tersedia dalam sistem DSS kami.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // GRID/LIST HOTEL DARI DATABASE
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                          Text(
                            "Rp ${hotel['price'] ?? 0} / malam",
                            style: const TextStyle(color: Color(0xFF0083B0), fontWeight: FontWeight.w600),
                          ),
                          Text(
                            hotel['address'] ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// TAB 2: REKOMENDASI SPK (SLOT UNTUK TEMAN KELOMPOK)
// ==========================================
class UserRecommendationTab extends StatelessWidget {
  const UserRecommendationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_rounded, size: 80, color: Color(0xFF0083B0)),
          const SizedBox(height: 16),
          const Text(
            "Rekomendasi Hotel (DSS)",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Halaman ini digunakan untuk memproses perangkingan hotel berdasarkan kriteria & bobot.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Pemberitahuan: Logika perhitungan ranking metode SPK sedang diintegrasikan oleh tim backend.",
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// TAB 3: DATA POI / WISATA (SLOT UNTUK TEMAN KELOMPOK)
// ==========================================
class UserPoiTab extends StatelessWidget {
  const UserPoiTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.map_rounded, size: 80, color: Colors.green.shade700),
          const SizedBox(height: 16),
          const Text(
            "Destinasi Wisata & POI",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Daftar Point of Interest (POI) di sekitar Bali untuk menghitung kriteria jarak pada sistem keputusan.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}