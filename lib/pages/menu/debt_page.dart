import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class DebtPage extends StatefulWidget {
  const DebtPage({super.key});

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();

  double _totalToPay = 0.0;
  double _interestAmount = 0.0;
  double _monthlyPayment = 0.0;
  bool _isCalculated = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'debt_channel',
          channelName: 'Debt Calculator',
          channelDescription: 'Notification channel for debt calculations',
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

  Future<void> _showNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'debt_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        autoDismissible: true,
      ),
    );
  }

  void _calculateDebt() {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final int years = int.tryParse(_yearsController.text) ?? 0;

    if (amount <= 0 || years <= 0) {
      setState(() {
        _totalToPay = 0.0;
        _interestAmount = 0.0;
        _monthlyPayment = 0.0;
        _isCalculated = false;
      });
      return;
    }

    // Bunga 10% per tahun (bunga majemuk tahunan)
    double total = amount * (1 + 0.10).pow(years);
    double interest = total - amount;
    double monthly = total / (years * 12);

    setState(() {
      _totalToPay = total;
      _interestAmount = interest;
      _monthlyPayment = monthly;
      _isCalculated = true;
    });
  }

  void _calculateAndSaveDebt() async {
    _calculateDebt();

    if (_totalToPay <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan jumlah pinjaman dan lama pinjaman yang valid!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final int years = int.tryParse(_yearsController.text) ?? 0;

    // Simpan ke history
    final historyData = {
      'type': 'Debt',
      'input': 'IDR ${amount.toStringAsFixed(0)} - ${years} tahun',
      'output': 'Total: IDR ${_totalToPay.toStringAsFixed(2)}',
      'timestamp': DateTime.now().toString(),
      'details': 'Bunga: IDR ${_interestAmount.toStringAsFixed(2)} | Cicilan/bulan: IDR ${_monthlyPayment.toStringAsFixed(2)}',
    };

    // Tampilkan notifikasi
    await _showNotification(
      '💰 Perhitungan Pinjaman Selesai',
      'Total yang harus dibayar: IDR ${_totalToPay.toStringAsFixed(2)}'
    );

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

  Widget _buildInputField(String label, TextEditingController controller, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) => _calculateDebt(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(icon, color: Colors.amber),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
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
            _isCalculated 
                ? 'Hasil Perhitungan Pinjaman'
                : 'Masukkan nominal dan tahun untuk melihat hasil',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          
          if (_isCalculated) ...[
            // Total yang harus dibayar
            _buildResultRow('Total Pembayaran', _totalToPay, Colors.amber),
            const Divider(color: Colors.white24, height: 30),
            
            // Bunga
            _buildResultRow('Total Bunga', _interestAmount, Colors.orange),
            const SizedBox(height: 15),
            
            // Cicilan per bulan
            _buildResultRow('Cicilan/Bulan', _monthlyPayment, Colors.lightBlue),
            const SizedBox(height: 15),
            
            // Info rate
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suku bunga: 10% per tahun (bunga majemuk)',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              '-',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          'IDR ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Debt Calculator'),
        backgroundColor: const Color(0xFF0B0D3A),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      backgroundColor: const Color(0xFF0B0D3A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kalkulator pinjaman dengan bunga majemuk 10% per tahun',
                        style: const TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              _buildInputField(
                'Jumlah Pinjaman (IDR):',
                _amountController,
                'Masukkan Nominal',
                Icons.account_balance_wallet
              ),
              const SizedBox(height: 20),

              _buildInputField(
                'Lama Pinjaman (Tahun):',
                _yearsController,
                'Masukkan Lama Pinjaman',
                Icons.calendar_today
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculateAndSaveDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Ajukan Pinjaman',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _yearsController.dispose();
    super.dispose();
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