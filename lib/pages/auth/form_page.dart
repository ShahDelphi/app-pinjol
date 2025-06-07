import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../utils/location_picker.dart';

import '../home_page.dart';
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
  bool isLoadingLocation = false;
  File? selectedImage;
  
  // Key untuk memaksa rebuild CircleAvatar
  Key _avatarKey = UniqueKey();
  
  // Google Maps API Key
  final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  final ImagePicker _picker = ImagePicker();

  // Menampilkan dialog pilihan sumber gambar
  Future<void> showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2156),
          title: const Text(
            'Pilih Sumber Foto',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.amber),
                title: const Text(
                  'Kamera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.amber),
                title: const Text(
                  'Galeri',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
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

  // Fungsi untuk mendapatkan lokasi saat ini dan convert ke alamat
  Future<void> _showAddressInputDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2156),
          title: const Text(
            'Pilih Metode Input Alamat',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.amber),
                title: const Text(
                  'Gunakan Lokasi Saat Ini',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Deteksi otomatis alamat dari GPS',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  getCurrentLocationAddress();
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.amber),
                title: const Text(
                  'Pilih di Peta',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Buka peta untuk memilih lokasi',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openLocationPicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.amber),
                title: const Text(
                  'Input Manual',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Ketik alamat secara manual',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Focus ke text field alamat
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method yang hilang - getCurrentLocationAddress
  Future<void> getCurrentLocationAddress() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS/Location services.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable in settings.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Convert coordinates to address
      await getAddressFromCoordinates(position.latitude, position.longitude);

    } catch (e) {
      debugPrint("Error getting current location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error mendapatkan lokasi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }
    }
  }

  // Tambahkan fungsi untuk membuka location picker
  Future<void> _openLocationPicker() async {
    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => const LocationPickerPage(),
        ),
      );

      if (result != null && result['address'] != null) {
        setState(() {
          alamatController.text = result['address'];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi berhasil dipilih dari peta'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error opening location picker: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuka peta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi untuk convert koordinat ke alamat
  Future<void> getAddressFromCoordinates(double lat, double lng) async {
    if (apiKey.isEmpty) {
      throw Exception('Google Maps API Key not found');
    }

    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey&language=id';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          String address = data['results'][0]['formatted_address'];
          
          setState(() {
            alamatController.text = address;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Alamat berhasil diisi otomatis'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('No address found for this location');
        }
      } else {
        throw Exception('Failed to get address from coordinates');
      }
    } catch (e) {
      throw Exception('Error converting coordinates to address: $e');
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
                  onTap: showImageSourceDialog,
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
              // Field alamat dengan tombol lokasi
              TextFormField(
                controller: alamatController,
                decoration: buildInputDecoration("Alamat", Icons.home).copyWith(
                  suffixIcon: isLoadingLocation 
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.amber,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.location_on, color: Colors.amber),
                        onPressed: _showAddressInputDialog, // Ganti dengan dialog
                        tooltip: 'Pilih metode input alamat',
                      ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 8),
              // Text hint untuk alamat
              const Text(
                'Tap ikon lokasi untuk memilih metode input alamat',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
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