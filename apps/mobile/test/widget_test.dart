import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/main.dart';

void main() {
  testWidgets('NEXORA smoke test and navigation verify', (
    WidgetTester tester,
  ) async {
    // Build NEXORA inside ProviderScope
    await tester.pumpWidget(const ProviderScope(child: NexoraApp()));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Brand title is rendered
    expect(find.text('NEXORA'), findsOneWidget);

    // Verify Quick Action buttons are present
    expect(find.text('Send Files'), findsOneWidget);
    expect(find.text('Receive Files'), findsOneWidget);

    // Verify 5 Bottom Navigation items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transfers'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap on Transfers tab
    await tester.tap(find.text('Transfers'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No active transfers'), findsOneWidget);

    // Tap on History tab
    await tester.tap(find.text('History'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No transfer history'), findsOneWidget);

    // Tap on Devices tab
    await tester.tap(find.text('Devices'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Devices & Trust Hub'), findsOneWidget);
    expect(find.text('Nearby Discoverable Peers'), findsOneWidget);

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('DEVICE IDENTITY'), findsOneWidget);
    expect(find.text('Device Display Name'), findsOneWidget);
    expect(find.text('Theme Mode'), findsOneWidget);

    // Tap back on Home tab
    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 100));

    // Tap on QR code icon
    await tester.tap(find.byIcon(Icons.qr_code_2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Pair Device'), findsOneWidget);
    expect(find.text('Short Authentication Code (SAS)'), findsOneWidget);
  });
}
