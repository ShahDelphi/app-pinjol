import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api-pinjol-589948883802.us-central1.run.app/api';

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        final sessionId = cookies.split(';').firstWhere((e) => e.contains('connect.sid'));
        await prefs.setString('session', sessionId);
      }
      return jsonDecode(response.body);
    } else {
      throw Exception('Login gagal');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final session = prefs.getString('session');

    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': session ?? ''
      },
    );
    await prefs.remove('session');
  }

  static Future<Map<String, dynamic>> checkForm() async {
    final prefs = await SharedPreferences.getInstance();
    final session = prefs.getString('session');

    final response = await http.get(
      Uri.parse('$baseUrl/form'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': session ?? ''
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal cek form');
    }
  }

  static Future<Map<String, dynamic>> register(String username, String password, String confirmPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": username,
        "password": password,
        "confirm_password": confirmPassword
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Registrasi gagal');
    }
  }
}
