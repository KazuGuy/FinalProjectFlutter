import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_services.dart';
import '../auth/login_page.dart';
import 'evaluation_page.dart';

class DashboardUserPageState extends State<DashboardUserPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const UserHomeTab(),         // Tab 1: Home (Traveloka List & Map + Filter)
      const EvaluationPage(),      // Tab 2: Rekomendasi MABAC DSS (Real Screen)
      const UserPoiMapTab(),       // Tab 3: Wisata POI (Interactive Map + Search)
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color travelokaBlue = Color(0xFF0194F3);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
            selectedIcon: Icon(Icons.home_rounded, color: travelokaBlue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: travelokaBlue),
            label: 'Rekomendasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: travelokaBlue),
            label: 'Wisata (POI)',
          ),
        ],
      ),
    );
  }
}

class DashboardUserPage extends StatefulWidget {
  const DashboardUserPage({super.key});

  @override
  State<DashboardUserPage> createState() => DashboardUserPageState();
}

// =========================================================================
// TAB 1: USER HOME - MENAMPILKAN HOTEL DENGAN STYLE TRAVELOKA + FILTER + MAP
// =========================================================================
class UserHomeTab extends StatefulWidget {
  const UserHomeTab({super.key});

  @override
  State<UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends State<UserHomeTab> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  // Filters State
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  double _minRating = 0.0;
  bool _hasDiscount = false;
  String? _selectedType;
  String _sortOrder = 'rating_desc';

  // Toggle View Mode: true = List, false = Map
  bool _isListView = true;

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  // Data
  List<dynamic> _hotels = [];
  List<dynamic> _pois = [];
  bool _isLoading = true;

