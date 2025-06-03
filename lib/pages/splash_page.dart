import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'form_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final session = prefs.getString('session');

    if (session != null) {
      final response = await http.get(
        Uri.parse('https://api-pinjol-589948883802.us-central1.run.app/api/form'),
        headers: { 'Cookie': session },
      );

      final isSubmitted = response.body.contains('submitted":true');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isSubmitted ? const HomePage() : const FormPage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}