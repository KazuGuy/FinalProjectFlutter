import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  final ApiService _api = ApiService();

  // State
  int _step = 1; // 1: pilih hotel, 2: pilih POI & bobot, 3: hasil
  List<dynamic> _hotels = [];
  List<dynamic> _pois = [];
  List<dynamic> _criterias = [];
  List<dynamic> _results = [];

  // Pilihan user
  final Set<int> _selectedHotelIds = {};
  int? _selectedPoiId;
  final Map<String, double> _weights = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final hotels    = await _api.getHotels();
    final pois      = await _api.getPoi();
    final criterias = await _api.getCriterias();

    // Set bobot default dari DB
    for (var c in criterias) {
      _weights[c['code']] = double.parse(c['default_weight'].toString());
    }

    setState(() {
      _hotels    = hotels;
      _pois      = pois;
      _criterias = criterias;
      _isLoading = false;
    });
  }

  Future<void> _calculate() async {
    // Validasi total bobot = 100
    final total = _weights.values.fold(0.0, (a, b) => a + b);
    if ((total - 100).abs() > 0.01) {
      _showSnackBar('Total bobot harus 100%. Sekarang: ${total.toStringAsFixed(1)}%', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final results = await _api.calculateMabac(
      hotelIds: _selectedHotelIds.toList(),
      poiId:    _selectedPoiId!,
      weights:  _weights,
    );

    setState(() {
      _results  = results;
      _step     = 3;
      _isLoading = false;
    });
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  void _reset() {
    setState(() {
      _step = 1;
      _selectedHotelIds.clear();
      _selectedPoiId = null;
      _results = [];
      for (var c in _criterias) {
        _weights[c['code']] = double.parse(c['default_weight'].toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildStepper(),
        Expanded(
          child: _step == 1
              ? _buildStep1()
              : _step == 2
                  ? _buildStep2()
                  : _buildStep3(),
        ),
      ],
    );
  }

  // ── Stepper ──────────────────────────────────────────────
  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: List.generate(3, (i) {
          final num    = i + 1;
          final active = _step == num;
          final done   = _step > num;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: done
                      ? Colors.green
                      : active
                          ? const Color(0xFF0194F3)
                          : Colors.grey.shade300,
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text('$num', style: TextStyle(
                          color: active ? Colors.white : Colors.grey,
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Text(
                  ['Pilih Hotel', 'Bobot', 'Hasil'][i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? const Color(0xFF0194F3) : Colors.grey,
                  ),
                ),
                if (i < 2)
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: Pilih Hotel ───────────────────────────────────
  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _hotels.length,
            itemBuilder: (context, index) {
              final h       = _hotels[index];
              final id      = int.parse(h['id'].toString());
              final checked = _selectedHotelIds.contains(id);
              return Card(
                color: checked ? const Color(0xFFE3F2FD) : Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: checked ? const Color(0xFF0194F3) : Colors.grey.shade200,
                    width: checked ? 2 : 1,
                  ),
                ),
                child: CheckboxListTile(
                  value: checked,
                  activeColor: const Color(0xFF0194F3),
                  onChanged: (_) {
                    setState(() {
                      if (checked) {
                        _selectedHotelIds.remove(id);
                      } else {
                        _selectedHotelIds.add(id);
                      }
                    });
                  },
                  title: Text(h['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatPrice(h['price'])} / malam  ·  ⭐ ${h['rating']}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0194F3)),
                      ),
                      Text(
                        '${h['facilities_count']} fasilitas · ${h['discount']}% diskon · ${h['type']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildBottomBar(
          label: '${_selectedHotelIds.length} hotel dipilih (min. 2)',
          buttonText: 'Lanjut →',
          enabled: _selectedHotelIds.length >= 2,
          onPressed: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  // ── Step 2: Pilih POI & Atur Bobot ────────────────────────
  Widget _buildStep2() {
    final total = _weights.values.fold(0.0, (a, b) => a + b);
    final isValid = (total - 100).abs() < 0.01;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // POI Selector
                const Text('POI Acuan Jarak',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text('Pilih Point of Interest'),
                      value: _selectedPoiId,
                      items: _pois.map((poi) {
                        return DropdownMenuItem<int>(
                          value: int.parse(poi['id'].toString()),
                          child: Text(poi['nama_poi'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedPoiId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bobot Kriteria
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bobot Kriteria',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'Total: ${total.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isValid ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const Text('Total harus 100%',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),

                ..._criterias.map((c) {
                  final code = c['code'] as String;
                  final w    = _weights[code] ?? 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c['name'] ?? code,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c['type'] == 'benefit'
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c['type'] == 'benefit' ? '↑ Benefit' : '↓ Cost',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c['type'] == 'benefit'
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      suffixText: '%',
                                    ),
                                    controller: TextEditingController(text: w.toStringAsFixed(0))
                                      ..selection = TextSelection.collapsed(offset: w.toStringAsFixed(0).length),
                                    onChanged: (val) {
                                      setState(() {
                                        _weights[code] = double.tryParse(val) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        _buildBottomBar(
          label: isValid ? 'Bobot valid ✓' : 'Total bobot: ${total.toStringAsFixed(1)}% (harus 100%)',
          buttonText: 'Hitung →',
          enabled: isValid && _selectedPoiId != null,
          onPressed: _calculate,
        ),
      ],
    );
  }

  // ── Step 3: Hasil ─────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Winner card
                if (_results.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0194F3), Color(0xFF005580)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🏆 Rekomendasi Terbaik',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          _results[0]['name'] ?? '',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Skor MABAC: ${double.parse(_results[0]['score'].toString()).toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Ranking list
                ..._results.map((r) {
                  final rank  = int.parse(r['rank'].toString());
                  final score = double.parse(r['score'].toString());
                  final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Text(medal, style: const TextStyle(fontSize: 24)),
                      title: Text(r['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        score >= 0 ? 'Di atas BAA ✓' : 'Di bawah BAA',
                        style: TextStyle(
                          color: score >= 0 ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        '${score >= 0 ? '+' : ''}${score.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: score >= 0 ? Colors.green : Colors.red,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Evaluasi Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0194F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  Widget _buildBottomBar({
    required String label,
    required String buttonText,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0194F3),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final p = int.parse(price.toString());
    return p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
