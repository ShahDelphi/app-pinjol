import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _predictions = [];
  static const String apiKey = 'Your_API_Key';

  LatLng _currentLatLng = const LatLng(-6.200000, 106.816666); // Default Jakarta
  StreamSubscription<Position>? _positionStream;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _startTracking();
  }

  Future<void> _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek service GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Cek permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, cannot request permissions.');
    }

    // Dapatkan lokasi sekarang
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _updateLocation(position);

    // Subscribe stream lokasi update
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateLocation(position);
    });
  }

  void _updateLocation(Position position) {
    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
    });
    mapController.animateCamera(CameraUpdate.newLatLng(_currentLatLng));
  }

  Future<void> _searchPlace(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions.clear();
      });
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=country:id';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final predictions = data['predictions'] as List;
      setState(() {
        _predictions.clear();
        _predictions.addAll(predictions.map((p) => {
              'description': p['description'],
              'place_id': p['place_id'],
            }));
      });
    }
  }

  Future<void> _selectPlace(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);

      setState(() {
        _currentLatLng = latLng;
        _predictions.clear();
        _searchController.text = data['result']['name'];
      });

      mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng current = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLatLng = current;
        _searchController.clear();
        _predictions.clear();
      });
      mapController.animateCamera(CameraUpdate.newLatLngZoom(current, 16));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi saat ini: $e')),
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D3A),
      appBar: AppBar(
        title: const Text('Location'),
        backgroundColor: const Color(0xFF0B0D3A),
        iconTheme: const IconThemeData(color: Colors.white), // untuk tombol/icon (misal tombol back)
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20), // untuk judul
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari lokasi...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
              ),
              onChanged: _searchPlace,
            ),
          ),
          if (_predictions.isNotEmpty)
            Container(
              color: Colors.white,
              height: 150,
              child: ListView.builder(
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final p = _predictions[index];
                  return ListTile(
                    title: Text(p['description']),
                    onTap: () => _selectPlace(p['place_id']),
                  );
                },
              ),
            ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentLatLng,
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId("selected"),
                  position: _currentLatLng,
                ),
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _goToCurrentLocation,
          backgroundColor: const Color(0xFF0B0D3A),
          child: const Icon(Icons.my_location),
          tooltip: 'Kembali ke lokasi saya',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      );
  }
}
