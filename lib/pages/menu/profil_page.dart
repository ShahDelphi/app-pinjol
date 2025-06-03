import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../models/form_model.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  late FormModel _formData;
  final Map<String, TextEditingController> _controllers = {};
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  // Key untuk memaksa rebuild CircleAvatar
  Key _avatarKey = UniqueKey();

  final Map<String, String> _fieldLabels = {
    'namaLengkap': 'Nama Lengkap',
    'nik': 'NIK',
    'phoneNumber': 'Nomor Telepon',
    'tanggalLahir': 'Tanggal Lahir',
    'alamat': 'Alamat',
    'gender': 'Jenis Kelamin',
    'agama': 'Agama',
    'jobs': 'Pekerjaan',
  };

  @override
  void initState() {
    super.initState();
    _fetchForm();
  }

  Future<void> _fetchForm() async {
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
          _formData = form;
          _isLoading = false;
        });

        _controllers['namaLengkap'] = TextEditingController(text: form.namaLengkap);
        _controllers['nik'] = TextEditingController(text: form.nik);
        _controllers['phoneNumber'] = TextEditingController(text: form.phoneNumber);
        _controllers['tanggalLahir'] = TextEditingController(text: form.tanggalLahir.split('T').first);
        _controllers['alamat'] = TextEditingController(text: form.alamat);
        _controllers['gender'] = TextEditingController(text: form.gender);
        _controllers['agama'] = TextEditingController(text: form.agama);
        _controllers['jobs'] = TextEditingController(text: form.jobs);
      }
    } catch (e) {
      debugPrint("Error fetching form: $e");
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Pastikan kualitas tinggi
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
              toolbarColor: Colors.deepPurple,
              toolbarWidgetColor: Colors.white,
              hideBottomControls: false, // Tampilkan kontrol untuk lebih fleksibel
              lockAspectRatio: true,
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
      // Tampilkan error ke user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _updateForm() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final session = prefs.getString('session');

    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('https://api-pinjol-589948883802.us-central1.run.app/api/form'),
    );

    request.headers['Cookie'] = session ?? '';

    request.fields.addAll({
      'namaLengkap': _controllers['namaLengkap']!.text,
      'nik': _controllers['nik']!.text,
      'phoneNumber': _controllers['phoneNumber']!.text,
      'tanggalLahir': _controllers['tanggalLahir']!.text,
      'alamat': _controllers['alamat']!.text,
      'gender': _controllers['gender']!.text,
      'agama': _controllers['agama']!.text,
      'jobs': _controllers['jobs']!.text,
    });

    if (selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath('fotoProfil', selectedImage!.path));
    }

    try {
      final res = await request.send();

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diperbarui')),
        );
        // Reset selected image setelah berhasil upload
        setState(() {
          selectedImage = null;
          _avatarKey = UniqueKey();
        });
        // Refresh data form
        _fetchForm();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui data')),
        );
      }
    } catch (e) {
      debugPrint("Error updating form: $e");
    }
  }

  Widget buildTextField(String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: _fieldLabels[key],
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: const Color(0xFF1E2156),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Tidak boleh kosong' : null,
      ),
    );
  }

  Widget buildDatePickerField(String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        readOnly: true,
        style: const TextStyle(color: Colors.white),
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(_controllers[key]!.text) ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            _controllers[key]!.text = pickedDate.toIso8601String().split('T').first;
          }
        },
        decoration: InputDecoration(
          labelText: _fieldLabels[key],
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: const Color(0xFF1E2156),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.white),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Tidak boleh kosong' : null,
      ),
    );
  }

  Widget buildDropdownField(String key, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: options.contains(_controllers[key]!.text) ? _controllers[key]!.text : null,
        onChanged: (value) {
          setState(() {
            _controllers[key]!.text = value!;
          });
        },
        dropdownColor: const Color(0xFF1E2156),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: _fieldLabels[key],
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: const Color(0xFF1E2156),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: options
            .map((value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ))
            .toList(),
        validator: (value) => (value == null || value.isEmpty) ? 'Tidak boleh kosong' : null,
      ),
    );
  }

  // Widget untuk menampilkan avatar dengan prioritas yang jelas
  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    Widget? child;

    if (selectedImage != null) {
      // Prioritas 1: Gambar yang baru dipilih/dicrop
      imageProvider = FileImage(selectedImage!);
    } else if (_formData.fotoProfil.isNotEmpty) {
      // Prioritas 2: Gambar dari server
      imageProvider = NetworkImage(_formData.fotoProfil);
    } else {
      // Prioritas 3: Placeholder icon
      child = const Icon(
        Icons.add_a_photo, 
        color: Colors.white, 
        size: 30
      );
    }

    return Container(
      key: _avatarKey, // Key untuk memaksa rebuild
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: const Color(0xFF1E2156),
        backgroundImage: imageProvider,
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profil Page',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B0D3A),
      ),
      backgroundColor: const Color(0xFF0B0D3A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.all(16),
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
                        'Tap untuk mengubah foto',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildTextField('namaLengkap'),
                    buildTextField('nik'),
                    buildTextField('phoneNumber'),
                    buildDatePickerField('tanggalLahir'),
                    buildTextField('alamat'),
                    buildDropdownField('gender', ['Laki-laki', 'Perempuan']),
                    buildDropdownField('agama', ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Budha', 'Konghucu']),
                    buildDropdownField('jobs', ['Pelajar', 'Mahasiswa', 'PNS', 'Wiraswasta', 'Karyawan', 'Lainnya']),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}