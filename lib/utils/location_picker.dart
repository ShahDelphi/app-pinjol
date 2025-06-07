import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class LocationPickerPage extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerPage({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  LatLng _selectedLocation = const LatLng(-7.250445, 110.831794); // Default Yogyakarta
  LatLng? _currentUserLocation; // Untuk menyimpan lokasi GPS terkini
  String _selectedAddress = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingAddress = false;
  bool _isGettingLocation = false; // Loading state untuk GPS
  final Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _selectedAddress = widget.initialAddress ?? '';
    }
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied && 
          permission != LocationPermission.deniedForever) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          
          final currentLocation = LatLng(position.latitude, position.longitude);
          
          setState(() {
            _currentUserLocation = currentLocation;
            _selectedLocation = currentLocation;
          });
          
          // Animasi kamera ke lokasi saat ini
          await _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(currentLocation, 16),
          );
          
          _updateMarker(currentLocation);
          _getAddressFromCoordinates(currentLocation);
        } else {
          // Jika layanan lokasi tidak aktif
          _showLocationServiceDialog();
        }
      } else {
        // Jika permission ditolak
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _showLocationErrorDialog();
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2156),
          title: const Text(
            'Layanan Lokasi Tidak Aktif',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Silakan aktifkan layanan lokasi untuk menggunakan fitur GPS.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2156),
          title: const Text(
            'Izin Lokasi Diperlukan',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Aplikasi memerlukan izin akses lokasi untuk menggunakan fitur GPS.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Pengaturan', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2156),
          title: const Text(
            'Error Lokasi',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Terjadi kesalahan saat mengambil lokasi. Silakan coba lagi.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    if (_apiKey.isEmpty) return;
    
    setState(() => _isLoadingAddress = true);
    
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=${location.latitude},${location.longitude}&'
          'key=$_apiKey&language=id';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          setState(() {
            _selectedAddress = data['results'][0]['formatted_address'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || _apiKey.isEmpty) return;
    
    setState(() => _isSearching = true);
    
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?'
          'query=$query&'
          'key=$_apiKey&'
          'language=id';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(data['results']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Lokasi Dipilih'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _searchResults.clear();
    });
    _updateMarker(location);
    _getAddressFromCoordinates(location);
  }

  void _onSearchResultTap(Map<String, dynamic> place) {
    final location = LatLng(
      place['geometry']['location']['lat'],
      place['geometry']['location']['lng'],
    );
    
    setState(() {
      _selectedLocation = location;
      _selectedAddress = place['formatted_address'];
      _searchResults.clear();
      _searchController.clear();
    });
    
    _updateMarker(location);
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(location, 16),
    );
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'location': _selectedLocation,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D3A),
      appBar: AppBar(
        title: const Text(
          'Pilih Lokasi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E2156),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                tooltip: 'Lokasi Saya',
              ),
              if (_isGettingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E2156),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari lokasi...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0B0D3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _searchPlaces,
            ),
          ),
          
          // Search Results
          if (_searchResults.isNotEmpty)
            Container(
              height: 200,
              color: const Color(0xFF1E2156),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(
                      place['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      place['formatted_address'],
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _onSearchResultTap(place),
                  );
                },
              ),
            ),
          
          // Map
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _selectedLocation,
                zoom: 15,
              ),
              markers: _markers,
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),
          
          // Address Info and Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E2156),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Alamat Terpilih:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_currentUserLocation != null)
                      Text(
                        'GPS: ${_currentUserLocation!.latitude.toStringAsFixed(6)}, ${_currentUserLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0D3A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingAddress
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Memuat alamat...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        )
                      : Text(
                          _selectedAddress.isEmpty 
                              ? 'Tap pada peta untuk memilih lokasi' 
                              : _selectedAddress,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedAddress.isNotEmpty ? _confirmLocation : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Konfirmasi Lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}