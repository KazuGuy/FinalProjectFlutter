class Poi {
  final int id;
  final String namaPoi;
  final double latitude;
  final double longitude;

  Poi({
    required this.id,
    required this.namaPoi,
    required this.latitude,
    required this.longitude,
  });

  factory Poi.fromJson(Map<String, dynamic> j) => Poi(
        id:        int.parse(j['id'].toString()),
        namaPoi:   j['nama_poi'],
        latitude:  double.parse(j['latitude'].toString()),
        longitude: double.parse(j['longitude'].toString()),
      );
}
