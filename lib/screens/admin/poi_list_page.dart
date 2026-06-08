import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import 'package:flutter_map/flutter_map.dart'; // Core library
import 'package:latlong2/latlong.dart';      // Provides LatLng

class PoiListPage extends StatefulWidget {
  const PoiListPage({super.key});

  @override
  State<PoiListPage> createState() => _PoiListPageState();
}

class _PoiListPageState extends State<PoiListPage> {
  final ApiService _api = ApiService();
  List<dynamic> _pois = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPois();
  }

  Future<void> _loadPois() async {
    setState(() => _isLoading = true);
    final pois = await _api.getPoi();
    setState(() {
      _pois = pois;
      _isLoading = false;
    });
  }

  void _showForm({Map<String, dynamic>? poi}) {
    final nameController = TextEditingController(text: poi?['nama_poi'] ?? '');
    final latController  = TextEditingController(text: poi?['latitude']?.toString() ?? '');
    final lngController  = TextEditingController(text: poi?['longitude']?.toString() ?? '');
    final mapController  = MapController();
    final isEdit = poi != null;

    LatLng? markerPos;
    final initLat = double.tryParse(poi?['latitude']?.toString() ?? '');
    final initLng = double.tryParse(poi?['longitude']?.toString() ?? '');
    if (initLat != null && initLng != null) {
      markerPos = LatLng(initLat, initLng);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit POI' : 'Tambah POI',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nama POI',
                    prefixIcon: const Icon(Icons.place_rounded, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Peta
                const Text('Ketuk peta untuk pilih lokasi',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 220,
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: markerPos ?? const LatLng(-8.65, 115.2),
                        initialZoom: markerPos != null ? 14 : 11,
                        onTap: (_, latlng) {
                          setModalState(() {
                            markerPos = latlng;
                            latController.text = latlng.latitude.toStringAsFixed(6);
                            lngController.text = latlng.longitude.toStringAsFixed(6);
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.finalprojectdss.app',
                        ),
                        if (markerPos != null)
                          MarkerLayer(markers: [
                            Marker(
                              point: markerPos!,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_pin,
                                  color: Color(0xFFFF6D00), size: 40),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Latitude',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Longitude',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || markerPos == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama dan lokasi wajib diisi')),
                        );
                        return;
                      }
                      final data = {
                        'nama_poi':  nameController.text.trim(),
                        'latitude':  latController.text,
                        'longitude': lngController.text,
                      };
                      bool success;
                      if (isEdit) {
                        success = await _api.updatePoi(int.parse(poi['id'].toString()), data);
                      } else {
                        success = await _api.addPoi(data);
                      }
                      Navigator.pop(context);
                      if (success) {
                        _loadPois();
                        _showSnackBar(isEdit ? 'POI berhasil diperbarui' : 'POI berhasil ditambahkan', Colors.green);
                      } else {
                        _showSnackBar('Gagal menyimpan POI', Colors.red);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0194F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah POI'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deletePoi(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus POI'),
        content: const Text('Yakin ingin menghapus POI ini? Semua data jarak ke hotel juga akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _api.deletePoi(id);
      if (success) {
        _loadPois();
        _showSnackBar('POI berhasil dihapus', Colors.green);
      } else {
        _showSnackBar('Gagal menghapus POI', Colors.red);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Data POI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0194F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF0194F3),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah POI'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pois.isEmpty
              ? const Center(child: Text('Belum ada POI.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pois.length,
                  itemBuilder: (context, index) {
                    final poi = _pois[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.place_rounded, color: Colors.green.shade700),
                        ),
                        title: Text(
                          poi['nama_poi'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${poi['latitude']}, ${poi['longitude']}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF0194F3)),
                              onPressed: () => _showForm(poi: poi),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.red),
                              onPressed: () => _deletePoi(int.parse(poi['id'].toString())),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}