import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  final TextEditingController _amountController = TextEditingController();
  
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _convertedAmount = 0.0;
  bool _isLoading = false;
  Map<String, double> _exchangeRates = {};
  DateTime? _lastUpdated;

  // Daftar mata uang yang didukung
  final List<String> _supportedCurrencies = [
    'IDR', 'USD', 'EUR', 'JPY', 'GBP', 'AUD', 'CAD', 'CHF', 'CNY', 'SGD'
  ];

  // API endpoints - tidak perlu API key untuk opsi gratis
  
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchExchangeRates();
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'exchange_channel',
          channelName: 'Currency Exchange',
          channelDescription: 'Notification channel for currency exchange',
          defaultColor: Colors.amber,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          criticalAlerts: true,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'Basic group',
        )
      ],
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // Mengambil kurs mata uang realtime dari API
  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Opsi 1: Menggunakan exchangerate-api.com (gratis, tanpa API key)
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        setState(() {
          _exchangeRates = {};
          // Konversi semua rate ke double dan filter hanya mata uang yang didukung
          for (String currency in _supportedCurrencies) {
            if (rates.containsKey(currency)) {
              _exchangeRates[currency] = rates[currency].toDouble();
            }
          }
          // USD sebagai base currency memiliki rate 1.0
          _exchangeRates['USD'] = 1.0;
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });

        _showSuccessMessage('Kurs mata uang berhasil diperbarui');
      } else {
        throw Exception('Gagal mengambil data kurs: ${response.statusCode}');
      }
    } catch (e) {
      // Coba API alternatif jika yang pertama gagal
      await _fetchExchangeRatesAlternative();
    }
  }

  // API alternatif gratis tanpa API key
  Future<void> _fetchExchangeRatesAlternative() async {
    try {
      // Opsi 2: Menggunakan exchangerate.host (gratis, tanpa API key)
      final response = await http.get(
        Uri.parse('https://api.exchangerate.host/latest?base=USD&symbols=${_supportedCurrencies.join(',')}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final rates = data['rates'] as Map<String, dynamic>;
          
          setState(() {
            _exchangeRates = {};
            for (String currency in _supportedCurrencies) {
              if (rates.containsKey(currency)) {
                _exchangeRates[currency] = rates[currency].toDouble();
              }
            }
            _exchangeRates['USD'] = 1.0;
            _lastUpdated = DateTime.now();
            _isLoading = false;
          });

          _showSuccessMessage('Kurs mata uang berhasil diperbarui (API alternatif)');
          return;
        }
      }

      // Jika semua API gagal, gunakan fallback
      throw Exception('Semua API gagal');
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Fallback ke kurs statis jika API gagal
        _exchangeRates = {
          'USD': 1.0,
          'IDR': 15400.0,
          'EUR': 0.85,
          'JPY': 110.0,
          'GBP': 0.75,
          'AUD': 1.35,
          'CAD': 1.25,
          'CHF': 0.92,
          'CNY': 6.45,
          'SGD': 1.35,
        };
      });
      
      _showErrorMessage('Menggunakan kurs offline: ${e.toString()}');
    }
  }

  // Untuk API yang memerlukan key (opsional)
  Future<void> _fetchExchangeRatesWithKey(String apiKey) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Opsi 3: Fixer.io (perlu API key gratis dari fixer.io)
      final response = await http.get(
        Uri.parse('http://data.fixer.io/api/latest?access_key=$apiKey&base=USD&symbols=${_supportedCurrencies.join(',')}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final rates = data['rates'] as Map<String, dynamic>;
          
          setState(() {
            _exchangeRates = {};
            for (String currency in _supportedCurrencies) {
              if (rates.containsKey(currency)) {
                _exchangeRates[currency] = rates[currency].toDouble();
              }
            }
            _exchangeRates['USD'] = 1.0;
            _lastUpdated = DateTime.now();
            _isLoading = false;
          });

          _showSuccessMessage('Kurs berhasil diperbarui dengan API key');
        } else {
          throw Exception('API Error: ${data['error']['info']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback ke API gratis
      await _fetchExchangeRates();
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'exchange_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        autoDismissible: true,
      ),
    );
  }

  void _convertCurrency() {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan jumlah yang valid!'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _convertedAmount = 0.0;
      });
      return;
    }

    if (_exchangeRates.isEmpty) {
      _showErrorMessage('Data kurs belum tersedia. Sedang memuat...');
      _fetchExchangeRates();
      return;
    }

    // Konversi mata uang menggunakan USD sebagai base
    double amountInUSD;
    if (_fromCurrency == 'USD') {
      amountInUSD = amount;
    } else {
      amountInUSD = amount / _exchangeRates[_fromCurrency]!;
    }

    double convertedAmount;
    if (_toCurrency == 'USD') {
      convertedAmount = amountInUSD;
    } else {
      convertedAmount = amountInUSD * _exchangeRates[_toCurrency]!;
    }

    setState(() {
      _convertedAmount = convertedAmount;
    });
  }

  void _convertAndSave() async {
    _convertCurrency();

    if (_convertedAmount <= 0) return;

    final double amount = double.tryParse(_amountController.text) ?? 0.0;

    // Simpan ke history
    final historyData = {
      'type': 'Exchange',
      'input': '${amount.toStringAsFixed(2)} $_fromCurrency',
      'output': '${_convertedAmount.toStringAsFixed(2)} $_toCurrency',
      'timestamp': DateTime.now().toString(),
      'rate': 'Rate: 1 $_fromCurrency = ${(_convertedAmount / amount).toStringAsFixed(4)} $_toCurrency',
    };

    // Tampilkan notifikasi
    await _showNotification(
      '💱 Konversi Mata Uang Selesai',
      '${amount.toStringAsFixed(2)} $_fromCurrency = ${_convertedAmount.toStringAsFixed(2)} $_toCurrency'
    );

    // Tampilkan snackbar konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Konversi selesai dan disimpan ke history!'),
        backgroundColor: Colors.green,
      ),
    );

    // Kembali ke home page dengan data history
    Navigator.pop(context, historyData);
  }

  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    
    // Auto convert jika ada amount
    if (_amountController.text.isNotEmpty) {
      _convertCurrency();
    }
  }

  Widget _buildCurrencyDropdown(String label, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF1E1E3F),
          items: _supportedCurrencies.map((String currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Text(
                currency,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Mengatur ulang layout saat keyboard muncul
      appBar: AppBar(
        title: const Text('Currency Exchange'),
        backgroundColor: const Color(0xFF0B0D3A),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _fetchExchangeRates,
            tooltip: 'Perbarui kurs',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0B0D3A),
      body: SafeArea(
        child: SingleChildScrollView( // Membuat halaman bisa di-scroll
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status update terakhir
              if (_lastUpdated != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Diperbarui: ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text('Jumlah:', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => _convertCurrency(),
                decoration: InputDecoration(
                  hintText: 'Masukkan nominal',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.amber),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildCurrencyDropdown('Dari:', _fromCurrency, (value) {
                      setState(() {
                        _fromCurrency = value!;
                      });
                      if (_amountController.text.isNotEmpty) {
                        _convertCurrency();
                      }
                    }),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _swapCurrencies,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(Icons.swap_horiz, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCurrencyDropdown('Ke:', _toCurrency, (value) {
                      setState(() {
                        _toCurrency = value!;
                      });
                      if (_amountController.text.isNotEmpty) {
                        _convertCurrency();
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _convertAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Tukar Mata Uang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _convertedAmount > 0 
                          ? 'Hasil Konversi'
                          : 'Masukkan nominal untuk melihat hasil',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _convertedAmount > 0 
                          ? '${_convertedAmount.toStringAsFixed(2)} $_toCurrency'
                          : '-',
                      style: TextStyle(
                        color: _convertedAmount > 0 ? Colors.amber : Colors.white54,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_convertedAmount > 0 && _amountController.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Rate: 1 $_fromCurrency = ${(_convertedAmount / (double.tryParse(_amountController.text) ?? 1)).toStringAsFixed(4)} $_toCurrency',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}