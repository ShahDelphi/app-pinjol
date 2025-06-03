import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class TimePage extends StatefulWidget {
  const TimePage({super.key});

  @override
  State<TimePage> createState() => _TimePageState();
}

class _TimePageState extends State<TimePage> {
  Timer? _timer;
  String _currentTime = '';
  String _selectedZone = 'WIB';
  
  final List<Map<String, dynamic>> _zones = [
    {'name': 'WIB', 'offset': 7, 'city': 'Jakarta'},
    {'name': 'WITA', 'offset': 8, 'city': 'Makassar'},
    {'name': 'WIT', 'offset': 9, 'city': 'Jayapura'},
    {'name': 'London', 'offset': 0, 'city': 'London'}, // GMT
    {'name': 'Tokyo', 'offset': 9, 'city': 'Tokyo'},
    {'name': 'New York', 'offset': -5, 'city': 'New York'}, // EST
    {'name': 'Dubai', 'offset': 4, 'city': 'Dubai'},
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now().toUtc();
    final selectedZoneData = _zones.firstWhere((zone) => zone['name'] == _selectedZone);
    final offset = selectedZoneData['offset'] as int;
    
    final localTime = now.add(Duration(hours: offset));
    final formattedTime = DateFormat('HH:mm:ss').format(localTime);
    
    setState(() {
      _currentTime = formattedTime;
    });
  }

  void _changeZone(String newZone) {
    setState(() {
      _selectedZone = newZone;
    });
    _updateTime();
  }

  Widget _buildTimeZoneCard(Map<String, dynamic> zone) {
    final now = DateTime.now().toUtc();
    final offset = zone['offset'] as int;
    final localTime = now.add(Duration(hours: offset));
    final formattedTime = DateFormat('HH:mm').format(localTime);
    final isSelected = _selectedZone == zone['name'];
    
    return GestureDetector(
      onTap: () => _changeZone(zone['name']),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withOpacity(0.3) : Colors.white12,
          border: isSelected ? Border.all(color: Colors.amber, width: 2) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.amber : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    zone['city'],
                    style: TextStyle(
                      color: isSelected ? Colors.amber.shade200 : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formattedTime,
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final selectedZoneData = _zones.firstWhere((zone) => zone['name'] == _selectedZone);
    final offset = selectedZoneData['offset'] as int;
    final localTime = now.add(Duration(hours: offset));
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(localTime);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live World Clock'),
        backgroundColor: const Color(0xFF0B0D3A),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      backgroundColor: const Color(0xFF0B0D3A),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main Clock Display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.withOpacity(0.2), Colors.amber.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    selectedZoneData['city'],
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_selectedZone',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Zone Selection Header
            const Row(
              children: [
                Icon(Icons.public, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Pilih Zona Waktu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Time Zone List
            Expanded(
              child: ListView.builder(
                itemCount: _zones.length,
                itemBuilder: (context, index) {
                  return _buildTimeZoneCard(_zones[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}