import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../electricity/electricity_provider.dart';
import '../electricity/profile_screen.dart';
import 'auth_provider.dart';

class AccountProfileScreen extends StatelessWidget {
  const AccountProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final electricity = context.watch<ElectricityProvider>();
    final user = auth.currentUser;
    final profile = electricity.profile;

    final initialLetter = (user?.nama.isNotEmpty == true) ? user!.nama[0].toUpperCase() : 'U';

    String profileSummary = 'Belum diatur';
    if (profile != null) {
      profileSummary = '${profile.kategori} • ${profile.daya} VA • Prabayar';
    }

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
                    'Profil',
                    style: TextStyle(
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
            // User Card sesuai Figma Screen 19
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryLightGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppConstants.primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Text(
                        initialLetter,
                        style: const TextStyle(
                          color: AppConstants.primaryDarkGreen,
                          fontSize: 20,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nama ?? 'Pengguna',
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Akun & Listrik
            const Text(
              'Akun & listrik',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppConstants.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryLightGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt, color: AppConstants.primaryGreen, size: 20),
                    ),
                    title: const Text(
                      'Profil listrik',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      profileSummary,
                      style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppConstants.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppConstants.borderLight),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_none, color: AppConstants.textSecondary, size: 20),
                    ),
                    title: const Text(
                      'Pengaturan notifikasi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Notifikasi saldo rendah (lokal)',
                      style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppConstants.textMuted),
                    onTap: () {
                      _showNotificationSettings(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Tentang
            const Text(
              'Tentang',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppConstants.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline, color: AppConstants.textSecondary, size: 20),
                ),
                title: const Text(
                  'Tentang aplikasi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Hemat Energi v1.0.0 • SDG 7',
                  style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppConstants.textMuted),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Keluar dari Akun (Logout) sesuai Figma Screen 19
            Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0C4C4)),
              ),
              child: TextButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, size: 18, color: AppConstants.errorRed),
                label: const Text(
                  'Keluar dari akun',
                  style: TextStyle(
                    color: AppConstants.errorRed,
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Data Anda tetap tersimpan aman di perangkat ini. Anda dapat masuk kembali kapan saja.',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorRed,
              minimumSize: const Size(90, 36),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan Notifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Aplikasi Hemat Energi memproses notifikasi secara lokal di perangkat tanpa menggunakan server eksternal.\n\nNotifikasi saldo rendah akan dikirimkan secara otomatis jika estimasi sisa hari kurang dari atau sama dengan 2 hari.',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tentang Hemat Energi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Hemat Energi (SDG 7)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 6),
            Text(
              'Aplikasi monitoring dan penghematan listrik prabayar untuk mahasiswa dan anak kos, sejalan dengan SDG 7: Energi Bersih & Terjangkau.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              'Fitur Utama:\n• 100% Offline & Penyimpanan Lokal SQLite\n• Perhitungan Konsumsi Aktual Berurutan\n• Estimasi Sisa Hari Saldo Token\n• Riwayat Token & Meter',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 8),
            Text(
              'Versi: 1.0.0',
              style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
