import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../dashboard/dashboard_screen.dart';
import '../electricity/history_screen.dart';
import '../electricity/profile_screen.dart';
import '../saving/saving_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(onTabChange: _onTabTapped),
      const ProfileScreen(),
      _buildPlaceholderPage(
        title: 'Perangkat',
        subtitle: 'Modul 2: Monitoring Konsumsi Perangkat',
        description: 'Fitur pendataan perangkat elektronik, estimasi konsumsi harian dan bulanan per alat akan dikerjakan pada modul berikutnya.',
        icon: Icons.devices_outlined,
      ),
      const SavingScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppConstants.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Beranda'),
              _buildNavItem(1, Icons.bolt_outlined, Icons.bolt, 'Listrik'),
              _buildNavItem(2, Icons.devices_outlined, Icons.devices, 'Perangkat'),
              _buildNavItem(3, Icons.eco_outlined, Icons.eco, 'Hemat'),
              _buildNavItem(4, Icons.history_outlined, Icons.history, 'Riwayat'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabTapped(index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.primaryLightGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  isSelected ? filledIcon : outlineIcon,
                  size: 18,
                  color: isSelected ? AppConstants.primaryDarkGreen : const Color(0xFF747E77),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppConstants.primaryDarkGreen : const Color(0xFF747E77),
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPage({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
  }) {
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Text(
                    title,
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppConstants.primaryLightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppConstants.primaryGreen, size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  color: AppConstants.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppConstants.border),
                ),
                child: const Text(
                  'Segera hadir (Anggota tim lain)',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Inter',
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
