import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orarepot/app_config.dart';
import 'package:orarepot/ppob_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the OraRepot PPOB shell', (WidgetTester tester) async {
    const config = AppConfig(
      environment: AppEnvironment.sit,
      apiBaseUrl: 'https://api.orarepot.com',
      appName: 'OraRepot',
      googleClientId:
          '569539983389-ue1egs1g4rivgo1csjn9ci734h1qopdc.apps.googleusercontent.com',
    );
    await tester.pumpWidget(const OraRepotPpobApp(config: config, showSplash: false));
    await tester.pump();
    // Allow boot Future (auth/theme load) to complete.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('SEMUA SISTEM NORMAL'), findsOneWidget);
    expect(find.text('TOKO PULSA ORA REPOT'), findsOneWidget);
    expect(find.text('Beli sekarang  ↗'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);

    final scroll = find.byType(CustomScrollView);
    await tester.drag(scroll, const Offset(0, -800));
    await tester.pump();
    expect(find.text('INVENTORY MODULE'), findsOneWidget);
    for (var i = 0; i < 12 && find.text('BUILT FOR SPEED').evaluate().isEmpty; i++) {
      await tester.drag(scroll, const Offset(0, -500));
      await tester.pump();
    }
    expect(find.text('BUILT FOR SPEED'), findsOneWidget);
  });
}
