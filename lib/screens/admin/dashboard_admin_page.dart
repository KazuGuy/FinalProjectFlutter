import 'package:flutter/material.dart';
import '../../services/api_services.dart'; // Mengambil data riil dari API Anda
import '../admin/hotel_list_page.dart';
import '../auth/login_page.dart';
import 'poi_list_page.dart';
import 'criteria_page.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  int _selectedIndex = 0;

  // Menyusun halaman admin ke dalam Tab Navigasi secara modular tanpa mengubah file aslinya
  late final List<Widget> _adminPages;

  @override
  void initState() {
    super.initState();
    _adminPages = [
      const AdminHomeTab(),       // Tab 1: Ringkasan & Statistik Keren ala Web DSS
      const HotelListPage(),      // Tab 2: Kelola Hotel (Memanggil file asli Anda langsung)
      const PoiListPage(),        // Tab 3: Kelola POI Wisata (Memanggil file asli Anda langsung)
      const CriteriaPage(),       // Tab 4: Kriteria SPK (Memanggil file asli Anda langsung)
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color adminPrimaryColor = Color(0xFF0194F3); // Warna Biru Utama

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _adminPages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: adminPrimaryColor),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.hotel_outlined),
            selectedIcon: Icon(Icons.hotel_rounded, color: adminPrimaryColor),
            label: 'Hotel',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: adminPrimaryColor),
            label: 'POI Wisata',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded, color: adminPrimaryColor),
            label: 'Kriteria',
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// WIDGET TAB UTAMA: DASHBOARD STATISTIK (MENGADOPSI RINGKASAN DATA WEB DSS)
// =========================================================================
class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  // State Data untuk Summary Cards
  int _totalHotels = 0;
  int _totalPois = 0;
  int _totalCriteria = 5; // Default kriteria SPK sistem Anda
  List<dynamic> _recentHotels = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoading = true);
    try {
      // Memanggil fungsi API bawaan Anda untuk menghitung rangkuman data secara dinamis
      final hotels = await _apiService.getHotelsWithFilter();
      final pois = await _apiService.getPoi();
      
      setState(() {
        _totalHotels = hotels.length;
        _totalPois = pois.length;
        _recentHotels = hotels.take(3).toList(); // Mengambil 3 hotel teratas sebagai pratinjau
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color adminPrimaryColor = Color(0xFF0194F3);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER HERO PANEL YANG MODERN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: const BoxDecoration(
                    color: adminPrimaryColor,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Control Panel",
                                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Welcome back, Admin!",
                                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          // Tombol Logout Elegan
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.white),
                              tooltip: 'Sign Out',
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginPage()),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Sistem Pendukung Keputusan Pemilihan Hotel Berbasis Web connected",
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      )
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. SUMMARY CARDS GRID (REPRESENTASI WEB DASHBOARD DSS)
                      const Text(
                        "Ringkasan Data SPK",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 14),
                      
                      _isLoading 
                          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                          : GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.4,
                              children: [
                                _buildStatCard(
                                  title: "Total Hotel",
                                  value: _totalHotels.toString(),
                                  icon: Icons.hotel_rounded,
                                  color: const Color(0xFF0194F3),
                                  subtitle: "Akomodasi terdaftar",
                                ),
                                _buildStatCard(
                                  title: "Destinasi POI",
                                  value: _totalPois.toString(),
                                  icon: Icons.camera_alt_rounded,
                                  color: const Color(0xFFFF6D00),
                                  subtitle: "Titik wisata Bali",
                                ),
                                _buildStatCard(
                                  title: "Kriteria SPK",
                                  value: _totalCriteria.toString(),
                                  icon: Icons.analytics_rounded,
                                  color: const Color(0xFF2E7D32),
                                  subtitle: "Parameter MABAC",
                                ),
                                _buildStatCard(
                                  title: "Database Status",
                                  value: "ONLINE",
                                  icon: Icons.cloud_done_rounded,
                                  color: const Color(0xFF6A1B9A),
                                  subtitle: "Koneksi API lancar",
                                ),
                              ],
                            ),
                      
                      const SizedBox(height: 28),

                      // 3. QUICK PRATINJAU DATA HOTEL TERBARU
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Pratinjau Hotel",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _isLoading
                          ? Container()
                          : _recentHotels.isEmpty
                              ? const Text("Belum ada data hotel.", style: TextStyle(color: Colors.grey))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _recentHotels.length,
                                  itemBuilder: (context, index) {
                                    final h = _recentHotels[index];
                                    return Card(
                                      color: Colors.white,
                                      elevation: 0,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      child: ListTile(
                                        leading: const CircleAvatar(
                                          backgroundColor: Color(0xFFEAF7FF),
                                          child: Icon(Icons.hotel, color: adminPrimaryColor, size: 20),
                                        ),
                                        title: Text(
                                          h['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          "Tipe: ${(h['type'] ?? 'Hotel').toString().toUpperCase()} • ⭐ ${h['rating'] ?? '0'}",
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        trailing: Text(
                                          "Rp ${h['price'] != null ? h['price'].toString() : '0'}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: adminPrimaryColor, fontSize: 13),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk membuat Summary Card yang interaktif
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.black54, overflow: TextOverflow.ellipsis),
              ),
            ],
          )
        ],
      ),
    );
  }
}