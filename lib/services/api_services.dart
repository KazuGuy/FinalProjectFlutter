import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // IP Jaringan Wi-Fi Laptop untuk sinkronisasi ke HP Fisik
  final String baseUrl = "http://10.28.77.236:8080/api";

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
          'role': 'user', // Default pendaftaran dari aplikasi mobile
        },
      );

      return json.decode(response.body);
    } catch (e) {
      print("Error Register API: $e");
      return null;
    }
  }

  // ==========================================
  // 3. CRUD HOTEL: GET ALL HOTELS (DENGAN PROTEKSI DATA)
  // ==========================================
  Future<List<dynamic>> getHotels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/hotels'));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        
        // Toleransi Fleksibel: Jika backend membungkus data di dalam objek json ['data'], ambil ['data'].
        // Jika backend langsung mengembalikan array list utuh, langsung return data tersebut.
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
      return []; // Return array kosong agar FutureBuilder di UI tidak crash
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
}