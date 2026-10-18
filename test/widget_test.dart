import 'package:flutter_test/flutter_test.dart';
import 'package:hemat_energi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders SplashScreen and navigates smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HematEnergiApp());

    // Memastikan teks SplashScreen tampil di awal
    expect(find.text('Hemat Energi'), findsWidgets);
    expect(find.text('Pakai listrik lebih bijak.'), findsOneWidget);

    // Majukan timer 1500ms agar navigasi splash selesai
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    // Memastikan berpindah ke LoginScreen karena belum login
    expect(find.text('Selamat datang'), findsOneWidget);
    expect(find.text('Kelola listrikmu dengan lebih mudah.'), findsOneWidget);
  });
}
