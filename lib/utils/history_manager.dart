import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryManager {
  static const String _historyKey = 'app_history';

  // Menyimpan history ke SharedPreferences
  static Future<void> saveHistory(List<Map<String, String>> historyItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert list of maps to JSON string
      final String jsonString = jsonEncode(historyItems);
      
      await prefs.setString(_historyKey, jsonString);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  // Mengambil history dari SharedPreferences
  static Future<List<Map<String, String>>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? jsonString = prefs.getString(_historyKey);
      
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

  // Menambahkan item baru ke history
  static Future<void> addHistoryItem(Map<String, String> newItem) async {
    try {
      final List<Map<String, String>> currentHistory = await loadHistory();
      
      // Tambahkan item baru di posisi pertama (terbaru di atas)
      currentHistory.insert(0, newItem);
      
      // Batasi history maksimal 50 item untuk menghemat storage
      if (currentHistory.length > 50) {
        currentHistory.removeRange(50, currentHistory.length);
      }
      
      await saveHistory(currentHistory);
    } catch (e) {
      print('Error adding history item: $e');
    }
  }

  // Menghapus semua history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  // Menghapus item history berdasarkan index
  static Future<void> removeHistoryItem(int index) async {
    try {
      final List<Map<String, String>> currentHistory = await loadHistory();
      
      if (index >= 0 && index < currentHistory.length) {
        currentHistory.removeAt(index);
        await saveHistory(currentHistory);
      }
    } catch (e) {
      print('Error removing history item: $e');
    }
  }
}