class Criteria {
  final int id;
  final String code;
  final String name;
  final String type; // 'cost' | 'benefit'
  final double defaultWeight;
  double weight; // bobot yang dipakai user di sesi evaluasi

  Criteria({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.defaultWeight,
    double? weight,
  }) : weight = weight ?? defaultWeight;

  factory Criteria.fromJson(Map<String, dynamic> j) => Criteria(
        id:            int.parse(j['id'].toString()),
        code:          j['code'],
        name:          j['name'],
        type:          j['type'],
        defaultWeight: double.parse(j['default_weight'].toString()),
      );
}
