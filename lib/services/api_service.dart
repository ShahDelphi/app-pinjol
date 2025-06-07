import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api-pinjol-589948883802.us-central1.run.app/api';
  
  // Headers untuk JSON
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };

  /// Register user baru
  static Future<ApiResponse> register({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: jsonHeaders,
        body: jsonEncode({
          'username': username,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      if (response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: 'Registrasi berhasil. Silakan login.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Gagal register: ${response.body}',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  /// Login user
  static Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: jsonHeaders,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final rawCookie = response.headers['set-cookie'];
        if (rawCookie != null && rawCookie.contains('connect.sid')) {
          final sessionId = rawCookie.split(';')[0];
          
          // Simpan session dan username
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session', sessionId);
          await prefs.setString('username', username);

          return LoginResponse(
            success: true,
            sessionId: sessionId,
            message: 'Login berhasil',
          );
        } else {
          return LoginResponse(
            success: false,
            message: 'Session tidak ditemukan',
          );
        }
      } else {
        return LoginResponse(
          success: false,
          message: 'Login gagal. Cek username/password.',
        );
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  /// Cek status form submission
  static Future<FormStatusResponse> checkFormStatus(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/form'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': sessionId,
        },
      );

      final isSubmitted = response.body.contains('"submitted":true');
      
      return FormStatusResponse(
        success: true,
        isSubmitted: isSubmitted,
      );
    } catch (e) {
      return FormStatusResponse(
        success: false,
        isSubmitted: false,
        message: 'Gagal mengecek status form: $e',
      );
    }
  }

  /// Get stored session dari SharedPreferences
  static Future<String?> getStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session');
  }

  /// Get stored username dari SharedPreferences
  static Future<String?> getStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  /// Clear stored session dan username
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session');
    await prefs.remove('username');
  }
}

/// Response class untuk API calls
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

/// Response class khusus untuk login
class LoginResponse extends ApiResponse {
  final String? sessionId;

  LoginResponse({
    required bool success,
    required String message,
    this.sessionId,
    dynamic data,
  }) : super(success: success, message: message, data: data);
}

/// Response class untuk status form
class FormStatusResponse extends ApiResponse {
  final bool isSubmitted;

  FormStatusResponse({
    required bool success,
    required this.isSubmitted,
    String? message,
    dynamic data,
  }) : super(success: success, message: message ?? '', data: data);
}