import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Pastikan menambahkan lucide_icons di pubspec.yaml

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Feedback',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0B0D3A),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF0B0D3A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionCard(
              icon: LucideIcons.smile,
              title: 'Kesan',
              content:
                  'Kuliah Teknologi Pemrograman Mobile sangat bermanfaat dan menantang. '
                  'Materi yang diajarkan lengkap dan relevan dengan perkembangan teknologi saat ini, '
                  'terutama dalam pembuatan aplikasi mobile. Dosen juga sangat komunikatif dan membantu '
                  'dalam menjelaskan konsep-konsep yang sulit sehingga saya lebih mudah memahami. '
                  'Tugas yang diberikan juga tidak terlalu sulit pagi mahasiswa masa kini.',
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              icon: LucideIcons.messageCircle,
              title: 'Saran',
              content:
                  'Agar kuliah ini semakin optimal, sebaiknya materi diberikan lebih banyak yang menunjang karir industri IT.'
                  'Selain itu, bisa ditambahkan sesi Proyek Eksternal yang bersetifikasi'
                  'dan mengaplikasikan teknologi mobile secara lebih nyata.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      color: const Color(0xFF1C1F4A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
