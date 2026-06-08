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
  int _step = 1;
  List<dynamic> _hotels    = [];
  List<dynamic> _pois      = [];
  List<dynamic> _criterias = [];
  List<dynamic> _results   = [];

  // Pilihan user
  final Set<int> _selectedHotelIds = {};
  int? _selectedPoiId;
  final Map<String, double> _weights = {};

  // FIX: Controllers disimpan di Map agar tidak di-recreate setiap build
  final Map<String, TextEditingController> _controllers = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Load Data ─────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final hotels    = await _api.getHotels();
      final pois      = await _api.getPoi();
      final criterias = await _api.getCriterias();

      // Null-safe: pastikan semua adalah List
      final safeHotels    = hotels    is List ? List<dynamic>.from(hotels)    : <dynamic>[];
      final safePois      = pois      is List ? List<dynamic>.from(pois)      : <dynamic>[];
      final safeCriterias = criterias is List ? List<dynamic>.from(criterias) : <dynamic>[];

      // Inisialisasi bobot & controllers sekali saja
      for (final c in safeCriterias) {
        if (c == null) continue;
        final code   = c['code']?.toString() ?? '';
        if (code.isEmpty) continue;
        final weight = double.tryParse(c['default_weight']?.toString() ?? '0') ?? 0.0;
        _weights[code] = weight;
        _controllers[code] = TextEditingController(text: weight.toStringAsFixed(0));
      }

      setState(() {
        _hotels    = safeHotels;
        _pois      = safePois;
        _criterias = safeCriterias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Gagal memuat data: $e', Colors.red);
      }
    }
  }

  // ── Calculate ─────────────────────────────────────────────
  Future<void> _calculate() async {
    if (_selectedHotelIds.isEmpty || _selectedPoiId == null) return;

    final total = _weights.values.fold(0.0, (a, b) => a + b);
    if ((total - 100).abs() > 0.01) {
      _showSnackBar('Total bobot harus 100%. Sekarang: ${total.toStringAsFixed(1)}%', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await _api.calculateMabac(
        hotelIds: _selectedHotelIds.toList(),
        poiId:    _selectedPoiId!,
        weights:  _weights,
      );
      setState(() {
        _results   = data is List ? List<dynamic>.from(data) : [];
        _step      = 3;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Gagal menghitung MABAC: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _reset() {
    setState(() {
      _step = 1;
      _selectedHotelIds.clear();
      _selectedPoiId = null;
      _results       = [];
      for (final c in _criterias) {
        if (c == null) continue;
        final code   = c['code']?.toString() ?? '';
        if (code.isEmpty) continue;
        final weight = double.tryParse(c['default_weight']?.toString() ?? '0') ?? 0.0;
        _weights[code] = weight;
        _controllers[code]?.text = weight.toStringAsFixed(0);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // FIX: Loading ada di dalam Column, bukan menggantikan seluruh widget tree
    return Column(
      children: [
        _buildStepper(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _step == 1
                  ? _buildStep1()
                  : _step == 2
                      ? _buildStep2()
                      : _buildStep3(),
        ),
      ],
    );
  }

  // ── Stepper ───────────────────────────────────────────────
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
                      : Text(
                          '$num',
                          style: TextStyle(
                            color: active ? Colors.white : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, thickness: 1),
                  ),
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
              final h = _hotels[index];
              if (h == null) return const SizedBox.shrink();
              final id      = int.tryParse(h['id']?.toString() ?? '') ?? 0;
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
                  title: Text(
                    h['name']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatPrice(h['price'])} / malam  ·  ⭐ ${h['rating'] ?? '-'}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0194F3)),
                      ),
                      Text(
                        '${h['facilities_count'] ?? 0} fasilitas · ${h['discount'] ?? 0}% diskon · ${h['type'] ?? '-'}',
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
    final total   = _weights.values.fold(0.0, (a, b) => a + b);
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
                const Text(
                  'POI Acuan Jarak',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
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
                      items: _pois
                          .where((poi) => poi != null)
                          .map((poi) {
                            return DropdownMenuItem<int>(
                              value: int.tryParse(poi['id']?.toString() ?? '') ?? 0,
                              child: Text(poi['nama_poi']?.toString() ?? ''),
                            );
                          })
                          .toList(),
                      onChanged: (val) => setState(() => _selectedPoiId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bobot Kriteria
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bobot Kriteria',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Total: ${total.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isValid ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Total harus 100%',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // FIX: null-safe criteria loop, controller dari Map
                ..._criterias.map((c) {
                  if (c == null) return const SizedBox.shrink();
                  final code = c['code']?.toString() ?? '';
                  if (code.isEmpty) return const SizedBox.shrink();
                  final w = _weights[code] ?? 0.0;

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
                            Text(
                              c['name']?.toString() ?? code,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
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
                                    // FIX: pakai controller dari Map, bukan buat baru setiap build
                                    controller: _controllers[code],
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide:
                                            BorderSide(color: Colors.grey.shade300),
                                      ),
                                      suffixText: '%',
                                    ),
                                    onChanged: (val) {
                                      _weights[code] = double.tryParse(val) ?? 0;
                                      // Rebuild hanya untuk update total label
                                      setState(() {});
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
          label: isValid
              ? 'Bobot valid ✓'
              : 'Total bobot: ${total.toStringAsFixed(1)}% (harus 100%)',
          buttonText: 'Hitung →',
          enabled: isValid && _selectedPoiId != null,
          onPressed: _calculate,
        ),
      ],
    );
  }

  // ── Step 3: Hasil ─────────────────────────────────────────
  Widget _buildStep3() {
    if (_results.isEmpty) {
      return Column(
        children: [
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Tidak ada hasil.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cek console untuk detail response API.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Winner card
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
                      const Text(
                        '🏆 Rekomendasi Terbaik',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _results[0]['name']?.toString() ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Skor MABAC: ${(double.tryParse(_results[0]['score']?.toString() ?? '0') ?? 0.0).toStringAsFixed(4)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ranking list
                ..._results.map((r) {
                  if (r == null) return const SizedBox.shrink();
                  final rank  = int.tryParse(r['rank']?.toString() ?? '0') ?? 0;
                  final score = double.tryParse(r['score']?.toString() ?? '0') ?? 0.0;
                  final medal = rank == 1
                      ? '🥇'
                      : rank == 2
                          ? '🥈'
                          : rank == 3
                              ? '🥉'
                              : '#$rank';
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Text(medal,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(
                        r['name']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0194F3),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final p = int.tryParse(price?.toString() ?? '0') ?? 0;
    return p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}