  // Popup state for map
  Map<String, dynamic>? _selectedMapHotel;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final hotels = await _apiService.getHotelsWithFilter(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating == 0.0 ? null : _minRating,
        hasDiscount: _hasDiscount,
        type: _selectedType,
        sort: _sortOrder,
      );
      final pois = await _apiService.getPoi();
      setState(() {
        _hotels = hotels;
        _pois = pois;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _minPrice = null;
      _maxPrice = null;
      _minRating = 0.0;
      _hasDiscount = false;
      _selectedType = null;
      _sortOrder = 'rating_desc';
      _searchController.clear();
    });
    _fetchData();
  }

  void _showFilterBottomSheet() {
    final minPriceController = TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final maxPriceController = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');
    double localRating = _minRating;
    bool localDiscount = _hasDiscount;
    String? localType = _selectedType;
    String localSort = _sortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Filter & Urutkan",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          minPriceController.clear();
                          maxPriceController.clear();
                          localRating = 0.0;
                          localDiscount = false;
                          localType = null;
                          localSort = 'rating_desc';
                        });
                      },
                      child: const Text("Reset", style: TextStyle(color: Color(0xFFFF6D00))),
                    )
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // URUTKAN
                const Text("Urutkan Berdasarkan", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: localSort,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rating_desc', child: Text("Skor Review Tertinggi")),
                    DropdownMenuItem(value: 'price_asc', child: Text("Harga Terendah")),
                    DropdownMenuItem(value: 'price_desc', child: Text("Harga Tertinggi")),
                    DropdownMenuItem(value: 'discount_desc', child: Text("Diskon Terbesar")),
                    DropdownMenuItem(value: 'facilities_desc', child: Text("Fasilitas Terbanyak")),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => localSort = val);
                  },
                ),
                const SizedBox(height: 16),

                // HARGA
                const Text("Kisaran Harga per Malam", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Min (Rp)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Max (Rp)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // RATING SLIDER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Rating Minimum", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      localRating == 0.0 ? "Semua rating" : "⭐ ${localRating.toStringAsFixed(1)} ke atas",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0194F3)),
                    ),
                  ],
                ),
                Slider(
                  min: 0.0,
                  max: 10.0,
                  divisions: 20,
                  activeColor: const Color(0xFF0194F3),
                  value: localRating,
                  onChanged: (val) => setModalState(() => localRating = val),
                ),
                const SizedBox(height: 12),

                // TIPE AKOMODASI
                const Text("Tipe Akomodasi", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['resort', 'villa', 'hotel', 'apartment', 'guesthouse'].map((type) {
                    final isSelected = localType == type;
                    return ChoiceChip(
                      label: Text(type.toUpperCase()),
                      selected: isSelected,
                      selectedColor: const Color(0xFFEAF7FF),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF0194F3) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setModalState(() {
                          localType = selected ? type : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // PROMO DISKON
                SwitchListTile(
                  title: const Text("Tampilkan diskon saja", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  value: localDiscount,
                  activeThumbColor: const Color(0xFF0194F3),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setModalState(() => localDiscount = val),
                ),
                const SizedBox(height: 20),

                // APPLY BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _minPrice = double.tryParse(minPriceController.text);
                        _maxPrice = double.tryParse(maxPriceController.text);
                        _minRating = localRating;
                        _hasDiscount = localDiscount;
                        _selectedType = localType;
                        _sortOrder = localSort;
                      });
                      _fetchData();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0194F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Terapkan Filter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return "0";
    final p = double.tryParse(price.toString())?.toInt() ?? 0;
    return p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  // List of placeholder images for premium hotel look
  static const List<String> _hotelImages = [
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=500&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1540541338287-41700207dee6?w=500&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=500&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=500&auto=format&fit=crop&q=60',
  ];

  @override
  Widget build(BuildContext context) {
    const Color travelokaBlue = Color(0xFF0194F3);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Traveloka-style blue header
            Container(
              color: travelokaBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "BaliStay DSS",
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                          Text(
                            "Traveloka UI • Web connected",
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                          )
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
                  const SizedBox(height: 14),

                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (val) {
                              setState(() => _searchQuery = val);
                              _fetchData();
                            },
                            decoration: InputDecoration(
                              hintText: "Cari hotel atau area...",
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: travelokaBlue),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () {
                                        setState(() => _searchQuery = '');
                                        _searchController.clear();
                                        _fetchData();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Toggle Map/List Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isListView ? Icons.map_rounded : Icons.list_rounded,
                            color: travelokaBlue,
                          ),
                          onPressed: () => setState(() => _isListView = !_isListView),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quick Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isLoading ? "Memuat..." : "Menampilkan ${_hotels.length} hotel",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _showFilterBottomSheet,
                            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                            label: const Text("Filter", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _minPrice != null ||
                              _maxPrice != null ||
                              _minRating != 0.0 ||
                              _hasDiscount ||
                              _selectedType != null)
                            TextButton.icon(
                              onPressed: _resetFilters,
                              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFECE0), size: 16),
                              label: const Text("Reset", style: TextStyle(color: Color(0xFFFFECE0), fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hotels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text("Tidak ada hotel yang sesuai kriteria.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              TextButton(onPressed: _resetFilters, child: const Text("Tampilkan Semua Hotel"))
                            ],
                          ),
                        )
                      : _isListView
                          ? _buildListView()
                          : _buildMapView(),
            )
          ],
        ),
      ),
    );
  }

  // ── USER HOME: LIST VIEW STYLE ──────────────────────────────────────────────
  Widget _buildListView() {
    const Color travelokaBlue = Color(0xFF0194F3);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hotels.length,
      itemBuilder: (context, index) {
        final h = _hotels[index];
        final type = h['type']?.toString().toUpperCase() ?? 'HOTEL';
        final discount = int.tryParse(h['discount']?.toString() ?? '0') ?? 0;
        final rating = double.tryParse(h['rating']?.toString() ?? '0.0') ?? 0.0;
        final facilitiesCount = int.tryParse(h['facilities_count']?.toString() ?? '0') ?? 0;
        final avgDistance = h['avg_distance'] != null ? double.tryParse(h['avg_distance'].toString()) : null;

        // Pick photo from list based on index
        final photo = _hotelImages[index % _hotelImages.length];

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Header + Discount Badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      photo,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.hotel, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  if (discount > 0)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6D00), // Orange badge
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$discount% OFF",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              // Card details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      h['facilities_detail'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(color: travelokaBlue, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Skor review pengguna",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          "$facilitiesCount fasilitas",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    if (avgDistance != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${avgDistance.toStringAsFixed(1)} km rata-rata jarak ke POI",
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      )
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Mulai dari", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text(
                              "Rp ${_formatPrice(h['price'])}",
                              style: const TextStyle(color: travelokaBlue, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const Text("per malam", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Sinyal sukses membandingkan, arahkan user ke tab Rekomendasi (Tab index 1)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Menambahkan ${h['name']} ke DSS. Buka tab Rekomendasi untuk mulai."),
                                action: SnackBarAction(
                                  label: "Buka",
                                  textColor: Colors.white,
                                  onPressed: () {
                                    final parentState = context.findAncestorStateOfType<DashboardUserPageState>();
                                    parentState?.setState(() {
                                      parentState._selectedIndex = 1;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: travelokaBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text("Bandingkan (DSS)"),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // ── USER HOME: MAP VIEW STYLE ──────────────────────────────────────────────
  Widget _buildMapView() {
    const Color travelokaBlue = Color(0xFF0194F3);

    // Create markers list
    final List<Marker> markers = [];

    // Add hotels markers (custom price-tag design)
    for (var h in _hotels) {
      final lat = double.tryParse(h['latitude']?.toString() ?? '');
      final lng = double.tryParse(h['longitude']?.toString() ?? '');
      final priceInt = double.tryParse(h['price']?.toString() ?? '')?.toInt() ?? 0;
      final priceShort = priceInt >= 1000000
          ? '${(priceInt / 1000000).toStringAsFixed(1)}M'
          : '${(priceInt / 1000).toStringAsFixed(0)}k';

      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 80,
            height: 40,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedMapHotel = h);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: travelokaBlue,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hotel_rounded, color: Colors.white, size: 11),
                      const SizedBox(width: 2),
                      Text(
                        priceShort,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // Add POIs markers (amber location-pins)
    for (var poi in _pois) {
      final lat = double.tryParse(poi['latitude']?.toString() ?? '');
      final lng = double.tryParse(poi['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Point of Interest (POI)"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(poi['nama_poi'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Koordinat: $lat, $lng", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
                    ],
                  ),
                );
              },
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFFFF6D00), // Traveloka Orange
                size: 24,
              ),
            ),
          ),
        );
      }
    }

    // Determine initial center
    LatLng initialCenter = const LatLng(-8.65, 115.2); // Denpasar area
    if (markers.isNotEmpty) {
      initialCenter = markers.first.point;
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 11,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.finalprojectdss.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Floating info banner explaining markers color
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: travelokaBlue, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 6),
                    const Text("Hotel (Skor & Harga)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF6D00), size: 14),
                    const SizedBox(width: 4),
                    const Text("Tempat Wisata (POI)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Pop up details for clicked hotel marker
        if (_selectedMapHotel != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedMapHotel!['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEAF7FF), borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  "⭐ ${double.tryParse(_selectedMapHotel!['rating']?.toString() ?? '0.0')?.toStringAsFixed(1)}",
                                  style: const TextStyle(color: travelokaBlue, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rp ${_formatPrice(_selectedMapHotel!['price'])} / malam",
                            style: const TextStyle(color: travelokaBlue, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            _selectedMapHotel!['facilities_detail'] ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final parentState = context.findAncestorStateOfType<DashboardUserPageState>();
                            parentState?.setState(() {
                              parentState._selectedIndex = 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: travelokaBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("DSS Rekom.", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => setState(() => _selectedMapHotel = null),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text("Tutup", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }
}

// =========================================================================
// TAB 3: WISATA POI TAB - INTERACTIVE MAP + DATA TABLE SEARCH
// =========================================================================
class UserPoiMapTab extends StatefulWidget {
  const UserPoiMapTab({super.key});

  @override
  State<UserPoiMapTab> createState() => _UserPoiMapTabState();
}

class _UserPoiMapTabState extends State<UserPoiMapTab> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  List<dynamic> _pois = [];
  List<dynamic> _filteredPois = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPois();
  }

  Future<void> _fetchPois() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getPoi();
    setState(() {
      _pois = data;
      _filteredPois = data;
      _isLoading = false;
    });
  }

  void _filterPois(String q) {
    setState(() {
      _filteredPois = _pois.where((poi) {
        final name = poi['nama_poi']?.toString().toLowerCase() ?? '';
        return name.contains(q.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color travelokaBlue = Color(0xFF0194F3);

    // Build markers
    final List<Marker> markers = _pois.map((poi) {
      final lat = double.tryParse(poi['latitude']?.toString() ?? '0.0') ?? 0.0;
      final lng = double.tryParse(poi['longitude']?.toString() ?? '0.0') ?? 0.0;
      return Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            _mapController.move(LatLng(lat, lng), 14);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Point of Interest: ${poi['nama_poi']}"),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Color(0xFFFF6D00),
            size: 26,
          ),
        ),
      );
    }).toList();

    // Default center Denpasar
    LatLng defaultCenter = const LatLng(-8.65, 115.2);
    if (_pois.isNotEmpty) {
      final lat = double.tryParse(_pois.first['latitude']?.toString() ?? '') ?? -8.65;
      final lng = double.tryParse(_pois.first['longitude']?.toString() ?? '') ?? 115.2;
      defaultCenter = LatLng(lat, lng);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Point of Interest (Bali)", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: travelokaBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // POI Map area (Interactive Leaflet equivalent)
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: defaultCenter,
                          initialZoom: 11,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.finalprojectdss.app',
                          ),
                          MarkerLayer(markers: markers),
                        ],
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton(
                          backgroundColor: Colors.white,
                          onPressed: () {
                            if (_pois.isNotEmpty) {
                              final lat = double.tryParse(_pois.first['latitude']?.toString() ?? '0.0') ?? -8.65;
                              final lng = double.tryParse(_pois.first['longitude']?.toString() ?? '0.0') ?? 115.2;
                              _mapController.move(LatLng(lat, lng), 11);
                            }
                          },
                          child: const Icon(Icons.my_location, color: travelokaBlue),
                        ),
                      )
                    ],
                  ),
                ),

                // POI Search Sidebar/Bottom panel
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Form
                          Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300, width: 0.8),
                            ),
                            child: TextField(
                              onChanged: _filterPois,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search, color: Colors.grey),
                                hintText: "Cari Destinasi Wisata / POI...",
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _filteredPois.isEmpty
                                ? const Center(child: Text("POI tidak ditemukan."))
                                : ListView.builder(
                                    itemCount: _filteredPois.length,
                                    itemBuilder: (context, index) {
                                      final poi = _filteredPois[index];
                                      final lat = double.tryParse(poi['latitude']?.toString() ?? '0.0') ?? 0.0;
                                      final lng = double.tryParse(poi['longitude']?.toString() ?? '0.0') ?? 0.0;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                          leading: const CircleAvatar(
                                            backgroundColor: Color(0xFFFFECE0),
                                            child: Icon(Icons.camera_alt_rounded, color: Color(0xFFFF6D00), size: 18),
                                          ),
                                          title: Text(poi['nama_poi'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          subtitle: Text("Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          trailing: const Icon(Icons.gps_fixed_rounded, color: travelokaBlue, size: 18),
                                          onTap: () {
                                            _mapController.move(LatLng(lat, lng), 15);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
