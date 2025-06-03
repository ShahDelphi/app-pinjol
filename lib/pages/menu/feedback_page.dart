import 'package:flutter/material.dart';

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
      ),
      backgroundColor: const Color(0xFF0B0D3A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kesan',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kuliah Teknologi Pemrograman Mobile sangat bermanfaat dan menantang. Materi yang diajarkan lengkap dan relevan dengan perkembangan teknologi saat ini, terutama dalam pembuatan aplikasi mobile. Dosen juga sangat komunikatif dan membantu dalam menjelaskan konsep-konsep yang sulit sehingga saya lebih mudah memahami. Praktikum yang dilakukan pun sangat membantu untuk memperkuat teori yang dipelajari.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Saran',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agar kuliah ini semakin optimal, sebaiknya materi praktikum diberikan lebih banyak contoh aplikasi nyata dari berbagai platform mobile. Selain itu, mungkin bisa ditambahkan sesi workshop atau proyek kolaboratif agar mahasiswa dapat belajar bekerja dalam tim dan mengaplikasikan teknologi mobile secara lebih nyata. Penambahan materi tentang teknologi terbaru seperti Flutter atau React Native juga akan sangat membantu sebagai persiapan dunia kerja.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
