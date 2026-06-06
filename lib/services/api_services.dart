import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
 final String baseUrl = "http://localhost:8080/api";

  Future<List<dynamic>> getHotels() async {
    final response = await http.get(Uri.parse('$baseUrl/hotels'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data']; // Mengambil array dari JSON
    } else {
      throw Exception('Gagal memuat data');
    }
  }

  Future<void> deleteHotel(int id) async {
    await http.delete(Uri.parse('$baseUrl/hotels/$id'));
  }
  // Tambahkan kedua fungsi ini di dalam class ApiService Anda:

Future<bool> addHotel(Map<String, String> hotelData) async {
  final response = await http.post(
    Uri.parse('$baseUrl/hotels'),
    body: hotelData,
  );
  return response.statusCode == 200 || response.statusCode == 201;
}

Future<bool> updateHotel(int id, Map<String, String> hotelData) async {
  final response = await http.put(
    Uri.parse('$baseUrl/hotels/$id'),
    body: hotelData,
  );
  return response.statusCode == 200;
}
}