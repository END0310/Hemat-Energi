import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'presentation/auth/account_profile_screen.dart';
import 'presentation/auth/auth_provider.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/splash_screen.dart';
import 'presentation/electricity/electricity_provider.dart';
import 'presentation/electricity/history_screen.dart';
import 'presentation/electricity/meter_form_screen.dart';
import 'presentation/electricity/meter_screen.dart';
import 'presentation/electricity/profile_screen.dart';
import 'presentation/electricity/token_form_screen.dart';
import 'presentation/electricity/token_screen.dart';
import 'presentation/shared/main_navigation_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale bahasa Indonesia untuk format tanggal DateFormat ('id_ID')
  await initializeDateFormatting('id_ID', null);

  // Multiplatform SQLite configuration:
  // 1. Web: Menggunakan sqflite_common_ffi_web (IndexedDB/Wasm)
  // 2. Desktop (Windows/Linux/macOS): Menggunakan FFI
  // 3. Mobile (Android/iOS): sqflite berjalan secara native bawaan OS
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const HematEnergiApp());
}

class HematEnergiApp extends StatelessWidget {
  const HematEnergiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ElectricityProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const MainNavigationScreen(),
          '/account': (context) => const AccountProfileScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/token': (context) => const TokenScreen(),
          '/token/form': (context) => const TokenFormScreen(),
          '/meter': (context) => const MeterScreen(),
          '/meter/form': (context) => const MeterFormScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}
