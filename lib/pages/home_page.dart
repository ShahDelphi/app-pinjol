import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_page.dart';
import './menu/debt_page.dart';
import './menu/exchange_page.dart';
import './menu/time_page.dart';
import './menu/location_page.dart';
import './menu/profil_page.dart';
import './menu/feedback_page.dart';
import '../widgets/history_list.dart';
import '../utils/history_manager.dart';
import '../../../models/form_model.dart'; // Import form model

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  final PageController _pageController = PageController(initialPage: 1);

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final session = prefs.getString('session');

    if (session != null) {
      try {
        await http.post(
          Uri.parse('https://api-pinjol-589948883802.us-central1.run.app/api/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': session,
          },
        );
        await prefs.remove('session');
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          FeedbackPage(),
          HomeContentPage(),
          ProfilPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0B0D3A),
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notification_important_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  List<Map<String, String>> historyItems = [];
  bool isLoading = true;
  String namaLengkap = "Username"; // Default value
  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
    _fetchUserProfile(); // Fetch user profile data
  }

  // Fetch user profile data from API
  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final session = prefs.getString('session');

    try {
      final res = await http.get(
        Uri.parse('https://api-pinjol-589948883802.us-central1.run.app/api/form'),
        headers: {'Cookie': session ?? ''},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        final form = FormModel.fromJson(jsonRes['data']);
        setState(() {
          namaLengkap = form.namaLengkap.isNotEmpty ? form.namaLengkap : "Username";
          isLoadingProfile = false;
        });
      } else {
        setState(() {
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
      setState(() {
        isLoadingProfile = false;
      });
    }
  }

  // Load history data saat widget pertama kali dibuat
  Future<void> _loadHistoryData() async {
    try {
      final loadedHistory = await HistoryManager.loadHistory();
      setState(() {
        historyItems = loadedHistory;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Menambahkan item baru ke history
  Future<void> addHistoryItem(Map<String, String> item) async {
    try {
      await HistoryManager.addHistoryItem(item);
      // Reload history untuk memastikan data terbaru
      await _loadHistoryData();
    } catch (e) {
      print('Error adding history item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan ke history'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Menghapus semua history
  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus History'),
          content: const Text('Apakah Anda yakin ingin menghapus semua history?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await HistoryManager.clearHistory();
        await _loadHistoryData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error clearing history: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus history'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D3A),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0B0D3A),
        elevation: 0,
        title: const Text(
          'Debt Plecit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _loadHistoryData();
              _fetchUserProfile(); // Refresh profile data juga
            }, 
            icon: const Icon(Icons.sync, color: Colors.white),
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            onSelected: (value) {
              if (value == 'logout') {
                final state = context.findAncestorStateOfType<_HomePageState>();
                if (state != null) {
                  state.logout(context);
                }
              } else if (value == 'clear_history') {
                _clearHistory();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'clear_history',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear History', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menampilkan selamat datang dengan nama lengkap
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Selamat Datang,",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isLoadingProfile)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          namaLengkap,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconCard(
                  icon: Icons.arrow_upward,
                  label: 'Debt',
                  onTap: () async {
                    final result = await Navigator.push<Map<String, String>>(
                      context,
                      MaterialPageRoute(builder: (_) => const DebtPage()),
                    );
                    if (result != null) {
                      await addHistoryItem(result);
                    }
                  },
                ),
                IconCard(
                  icon: Icons.request_quote, 
                  label: 'Exchange', 
                  onTap: () async {
                    final result = await Navigator.push<Map<String, String>>(
                      context,
                      MaterialPageRoute(builder: (_) => const ExchangePage()),
                    );
                    if (result != null) {
                      await addHistoryItem(result);
                    }
                  },
                ),
                IconCard(icon: Icons.access_time, label: 'Time', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TimePage()));
                }),
                IconCard(icon: Icons.send, label: 'Location', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationPage()));
                }),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("History", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text("${historyItems.length} items", style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading 
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  )
                : HistoryList(historyItems: historyItems),
            ),
          ],
        ),
      ),
    );
  }
}

class IconCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const IconCard({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2156),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white))
        ],
      ),
    );
  }
}