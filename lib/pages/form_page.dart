import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'home_page.dart';
import 'login_page.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final namaController = TextEditingController();
  final nikController = TextEditingController();
  final phoneController = TextEditingController();
  final alamatController = TextEditingController();
  final tanggalController = TextEditingController();

  String gender = 'Laki-laki';
  String agama = 'Islam';
  String pekerjaan = 'Pelajar';
  bool isLoading = false;
  File? selectedImage;
  
  // Key untuk memaksa rebuild CircleAvatar
  Key _avatarKey = UniqueKey();

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Kualitas tinggi
      );
      
      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 90, // Tingkatkan kualitas compress
          aspectRatioPresets: [CropAspectRatioPreset.square],
          cropStyle: CropStyle.circle,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Foto',
              toolbarColor: Colors.amber,
              toolbarWidgetColor: Colors.white,
              hideBottomControls: false, // Tampilkan kontrol untuk lebih fleksibel
              lockAspectRatio: true,
              statusBarColor: Colors.amber,
              initAspectRatio: CropAspectRatioPreset.square,
            ),
            IOSUiSettings(
              title: 'Crop Foto',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            selectedImage = File(croppedFile.path);
            // Generate key baru untuk memaksa rebuild avatar
            _avatarKey = UniqueKey();
          });
          
          // Debug print untuk memastikan file ada
          debugPrint("Cropped image path: ${croppedFile.path}");
          debugPrint("Cropped image exists: ${await File(croppedFile.path).exists()}");
        }
      }
    } catch (e) {
      debugPrint("Error selecting image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto profil wajib dipilih.")),
      );
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = prefs.getString('session');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api-pinjol-589948883802.us-central1.run.app/api/form'),
      );

      request.headers['Cookie'] = session ?? '';
      request.files.add(await http.MultipartFile.fromPath('fotoProfil', selectedImage!.path));
      request.fields.addAll({
        "namaLengkap": namaController.text,
        "nik": nikController.text,
        "phoneNumber": phoneController.text,
        "alamat": alamatController.text,
        "tanggalLahir": tanggalController.text,
        "gender": gender,
        "agama": agama,
        "jobs": pekerjaan,
      });

      final response = await request.send();

      if (response.statusCode == 201) {
        if (!context.mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal submit form.")),
        );
      }
    } catch (e) {
      debugPrint("Error submitting form: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
    
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = prefs.getString('session');
      final response = await http.post(
        Uri.parse('https://api-pinjol-589948883802.us-central1.run.app/api/logout'),
        headers: {'Cookie': session ?? ''},
      );

      await prefs.remove('session');

      if (!context.mounted) return;
      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal logout")),
        );
      }
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }

  InputDecoration buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.amber),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white30),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.amber),
        borderRadius: BorderRadius.circular(10),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // Widget untuk menampilkan avatar dengan handling yang lebih baik
  Widget _buildAvatar() {
    return Container(
      key: _avatarKey, // Key untuk memaksa rebuild
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.amber.withOpacity(0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.amber,
        backgroundImage: selectedImage != null ? FileImage(selectedImage!) : null,
        child: selectedImage == null
            ? const Icon(
                Icons.add_a_photo, 
                color: Color(0xFF0B0D3A),
                size: 30,
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    namaController.dispose();
    nikController.dispose();
    phoneController.dispose();
    alamatController.dispose();
    tanggalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D3A),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Isi Data Diri", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.amber[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Avatar dengan gesture detector
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: _buildAvatar(),
                ),
              ),
              const SizedBox(height: 8),
              // Text hint untuk user
              const Center(
                child: Text(
                  'Tap untuk memilih foto profil',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: namaController,
                decoration: buildInputDecoration("Nama Lengkap", Icons.person),
                style: const TextStyle(color: Colors.white),
                validator: (value) => (value == null || value.isEmpty) ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nikController,
                decoration: buildInputDecoration("NIK", Icons.credit_card),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Wajib diisi";
                  if (value.length != 16) return "NIK harus 16 digit";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: buildInputDecoration("Nomor Telepon", Icons.phone),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Wajib diisi";
                  if (value.length < 10) return "Nomor telepon tidak valid";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tanggalController,
                readOnly: true,
                decoration: buildInputDecoration("Tanggal Lahir", Icons.date_range),
                style: const TextStyle(color: Colors.white),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.amber,
                            onPrimary: Color(0xFF0B0D3A),
                            surface: Color(0xFF1E2156),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    tanggalController.text = picked.toIso8601String().split("T").first;
                  }
                },
                validator: (value) => (value == null || value.isEmpty) ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: alamatController,
                decoration: buildInputDecoration("Alamat", Icons.home),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: gender,
                dropdownColor: Colors.grey[900],
                iconEnabledColor: Colors.amber,
                decoration: buildInputDecoration("Jenis Kelamin", Icons.wc),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                ],
                onChanged: (val) => setState(() => gender = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: agama,
                dropdownColor: Colors.grey[900],
                iconEnabledColor: Colors.amber,
                decoration: buildInputDecoration("Agama", Icons.account_balance),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Islam', child: Text('Islam')),
                  DropdownMenuItem(value: 'Kristen', child: Text('Kristen')),
                  DropdownMenuItem(value: 'Katolik', child: Text('Katolik')),
                  DropdownMenuItem(value: 'Hindu', child: Text('Hindu')),
                  DropdownMenuItem(value: 'Budha', child: Text('Budha')),
                  DropdownMenuItem(value: 'Konghucu', child: Text('Konghucu')),
                ],
                onChanged: (val) => setState(() => agama = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: pekerjaan,
                dropdownColor: Colors.grey[900],
                iconEnabledColor: Colors.amber,
                decoration: buildInputDecoration("Pekerjaan", Icons.work),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Pelajar', child: Text('Pelajar')),
                  DropdownMenuItem(value: 'Mahasiswa', child: Text('Mahasiswa')),
                  DropdownMenuItem(value: 'PNS', child: Text('PNS')),
                  DropdownMenuItem(value: 'Wiraswasta', child: Text('Wiraswasta')),
                  DropdownMenuItem(value: 'Karyawan', child: Text('Karyawan')),
                  DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                ],
                onChanged: (val) => setState(() => pekerjaan = val!),
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.amber),
                          SizedBox(height: 10),
                          Text(
                            'Mengirim data...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: const Color(0xFF0B0D3A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        onPressed: submitForm,
                        child: const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}