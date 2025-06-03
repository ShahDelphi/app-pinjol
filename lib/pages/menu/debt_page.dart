import 'package:flutter/material.dart';

class DebtPage extends StatefulWidget {
  const DebtPage({super.key});

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();

  double _totalToPay = 0.0;

  void _calculateAndSaveDebt() {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final int years = int.tryParse(_yearsController.text) ?? 0;

    if (amount <= 0 || years <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan jumlah pinjaman dan lama pinjaman yang valid!'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _totalToPay = 0.0;
      });
      return;
    }

    // Bunga 10% per tahun (bunga majemuk tahunan)
    double total = amount * (1 + 0.10).pow(years);
    setState(() {
      _totalToPay = total;
    });

    // Langsung simpan ke history setelah perhitungan
    final historyData = {
      'type': 'Debt',
      'input': 'IDR ${amount.toStringAsFixed(0)} - ${years} tahun',
      'output': 'Total: IDR ${total.toStringAsFixed(2)}',
      'timestamp': DateTime.now().toString(),
    };

    // Tampilkan snackbar konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perhitungan selesai dan disimpan ke history!'),
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
        title: const Text('Debt'),
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
            const Text(
              'Masukkan jumlah pinjaman (IDR):',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Contoh: 1000000',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Masukkan lama pinjaman (tahun):',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _yearsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Contoh: 2',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateAndSaveDebt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Ajukan Pinjaman',
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
                _totalToPay > 0 
                    ? 'Total yang harus dibayar:\nIDR ${_totalToPay.toStringAsFixed(2)}'
                    : 'Masukkan nominal untuk melihat total pengembalian',
                style: TextStyle(
                  color: _totalToPay > 0 ? Colors.amber : Colors.white54,
                  fontSize: 18,
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

extension DoubleExtension on double {
  double pow(int exponent) {
    return double.parse((this.toDouble()).toStringAsFixed(6)).toDouble().powManual(exponent);
  }

  double powManual(int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}