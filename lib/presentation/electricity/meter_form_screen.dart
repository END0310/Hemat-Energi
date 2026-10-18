import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/models/meter_reading.dart';
import '../auth/auth_provider.dart';
import 'electricity_provider.dart';

class MeterFormScreen extends StatefulWidget {
  final MeterReading? existingReading;

  const MeterFormScreen({super.key, this.existingReading});

  @override
  State<MeterFormScreen> createState() => _MeterFormScreenState();
}

class _MeterFormScreenState extends State<MeterFormScreen> {
  late DateTime _selectedDateTime;
  final _saldoController = TextEditingController();
  String? _fotoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingReading != null) {
      _selectedDateTime = widget.existingReading!.tanggalWaktu;
      _saldoController.text = AppFormatters.formatKwh(widget.existingReading!.saldoKwh).replaceAll('.', ',');
      _fotoPath = widget.existingReading!.fotoPath;
    } else {
      _selectedDateTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _saldoController.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Salin file ke folder dokumen lokal aplikasi
        final dbPath = await getDatabasesPath();
        final docDir = Directory(p.join(p.dirname(dbPath), 'meter_photos'));
        if (!await docDir.exists()) {
          await docDir.create(recursive: true);
        }

        final fileName = 'meter_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
        final savedFile = await File(pickedFile.path).copy(p.join(docDir.path, fileName));

        setState(() {
          _fotoPath = savedFile.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppConstants.primaryGreen),
              title: const Text('Ambil Foto dengan Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppConstants.primaryGreen),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_fotoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppConstants.errorRed),
                title: const Text('Hapus Foto Terpasang', style: TextStyle(color: AppConstants.errorRed)),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _fotoPath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final saldoText = _saldoController.text.replaceAll(',', '.').trim();
    final saldo = double.tryParse(saldoText);

    if (saldo == null || saldo < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saldo kWh harus diisi dengan angka tidak negatif.'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }

    final electricity = context.read<ElectricityProvider>();

    // Cek apakah hasil konsumsi negatif
    if (widget.existingReading == null) {
      final willBeNegative = electricity.checkWillResultInNegativeConsumption(
        newSaldoKwh: saldo,
        newTanggalWaktu: _selectedDateTime,
      );

      if (willBeNegative) {
        final confirm = await _showNegativeWarningDialog();
        if (confirm != true) return;
        if (!mounted) return;
      }
    }

    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser!.id!;

    bool success;
    if (widget.existingReading != null) {
      final updated = widget.existingReading!.copyWith(
        tanggalWaktu: _selectedDateTime,
        saldoKwh: saldo,
        fotoPath: _fotoPath,
      );
      success = await electricity.updateMeterReading(updated);
    } else {
      success = await electricity.addMeterReading(
        userId: userId,
        tanggalWaktu: _selectedDateTime,
        saldoKwh: saldo,
        fotoPath: _fotoPath,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingReading != null
              ? 'Catatan meter berhasil diperbarui!'
              : 'Catatan meter berhasil disimpan!'),
          backgroundColor: AppConstants.primaryGreen,
        ),
      );
    }
  }

  Future<bool?> _showNegativeWarningDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppConstants.warningYellow, size: 24),
            SizedBox(width: 8),
            Text('Periksa Data Input', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Saldo yang Anda masukkan lebih besar dari saldo sebelumnya ditambah token yang tercatat. Hal ini menyebabkan perhitungan konsumsi bernilai negatif.\n\nApakah Anda yakin angka saldo meter dan tanggal sudah benar?',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Periksa Ulang'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              minimumSize: const Size(100, 36),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tetap Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReading != null;
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
                    isEditing ? 'Ubah catatan meter' : 'Catat meter',
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
            // Field Tanggal & waktu
            const Text(
              'Tanggal & waktu',
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

            // Field Saldo kWh
            const Text(
              'Saldo kWh',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _saldoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Contoh: 11,2',
                suffixText: 'kWh',
                suffixStyle: TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Field Foto Meter (Opsional)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Foto meter',
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Opsional',
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _showImagePickerOptions,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _fotoPath != null ? AppConstants.primaryGreen : AppConstants.borderInput,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _fotoPath != null && File(_fotoPath!).existsSync()
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_fotoPath!),
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle, size: 16, color: AppConstants.primaryGreen),
                              SizedBox(width: 4),
                              Text(
                                'Foto bukti terpasang (ketuk untuk ganti)',
                                style: TextStyle(
                                  color: AppConstants.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: const [
                          Icon(Icons.camera_alt_outlined, size: 28, color: AppConstants.primaryGreen),
                          SizedBox(height: 6),
                          Text(
                            'Tambah foto',
                            style: TextStyle(
                              color: AppConstants.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Hanya untuk dokumentasi, angka tetap diisi manual',
                            style: TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Info Box
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
                      'Pastikan angka sesuai dengan yang terlihat pada meter listrik.',
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

            // Tombol Simpan Catatan
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: electricity.isLoading ? null : _handleSave,
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
                        isEditing ? 'Perbarui Catatan' : 'Simpan Catatan',
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
