import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nama_project/main.dart';

void main() {
  testWidgets('App smoke test - renders without errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HematAirEnergiApp());
    expect(find.byType(HematAirEnergiApp), findsOneWidget);
    // Lepas splash sebelum menyelesaikan timer navigasi yang dijadwalkannya.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
