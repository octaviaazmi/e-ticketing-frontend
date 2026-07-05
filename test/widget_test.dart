import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpdesk_app/main.dart'; // sesuaikan dengan nama project kamu

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // 🔥 HAPUS 'const' DI SINI 🔥
    await tester.pumpWidget(MyApp());

    // Verify that our app starts with the login screen.
    // (Kita tidak perlu test default Flutter, tapi ini biar ga error)
    expect(find.text('E-Ticketing Helpdesk'), findsOneWidget);
  });
}