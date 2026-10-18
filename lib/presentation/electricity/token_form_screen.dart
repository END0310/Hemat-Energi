import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/models/token_purchase.dart';
import '../auth/auth_provider.dart';
import 'electricity_provider.dart';

class TokenFormScreen extends StatefulWidget {
  final TokenPurchase? existingToken;

  const TokenFormScreen({super.key, this.existingToken});

  @override
  State<TokenFormScreen> createState() => _TokenFormScreenState();
}

class _TokenFormScreenState extends State<TokenFormScreen> {
  late DateTime _selectedDateTime;
  final _nominalController = TextEditingController();
  final _kwhController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingToken != null) {
      _selectedDateTime = widget.existingToken!.tanggalWaktu;
      _nominalController.text = widget.existingToken!.nominal.toInt().toString();
      _kwhController.text = AppFormatters.formatKwh(widget.existingToken!.kwhToken).replaceAll('.', ',');
    } else {
      _selectedDateTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _kwhController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _selectedDateTime.hour,
            _selectedDateTime.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final electricity = context.read<ElectricityProvider>();
    final userId = auth.currentUser!.id!;

    final nominalText = _nominalController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final kwhText = _kwhController.text.replaceAll(',', '.').trim();

    final nominal = double.tryParse(nominalText);
    final kwh = double.tryParse(kwhText);

    if (nominal == null || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal token harus lebih besar dari 0.'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }

    if (kwh == null || kwh <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('kWh yang diperoleh harus lebih besar dari 0.'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }

    bool success;
    if (widget.existingToken != null) {
      final updated = widget.existingToken!.copyWith(
        tanggalWaktu: _selectedDateTime,
        nominal: nominal,
        kwhToken: kwh,
      );
      success = await electricity.updateTokenPurchase(updated);
    } else {
      success = await electricity.addTokenPurchase(
        userId: userId,
        tanggalWaktu: _selectedDateTime,
        nominal: nominal,
        kwhToken: kwh,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingToken != null
              ? 'Transaksi token berhasil diperbarui!'
              : 'Transaksi token berhasil disimpan!'),
          backgroundColor: AppConstants.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingToken != null;
    final electricity = context.watch<ElectricityProvider>();

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppConstants.borderLight, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Ubah token' : 'Tambah token',
                    style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field Tanggal transaksi
            const Text(
              'Tanggal transaksi',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.borderInput),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppFormatters.formatDateTime(_selectedDateTime),
                      style: const TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppConstants.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Field Nominal token
            const Text(
              'Nominal token',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: '50.000',
                suffixText: 'Rp',
                suffixStyle: TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Field kWh yang diperoleh
            const Text(
              'kWh yang diperoleh',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _kwhController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Contoh: 33,7',
                suffixText: 'kWh',
                suffixStyle: TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info Box PRD: Tidak dihitung dari nominal / tarif
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, size: 20, color: AppConstants.textSecondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Masukkan jumlah kWh sesuai informasi pada transaksi token Anda. Tidak perlu menghitungnya sendiri.',
                      style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 11,
                        fontFamily: 'Inter',
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Simpan Token
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: electricity.isLoading ? null : _save,
                child: electricity.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEditing ? 'Perbarui Token' : 'Simpan Token',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
