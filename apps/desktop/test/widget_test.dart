import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_desktop/main.dart';

void main() {
  testWidgets('Desktop Shell renders sidebar navigation and NEXORA branding', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: NexoraDesktopApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify NEXORA branding in sidebar and top header
    expect(find.text('NEXORA'), findsWidgets);
    expect(find.text('CONNECT. SHARE.'), findsOneWidget);

    // Verify navigation sidebar items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Transfers'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Trusted Devices'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap 'Send' in sidebar
    await tester.tap(find.text('Send'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Send Files'), findsOneWidget);
    expect(find.text('1. Select Destination Device'), findsOneWidget);

    // Tap 'Receive' in sidebar
    await tester.tap(find.text('Receive'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Receive Files'), findsOneWidget);
    expect(find.text('Receiver Engine Active'), findsOneWidget);

    // Tap 'Transfers' in sidebar
    await tester.tap(find.text('Transfers'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Active Transfers'), findsOneWidget);
    expect(find.text('No Transfers in Progress'), findsOneWidget);

    // Tap 'History' in sidebar
    await tester.tap(find.text('History'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Transfer History'), findsOneWidget);
    expect(find.text('No Transfer History Yet'), findsOneWidget);

    // Tap 'Trusted Devices' in sidebar
    await tester.tap(find.text('Trusted Devices'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Add Manual IP'), findsOneWidget);

    // Tap 'Settings' in sidebar
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Device Display Name'), findsOneWidget);
    expect(find.text('Windows Firewall Troubleshooter'), findsOneWidget);
  });
}
