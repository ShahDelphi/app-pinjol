import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
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
  bool _showPrayerTimes = false;
  PrayerTimes? _prayerTimes;
  
  final List<Map<String, dynamic>> _zones = [
    {
      'name': 'WIB', 
      'offset': 7, 
      'city': 'Jakarta', 
      'lat': -6.2088, 
      'lng': 106.8456,
      'method': CalculationMethod.singapore,
      'madhab': Madhab.shafi
    },
    {
      'name': 'WITA', 
      'offset': 8, 
      'city': 'Makassar', 
      'lat': -5.1477, 
      'lng': 119.4327,
      'method': CalculationMethod.singapore,
      'madhab': Madhab.shafi
    },
    {
      'name': 'WIT', 
      'offset': 9, 
      'city': 'Jayapura', 
      'lat': -2.5489, 
      'lng': 140.7197,
      'method': CalculationMethod.singapore,
      'madhab': Madhab.shafi
    },
    {
      'name': 'London', 
      'offset': 1, // GMT+1 (BST) - Update sesuai musim
      'city': 'London', 
      'lat': 51.5074, 
      'lng': -0.1278,
      'method': CalculationMethod.moon_sighting_committee,
      'madhab': Madhab.hanafi
    },
    {
      'name': 'Tokyo', 
      'offset': 9, 
      'city': 'Tokyo', 
      'lat': 35.6762, 
      'lng': 139.6503,
      'method': CalculationMethod.muslim_world_league,
      'madhab': Madhab.shafi
    },
    {
      'name': 'New York', 
      'offset': -4, // EDT
      'city': 'New York', 
      'lat': 40.7128, 
      'lng': -74.0060,
      'method': CalculationMethod.north_america,
      'madhab': Madhab.shafi
    },
    {
      'name': 'Dubai', 
      'offset': 4, 
      'city': 'Dubai', 
      'lat': 25.2048, 
      'lng': 55.2708,
      'method': CalculationMethod.umm_al_qura,
      'madhab': Madhab.hanafi
    },
    {
      'name': 'Makkah', 
      'offset': 3, 
      'city': 'Makkah', 
      'lat': 21.4225, 
      'lng': 39.8262,
      'method': CalculationMethod.umm_al_qura,
      'madhab': Madhab.hanafi
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _calculatePrayerTimes();
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
      // Update prayer times every minute
      if (DateTime.now().second == 0) {
        _calculatePrayerTimes();
      }
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
    _calculatePrayerTimes();
  }

  void _togglePrayerTimes() {
    setState(() {
      _showPrayerTimes = !_showPrayerTimes;
    });
  }

  void _calculatePrayerTimes() {
    final selectedZoneData = _zones.firstWhere((zone) => zone['name'] == _selectedZone);
    
    try {
      final coordinates = Coordinates(
        selectedZoneData['lat'] as double, 
        selectedZoneData['lng'] as double
      );
      
      final calculationMethod = selectedZoneData['method'] as CalculationMethod;
      final params = calculationMethod.getParameters();
      params.madhab = selectedZoneData['madhab'] as Madhab;
      
      // Use local date for the selected timezone
      final now = DateTime.now();
      final offset = selectedZoneData['offset'] as int;
      final utcOffset = Duration(hours: offset);
      
      // Create DateComponents for the selected timezone
      final localDate = now.toUtc().add(utcOffset);
      final dateComponents = DateComponents(localDate.year, localDate.month, localDate.day);
      
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);
      
      setState(() {
        _prayerTimes = prayerTimes;
      });
    } catch (e) {
      print('Error calculating prayer times: $e');
      setState(() {
        _prayerTimes = null;
      });
    }
  }

  String _formatPrayerTime(DateTime? time, int timezoneOffset) {
    if (time == null) return '--:--';
    
    // Prayer times from adhan library are already in UTC
    // Convert to local timezone
    final localTime = time.toUtc().add(Duration(hours: timezoneOffset));
    return DateFormat('HH:mm').format(localTime);
  }

  bool _isMuslimRegion(String zoneName) {
    return ['WIB', 'WITA', 'WIT', 'Dubai', 'Makkah', 'London', 'Tokyo', 'New York'].contains(zoneName);
  }

  String _getNextPrayer() {
    if (_prayerTimes == null) return '';
    
    final now = DateTime.now();
    final selectedZoneData = _zones.firstWhere((zone) => zone['name'] == _selectedZone);
    final offset = selectedZoneData['offset'] as int;
    final localNow = now.toUtc().add(Duration(hours: offset));
    
    final prayers = [
      {'name': 'Subuh', 'time': _prayerTimes!.fajr.toUtc().add(Duration(hours: offset))},
      {'name': 'Dzuhur', 'time': _prayerTimes!.dhuhr.toUtc().add(Duration(hours: offset))},
      {'name': 'Ashar', 'time': _prayerTimes!.asr.toUtc().add(Duration(hours: offset))},
      {'name': 'Maghrib', 'time': _prayerTimes!.maghrib.toUtc().add(Duration(hours: offset))},
      {'name': 'Isya', 'time': _prayerTimes!.isha.toUtc().add(Duration(hours: offset))},
    ];
    
    for (var prayer in prayers) {
      final prayerTime = prayer['time'] as DateTime;
      if (prayerTime.isAfter(localNow)) {
        final diff = prayerTime.difference(localNow);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        
        if (hours > 0) {
          return '${prayer['name']} dalam ${hours}j ${minutes}m';
        } else {
          return '${prayer['name']} dalam ${minutes}m';
        }
      }
    }
    
    // If no prayer found today, show tomorrow's Fajr
    final tomorrowFajr = _prayerTimes!.fajr.toUtc().add(Duration(hours: offset, days: 1));
    final diff = tomorrowFajr.difference(localNow);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    
    return 'Subuh besok dalam ${hours}j ${minutes}m';
  }

  Widget _buildPrayerTimesCard() {
    if (!_isMuslimRegion(_selectedZone)) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Waktu solat tidak tersedia untuk zona waktu ini',
          style: TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_prayerTimes == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text(
              'Menghitung waktu solat...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final selectedZoneData = _zones.firstWhere((zone) => zone['name'] == _selectedZone);
    final offset = selectedZoneData['offset'] as int;
    
    final prayerData = [
      {'name': 'Subuh', 'time': _prayerTimes!.sunrise, 'icon': Icons.nights_stay},
      {'name': 'Dzuhur', 'time': _prayerTimes!.dhuhr, 'icon': Icons.wb_sunny},
      {'name': 'Ashar', 'time': _prayerTimes!.asr, 'icon': Icons.wb_sunny_outlined},
      {'name': 'Maghrib', 'time': _prayerTimes!.maghrib, 'icon': Icons.wb_twilight},
      {'name': 'Isya', 'time': _prayerTimes!.isha, 'icon': Icons.nightlight},
    ];

    final nextPrayer = _getNextPrayer();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Jadwal Solat - ${selectedZoneData['city']}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (nextPrayer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                nextPrayer,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...prayerData.map((prayer) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  prayer['icon'] as IconData,
                  color: Colors.green.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prayer['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  _formatPrayerTime(prayer['time'] as DateTime?, offset),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 12),
          Text(
            'Metode: ${_getCalculationMethodName(selectedZoneData['method'])} | '
            'Madhab: ${selectedZoneData['madhab'] == Madhab.shafi ? 'Syafi\'i' : 'Hanafi'}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getCalculationMethodName(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.singapore:
        return 'Singapore';
      case CalculationMethod.muslim_world_league:
        return 'Muslim World League';
      case CalculationMethod.umm_al_qura:
        return 'Umm Al-Qura';
      case CalculationMethod.north_america:
        return 'North America';
      case CalculationMethod.moon_sighting_committee:
        return 'Moon Sighting Committee';
      default:
        return 'Default';
    }
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
                  Row(
                    children: [
                      Text(
                        zone['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.amber : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isMuslimRegion(zone['name']))
                        Icon(
                          Icons.mosque,
                          color: isSelected ? Colors.amber : Colors.white70,
                          size: 16,
                        ),
                    ],
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
        title: const Text('Praying Time'),
        backgroundColor: const Color(0xFF0B0D3A),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        actions: [
          IconButton(
            icon: Icon(
              _showPrayerTimes ? Icons.schedule : Icons.mosque,
              color: Colors.white,
            ),
            onPressed: _togglePrayerTimes,
            tooltip: _showPrayerTimes ? 'Hide Prayer Times' : 'Show Prayer Times',
          ),
        ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectedZoneData['city'],
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isMuslimRegion(_selectedZone))
                        const Icon(
                          Icons.mosque,
                          color: Colors.amber,
                          size: 18,
                        ),
                    ],
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
            
            // Prayer Times Section
            if (_showPrayerTimes) _buildPrayerTimesCard(),
            
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