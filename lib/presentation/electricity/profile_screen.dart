import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../auth/auth_provider.dart';
import 'electricity_provider.dart';
import 'meter_screen.dart';
import 'token_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final electricity = context.watch<ElectricityProvider>();
    final profile = electricity.profile;
    final tariff = electricity.tariff;

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
                  const Text(
                    'Profil listrik',
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showEditProfileBottomSheet(context),
                    child: Text(
                      profile == null ? 'Isi' : 'Ubah',
                      style: const TextStyle(
                        color: AppConstants.primaryGreen,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Banner Profil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryLightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.bolt, color: AppConstants.primaryDarkGreen, size: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Listrik kamar kos',
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile?.jenisListrik ?? 'Prabayar / Token',
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rincian Detail Profil Listrik
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Kategori / golongan',
                    value: profile?.kategori ?? 'Belum diatur',
                  ),
                  const Divider(height: 1, color: AppConstants.borderLight),
                  _buildDetailRow(
                    label: 'Daya terpasang',
                    value: profile != null ? '${AppFormatters.formatKwh(profile.daya.toDouble())} VA' : '-',
                  ),
                  const Divider(height: 1, color: AppConstants.borderLight),
                  _buildDetailRow(
                    label: 'Jenis listrik',
                    value: profile?.jenisListrik ?? 'Prabayar',
                  ),
                  const Divider(height: 1, color: AppConstants.borderLight),
                  _buildDetailRow(
                    label: 'Tarif berlaku',
                    value: tariff != null ? AppFormatters.formatTariff(tariff) : '-',
                    isTariff: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Box Tarif Otomatis PLN
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
                      'Tarif ditentukan otomatis berdasarkan golongan dan daya. Kamu tidak perlu memasukkannya sendiri.',
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
            const SizedBox(height: 28),

            // Kelola Listrik Section
            const Text(
              'Kelola listrik',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Shortcut Token Listrik
            _buildNavCard(
              icon: Icons.confirmation_number_outlined,
              title: 'Token listrik',
              subtitle: 'Lihat saldo dan pembelian',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TokenScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            // Shortcut Catatan Meter
            _buildNavCard(
              icon: Icons.speed_outlined,
              title: 'Catatan meter',
              subtitle: 'Pantau perubahan saldo',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MeterScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isTariff = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: isTariff ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppConstants.primaryLightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppConstants.primaryGreen, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 11,
            fontFamily: 'Inter',
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppConstants.textMuted),
      ),
    );
  }

  void _showEditProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _EditProfileForm(),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm();

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  String? _selectedKategori;
  int? _selectedDaya;
  double? _lookedUpTariff;
  bool _loadingOptions = true;

  List<String> _kategoriList = [];
  List<int> _dayaList = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final electricity = context.read<ElectricityProvider>();
    final categories = await electricity.getCategories();

    final currentProfile = electricity.profile;
    String? initialKat = currentProfile?.kategori ?? (categories.isNotEmpty ? categories.first : null);
    List<int> powerOptions = [];

    if (initialKat != null) {
      powerOptions = await electricity.getPowerOptions(initialKat);
    }

    int? initialDaya = currentProfile?.daya ?? (powerOptions.isNotEmpty ? powerOptions.first : null);
    double? initialTariff;

    if (initialKat != null && initialDaya != null) {
      initialTariff = await electricity.lookupTariff(initialKat, initialDaya);
    }

    if (mounted) {
      setState(() {
        _kategoriList = categories;
        _selectedKategori = initialKat;
        _dayaList = powerOptions;
        _selectedDaya = initialDaya;
        _lookedUpTariff = initialTariff;
        _loadingOptions = false;
      });
    }
  }

  Future<void> _onCategoryChanged(String? newCategory) async {
    if (newCategory == null) return;
    setState(() {
      _selectedKategori = newCategory;
      _loadingOptions = true;
    });

    final electricity = context.read<ElectricityProvider>();
    final powers = await electricity.getPowerOptions(newCategory);
    final firstDaya = powers.isNotEmpty ? powers.first : null;
    double? tariff;

    if (firstDaya != null) {
      tariff = await electricity.lookupTariff(newCategory, firstDaya);
    }

    if (mounted) {
      setState(() {
        _dayaList = powers;
        _selectedDaya = firstDaya;
        _lookedUpTariff = tariff;
        _loadingOptions = false;
      });
    }
  }

  Future<void> _onDayaChanged(int? newDaya) async {
    if (newDaya == null || _selectedKategori == null) return;
    setState(() {
      _selectedDaya = newDaya;
    });

    final electricity = context.read<ElectricityProvider>();
    final tariff = await electricity.lookupTariff(_selectedKategori!, newDaya);

    if (mounted) {
      setState(() {
        _lookedUpTariff = tariff;
      });
    }
  }

  Future<void> _save() async {
    if (_selectedKategori == null || _selectedDaya == null) return;

    final auth = context.read<AuthProvider>();
    final electricity = context.read<ElectricityProvider>();
    final userId = auth.currentUser!.id!;

    final success = await electricity.saveProfile(
      userId: userId,
      kategori: _selectedKategori!,
      daya: _selectedDaya!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil listrik berhasil diperbarui!'),
          backgroundColor: AppConstants.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _selectedKategori != null && _selectedDaya != null && _lookedUpTariff != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ubah Profil Listrik',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  color: AppConstants.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_loadingOptions)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // Dropdown Kategori
            const Text(
              'Kategori / Golongan Tarif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedKategori,
              items: _kategoriList.map((kat) {
                return DropdownMenuItem(value: kat, child: Text(kat));
              }).toList(),
              onChanged: _onCategoryChanged,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown Daya
            const Text(
              'Daya Terpasang (VA)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _selectedDaya,
              items: _dayaList.map((daya) {
                return DropdownMenuItem(
                  value: daya,
                  child: Text('${AppFormatters.formatKwh(daya.toDouble())} VA'),
                );
              }).toList(),
              onChanged: _onDayaChanged,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Tarif Read-Only
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppConstants.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tarif Resmi Berlaku:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  Text(
                    _lookedUpTariff != null
                        ? AppFormatters.formatTariff(_lookedUpTariff!)
                        : 'Tarif tidak ditemukan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _lookedUpTariff != null ? AppConstants.primaryGreen : AppConstants.errorRed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: canSave ? _save : null,
                child: const Text('Simpan Profil Listrik'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
