import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryManager {
  static const String _historyKeyPrefix = 'app_history_';

  // Generate unique key untuk setiap user
  static String _getHistoryKey(String username) {
    return '$_historyKeyPrefix$username';
  }

  // Menyimpan history ke SharedPreferences berdasarkan username
  static Future<void> saveHistory(List<Map<String, String>> historyItems, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert list of maps to JSON string
      final String jsonString = jsonEncode(historyItems);
      
      await prefs.setString(_getHistoryKey(username), jsonString);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  // Mengambil history dari SharedPreferences berdasarkan username
  static Future<List<Map<String, String>>> loadHistory(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? jsonString = prefs.getString(_getHistoryKey(username));
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      // Convert JSON string back to list of maps
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((item) => Map<String, String>.from(item)).toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  // Menambahkan item baru ke history berdasarkan username
  static Future<void> addHistoryItem(Map<String, String> newItem, String username) async {
    try {
      final List<Map<String, String>> currentHistory = await loadHistory(username);
      
      // Tambahkan item baru di posisi pertama (terbaru di atas)
      currentHistory.insert(0, newItem);
      
      // Batasi history maksimal 50 item untuk menghemat storage
      if (currentHistory.length > 50) {
        currentHistory.removeRange(50, currentHistory.length);
      }
      
      await saveHistory(currentHistory, username);
    } catch (e) {
      print('Error adding history item: $e');
    }
  }

  // Menghapus semua history berdasarkan username
  static Future<void> clearHistory(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getHistoryKey(username));
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  // Menghapus item history berdasarkan index dan username
  static Future<void> removeHistoryItem(int index, String username) async {
    try {
      final List<Map<String, String>> currentHistory = await loadHistory(username);
      
      if (index >= 0 && index < currentHistory.length) {
        currentHistory.removeAt(index);
        await saveHistory(currentHistory, username);
      }
    } catch (e) {
      print('Error removing history item: $e');
    }
  }

  // Method untuk mendapatkan username dari SharedPreferences
  static Future<String> getCurrentUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('username') ?? 'default_user';
    } catch (e) {
      print('Error getting current username: $e');
      return 'default_user';
    }
  }
}