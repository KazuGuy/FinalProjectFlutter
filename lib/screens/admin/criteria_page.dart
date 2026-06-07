import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class CriteriaPage extends StatefulWidget {
  const CriteriaPage({super.key});

  @override
  State<CriteriaPage> createState() => _CriteriaPageState();
}

class _CriteriaPageState extends State<CriteriaPage> {
  final ApiService _api = ApiService();
  List<dynamic> _criterias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCriterias();
  }

  Future<void> _loadCriterias() async {
    setState(() => _isLoading = true);
    final criterias = await _api.getCriterias();
    setState(() {
      _criterias = criterias;
      _isLoading = false;
    });
  }

  void _showEditForm(Map<String, dynamic> criteria) {
    final weightController = TextEditingController(
      text: criteria['default_weight'].toString(),
    );
    String selectedType = criteria['type'];

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Kriteria ${criteria['code']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                criteria['name'],
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Tipe
              const Text('Tipe', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: ['benefit', 'cost'].map((type) {
                  final isSelected = selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = type),
                      child: Container(
                        margin: EdgeInsets.only(right: type == 'benefit' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (type == 'benefit' ? Colors.green.shade50 : Colors.red.shade50)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? (type == 'benefit' ? Colors.green : Colors.red)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              type == 'benefit' ? '↑ Benefit' : '↓ Cost',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (type == 'benefit' ? Colors.green.shade700 : Colors.red.shade700)
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              type == 'benefit' ? 'Makin besar makin baik' : 'Makin kecil makin baik',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Bobot default
              const Text('Bobot Default', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'contoh: 1.5',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixText: '(relatif)',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bobot relatif antar kriteria, dinormalisasi otomatis saat evaluasi.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final data = {
                      'type':           selectedType,
                      'default_weight': weightController.text.trim(),
                    };
                    final success = await _api.updateCriteria(
                      int.parse(criteria['id'].toString()),
                      data,
                    );
                    Navigator.pop(context);
                    if (success) {
                      _loadCriterias();
                      _showSnackBar('Kriteria berhasil diperbarui', Colors.green);
                    } else {
                      _showSnackBar('Gagal memperbarui kriteria', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0194F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: const Text('Kriteria SPK', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0194F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _criterias.length,
              itemBuilder: (context, index) {
                final c = _criterias[index];
                final isBenefit = c['type'] == 'benefit';
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c['code'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0194F3),
                        ),
                      ),
                    ),
                    title: Text(
                      c['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBenefit ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isBenefit ? '↑ Benefit' : '↓ Cost',
                            style: TextStyle(
                              fontSize: 11,
                              color: isBenefit ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bobot: ${c['default_weight']}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF0194F3)),
                      onPressed: () => _showEditForm(c),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
