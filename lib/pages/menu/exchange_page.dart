import 'package:flutter/material.dart';

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

  // Nilai tukar relatif terhadap IDR (1 mata uang = X IDR)
  final Map<String, double> _exchangeRatesToIDR = {
    'IDR': 1.0,
    'USD': 15400.0,
    'EUR': 16600.0,
    'JPY': 105.0,
  };

  void _convertAndSave() {
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

    // Proses konversi
    final double fromRate = _exchangeRatesToIDR[_fromCurrency]!;
    final double toRate = _exchangeRatesToIDR[_toCurrency]!;

    // Konversi: jumlah dalam IDR → bagi dengan rate tujuan
    double amountInIDR = amount * fromRate;
    double convertedAmount = amountInIDR / toRate;

    setState(() {
      _convertedAmount = convertedAmount;
    });

    // Langsung simpan ke history setelah konversi
    final historyData = {
      'type': 'Exchange',
      'input': '${amount.toStringAsFixed(2)} $_fromCurrency',
      'output': '${convertedAmount.toStringAsFixed(2)} $_toCurrency',
      'timestamp': DateTime.now().toString(),
    };

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Exchange'),
        backgroundColor: const Color(0xFF0B0D3A),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      backgroundColor: const Color(0xFF0B0D3A),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jumlah:',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Masukkan nominal',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dari:',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _fromCurrency,
                        dropdownColor: Colors.amber,
                        items: _exchangeRatesToIDR.keys.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency,
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _fromCurrency = value!;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.swap_horiz, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ke:',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _toCurrency,
                        dropdownColor: Colors.amber,
                        items: _exchangeRatesToIDR.keys.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency,
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _toCurrency = value!;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
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
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _convertedAmount > 0 
                    ? 'Hasil Konversi:\n${_convertedAmount.toStringAsFixed(2)} $_toCurrency'
                    : 'Masukkan nominal untuk melihat hasil tukar mata uang ',
                style: TextStyle(
                  color: _convertedAmount > 0 ? Colors.amber : Colors.white54,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}