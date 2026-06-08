import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_services.dart';

class HotelFormPage extends StatefulWidget {
  final Map<String, dynamic>? hotel; // null = tambah, isi = edit
  const HotelFormPage({super.key, this.hotel});

  @override
  State<HotelFormPage> createState() => _HotelFormPageState();
}

class _HotelFormPageState extends State<HotelFormPage> {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();

  // Form controllers
  final _nameController        = TextEditingController();
  final _priceController       = TextEditingController();
  final _ratingController      = TextEditingController();
  final _facilitiesCountController = TextEditingController();
  final _facilitiesDetailController = TextEditingController();
  final _discountController    = TextEditingController();
  final _latController         = TextEditingController();
  final _lngController         = TextEditingController();

  String _selectedType = 'hotel';
  LatLng? _markerPosition;
  bool _isSaving = false;

  final List<String> _types = ['resort', 'villa', 'hotel', 'apartment', 'guesthouse'];

  @override
  void initState() {
    super.initState();
    if (widget.hotel != null) {
      final h = widget.hotel!;
      _nameController.text             = h['name'] ?? '';
      _priceController.text            = h['price']?.toString() ?? '';
      _ratingController.text           = h['rating']?.toString() ?? '';
      _facilitiesCountController.text  = h['facilities_count']?.toString() ?? '';
      _facilitiesDetailController.text = h['facilities_detail'] ?? '';
      _discountController.text         = h['discount']?.toString() ?? '0';
      _selectedType                    = h['type'] ?? 'hotel';

      final lat = double.tryParse(h['latitude']?.toString() ?? '');
      final lng = double.tryParse(h['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        _markerPosition = LatLng(lat, lng);
        _latController.text = lat.toStringAsFixed(6);
        _lngController.text = lng.toStringAsFixed(6);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _facilitiesCountController.dispose();
    _facilitiesDetailController.dispose();
    _discountController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _markerPosition = latlng;
      _latController.text = latlng.latitude.toStringAsFixed(6);
      _lngController.text = latlng.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _ratingController.text.isEmpty ||
        _facilitiesCountController.text.isEmpty ||
        _facilitiesDetailController.text.isEmpty ||
        _markerPosition == null) {
      _showSnackBar('Semua field wajib diisi dan pilih lokasi di peta', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'name':              _nameController.text.trim(),
      'type':              _selectedType,
      'price':             _priceController.text.trim(),
      'rating':            _ratingController.text.trim(),
      'facilities_count':  _facilitiesCountController.text.trim(),
      'facilities_detail': _facilitiesDetailController.text.trim(),
      'discount':          _discountController.text.trim().isEmpty ? '0' : _discountController.text.trim(),
      'latitude':          _latController.text,
      'longitude':         _lngController.text,
    };

    bool success;
    if (widget.hotel != null) {
      success = await _api.updateHotel(int.parse(widget.hotel!['id'].toString()), data);
    } else {
      success = await _api.addHotel(data);
    }

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Gagal menyimpan data hotel', Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    const travelokaBlue = Color(0xFF0194F3);
    final isEdit = widget.hotel != null;
    final initialCenter = _markerPosition ?? const LatLng(-8.65, 115.2);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Hotel' : 'Tambah Hotel',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: travelokaBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Peta ──────────────────────────────────────────
            const Text('Lokasi Hotel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Ketuk peta untuk menentukan koordinat hotel',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 260,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: _markerPosition != null ? 15 : 11,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.finalprojectdss.app',
                    ),
                    if (_markerPosition != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _markerPosition!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin, color: travelokaBlue, size: 40),
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
                  child: _coordField(_latController, 'Latitude'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _coordField(_lngController, 'Longitude'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Form Fields ───────────────────────────────────
            const Text('Informasi Hotel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),

            _inputField(_nameController, 'Nama Hotel', Icons.hotel_rounded),
            const SizedBox(height: 12),

            // Tipe
            const Text('Tipe Penginapan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.toUpperCase()),
                  selected: isSelected,
                  selectedColor: const Color(0xFFEAF7FF),
                  labelStyle: TextStyle(
                    color: isSelected ? travelokaBlue : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _inputField(_priceController, 'Harga/Malam (Rp)', Icons.payments_rounded, isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _inputField(_ratingController, 'Skor Review (0-10)', Icons.star_rounded, isDecimal: true)),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _inputField(_facilitiesCountController, 'Jml Fasilitas', Icons.category_rounded, isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _inputField(_discountController, 'Diskon (%)', Icons.local_offer_rounded, isNumber: true)),
              ],
            ),
            const SizedBox(height: 12),

            _inputField(_facilitiesDetailController, 'Detail Fasilitas', Icons.list_rounded, maxLines: 3),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: travelokaBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Hotel',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, IconData icon,
      {bool isNumber = false, bool isDecimal = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : isNumber
              ? TextInputType.number
              : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _coordField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}