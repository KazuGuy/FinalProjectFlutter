class MabacResult {
  final int rank;
  final int hotelId;
  final String hotelName;
  final double score;

  MabacResult({
    required this.rank,
    required this.hotelId,
    required this.hotelName,
    required this.score,
  });

  factory MabacResult.fromJson(Map<String, dynamic> j) => MabacResult(
        rank:      int.parse(j['rank'].toString()),
        hotelId:   int.parse(j['id'].toString()),
        hotelName: j['name'],
        score:     double.parse(j['score'].toString()),
      );
}
