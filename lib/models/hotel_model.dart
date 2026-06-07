class Hotel {
  final int id;
  final String name;
  final String type;
  final double price;
  final double rating;
  final int facilitiesCount;
  final String facilitiesDetail;
  final int discount;
  final double latitude;
  final double longitude;
  final double? avgDistance;

  Hotel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.rating,
    required this.facilitiesCount,
    required this.facilitiesDetail,
    required this.discount,
    required this.latitude,
    required this.longitude,
    this.avgDistance,
  });

  factory Hotel.fromJson(Map<String, dynamic> j) => Hotel(
        id:               int.parse(j['id'].toString()),
        name:             j['name'] ?? '',
        type:             j['type'] ?? 'hotel',
        price:            double.parse(j['price'].toString()),
        rating:           double.parse(j['rating'].toString()),
        facilitiesCount:  int.parse(j['facilities_count'].toString()),
        facilitiesDetail: j['facilities_detail'] ?? '',
        discount:         int.parse(j['discount'].toString()),
        latitude:         double.parse(j['latitude'].toString()),
        longitude:        double.parse(j['longitude'].toString()),
        avgDistance:      j['avg_distance'] != null
                            ? double.parse(j['avg_distance'].toString())
                            : null,
      );
}
