class ApiConstants {
  // Ganti sesuai environment
  static const String _mode = 'local'; // 'local' | 'deployed'

  // Pilih target local server sesuai device/platform:
  // - Gunakan 'http://localhost:8080/api' jika test di browser/web-server (di laptop yang sama)
  // - Gunakan 'http://10.0.2.2:8080/api' jika menggunakan Emulator Android bawaan
  // - Gunakan IP Wi-Fi kamu (misal 'http://192.168.1.8:8080/api') jika test menggunakan HP Fisik
  static const String _local    = 'http://localhost:8080/api'; 
  static const String _deployed = 'https://yourapp.railway.app/api'; 

  static const String baseUrl = _mode == 'deployed' ? _deployed : _local;

  static const String login               = '$baseUrl/login';
  static const String register            = '$baseUrl/register';
  static const String hotels              = '$baseUrl/hotels';
  static const String criterias           = '$baseUrl/criterias';
  static const String poi                 = '$baseUrl/poi';
  static const String evaluationCalculate = '$baseUrl/evaluation/calculate';
}
