import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant/api_constants.dart';

class ApiService {
  final String baseUrl = ApiConstants.baseUrl;

  // ==========================================
  // 1. AUTHENTICATION: LOGIN
  // ==========================================
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Login Gagal, Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error Login API: $e");
      return null;
    }
  }

  // ==========================================
  // 2. AUTHENTICATION: REGISTER
  // ==========================================
  Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': 'user',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      print("Error Register API: $e");
      return null;
    }
  }

  // ==========================================
  // 3. CRUD HOTEL: GET ALL HOTELS
  // ==========================================
  Future<List<dynamic>> getHotels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/hotels'));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is Map && decodedData.containsKey('data')) {
          return decodedData['data'] ?? [];
        } else if (decodedData is List) {
          return decodedData;
        }
        return [];
      } else {
        print("Gagal mengambil data hotel, Status Code: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error Get Hotels API: $e");
      return [];
    }
  }

  // ==========================================
  // 4. CRUD HOTEL: ADD HOTEL
  // ==========================================
  Future<bool> addHotel(Map<String, String> hotelData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hotels'),
        body: hotelData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error Add Hotel API: $e");
      return false;
    }
  }

  // ==========================================
  // 5. CRUD HOTEL: UPDATE HOTEL
  // ==========================================
  Future<bool> updateHotel(int id, Map<String, String> hotelData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/hotels/$id'),
        body: hotelData,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Hotel API: $e");
      return false;
    }
  }

  // ==========================================
  // 6. CRUD HOTEL: DELETE HOTEL
  // ==========================================
  Future<bool> deleteHotel(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/hotels/$id'));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error Delete Hotel API: $e");
      return false;
    }
  }

  // ==========================================
  // 7. GET CRITERIAS
  // ==========================================
  Future<List<dynamic>> getCriterias() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/criterias'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'] ?? [];
        } else if (decoded is List) {
          return decoded;
        }
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get Criterias API: $e");
      return [];
    }
  }

  // ==========================================
  // 8. GET POI
  // ==========================================
  Future<List<dynamic>> getPoi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/poi'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'] ?? [];
        } else if (decoded is List) {
          return decoded;
        }
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get POI API: $e");
      return [];
    }
  }

  // ==========================================
  // 9. EVALUATION: KALKULASI MABAC
  // ==========================================
  Future<List<dynamic>> calculateMabac({
    required List<int> hotelIds,
    required int poiId,
    required Map<String, double> weights,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/evaluation/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'hotel_ids': hotelIds,
          'poi_id':    poiId,
          'weights':   weights,
        }),
      );

      // Log selalu agar mudah debug di console
      print("MABAC status : ${response.statusCode}");
      print("MABAC body   : ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Backend langsung return array
        if (decoded is List) {
          return List<dynamic>.from(decoded);
        }

        // Backend wrap dalam object — coba semua key yang umum dipakai
        if (decoded is Map) {
          for (final key in ['data', 'results', 'result', 'rankings', 'hotels']) {
            if (decoded.containsKey(key) && decoded[key] is List) {
              return List<dynamic>.from(decoded[key] as List);
            }
          }
          // Tidak ada key list yang dikenal — log untuk debug
          print("MABAC response keys: ${decoded.keys.toList()}");
          print("MABAC: Tidak ditemukan key list. Periksa struktur response backend.");
        }

        return [];
      }

      print("Kalkulasi gagal: ${response.statusCode} — ${response.body}");
      return [];
    } catch (e) {
      print("Error Calculate MABAC API: $e");
      return [];
    }
  }

  // ==========================================
  // 10. GET HOTELS WITH FILTER
  // ==========================================
  Future<List<dynamic>> getHotelsWithFilter({
    String? query,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? hasDiscount,
    String? type,
    String sort = 'rating_desc',
  }) async {
    try {
      final params = <String, String>{};
      if (query != null && query.isNotEmpty) params['q'] = query;
      if (minPrice != null) params['min_price'] = minPrice.toString();
      if (maxPrice != null) params['max_price'] = maxPrice.toString();
      if (minRating != null) params['min_rating'] = minRating.toString();
      if (hasDiscount == true) params['min_discount'] = '1';
      if (type != null) params['type'] = type;
      params['sort'] = sort;

      final uri = Uri.parse('$baseUrl/hotels').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'] ?? [];
        } else if (decoded is List) {
          return decoded;
        }
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get Hotels With Filter API: $e");
      return [];
    }
  }

  Future<bool> addPoi(Map<String, String> data) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/poi'), body: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error Add POI: $e");
      return false;
    }
  }

  Future<bool> updatePoi(int id, Map<String, String> data) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/poi/$id'), body: data);
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update POI: $e");
      return false;
    }
  }

  Future<bool> deletePoi(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/poi/$id'));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error Delete POI: $e");
      return false;
    }
  }

  Future<bool> updateCriteria(int id, Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/criterias/$id'),
        body: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Criteria: $e");
      return false;
    }
  }
}