import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/models/device_model.dart';
import 'package:nexora_app/providers/app_state.dart';
import 'package:nexora_app/screens/devices_screen.dart';
import 'package:nexora_app/theme/nexora_theme.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('State 1: Initial & No Devices Found State renders properly in light mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: const DevicesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Devices & Trust Hub'), findsOneWidget);
    expect(find.text('Nearby Discoverable Peers'), findsOneWidget);
    expect(find.text('Trusted Devices'), findsOneWidget);
    expect(find.text('No trusted devices'), findsOneWidget);
  });

  testWidgets('State 1: Initial & No Devices Found State renders properly in dark mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: NexoraTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const DevicesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Devices & Trust Hub'), findsOneWidget);
    expect(find.text('Nearby Discoverable Peers'), findsOneWidget);
    expect(find.text('Trusted Devices'), findsOneWidget);
    expect(find.text('No trusted devices'), findsOneWidget);
  });

  testWidgets('State 2: Scanning State renders with radar pulse ring and cancel control', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: NexoraTheme.darkTheme,
          home: const DevicesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Initially it starts scan on launch, so scanning text and Cancel Scan should be visible
    expect(find.text('Scanning for nearby NEXORA devices...'), findsOneWidget);
    expect(find.text('Cancel Scan'), findsOneWidget);

    // Cancel scan
    await tester.tap(find.text('Cancel Scan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No nearby devices found'), findsOneWidget);
    expect(find.text('Scan Again'), findsOneWidget);
  });

  testWidgets('State 3: Devices Found State renders discovered peer cards with Send Files button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final activePeer = NexoraDevice(
      deviceId: 'peer-device-android-1',
      displayName: 'Galaxy S24 Ultra',
      platform: 'Android',
      fingerprint: '3978f639c6b014243b0d142017243af5f7fb00112233445566778899aabbccdd',
      address: '192.168.1.120',
      port: 48842,
      lastSeen: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveredPeersProvider.overrideWith((ref) => [activePeer]),
        ],
        child: MaterialApp(
          theme: NexoraTheme.darkTheme,
          home: const DevicesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Galaxy S24 Ultra'), findsOneWidget);
    expect(find.text('Send Files'), findsOneWidget);
    expect(find.text('1 Active'), findsOneWidget);
  });

  testWidgets('State 7: Trusted Devices hub renders short, empty, and full fingerprints safely without RangeError', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final shortFpDevice = NexoraDevice(
      deviceId: 'trusted-short',
      displayName: 'Short FP Device',
      platform: 'Windows',
      fingerprint: 'a', // Only 1 char
      lastSeen: DateTime.now(),
    );

    final emptyFpDevice = NexoraDevice(
      deviceId: 'trusted-empty',
      displayName: 'Empty FP Device',
      platform: 'Linux',
      fingerprint: '', // Empty string
      lastSeen: DateTime.now(),
    );

    final fullFpDevice = NexoraDevice(
      deviceId: 'trusted-full',
      displayName: 'MacBook Pro',
      platform: 'macOS',
      fingerprint: 'A1B2C3D4E5F60718293A4B5C6D7E8F901234567890ABCDEF1234567890ABCDEF',
      lastSeen: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trustedDevicesProvider.overrideWith((ref) => [
            shortFpDevice,
            emptyFpDevice,
            fullFpDevice,
          ]),
        ],
        child: MaterialApp(
          theme: NexoraTheme.darkTheme,
          home: const DevicesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Short FP Device'), findsOneWidget);
    expect(find.text('Empty FP Device'), findsOneWidget);
    expect(find.text('MacBook Pro'), findsOneWidget);
    expect(find.text('3 Saved'), findsOneWidget);

    // Verify formatShortFingerprint directly
    expect(DevicesScreen.formatShortFingerprint(''), 'Unverified');
    expect(DevicesScreen.formatShortFingerprint('abc'), 'ABC');
    expect(
      DevicesScreen.formatShortFingerprint('A1B2C3D4E5F60718293A4B5C6D7E8F90'),
      'A1B2C3D4E5F60718...',
    );
  });

  testWidgets('Connect by IP dialog opens and handles input', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: NexoraTheme.darkTheme,
          home: const DevicesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap on Connect by IP icon button in app bar
    await tester.tap(find.byIcon(Icons.wifi_find).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Peer IP Address'), findsOneWidget);

    // Enter IP and cancel
    await tester.enterText(find.byType(TextField), '192.168.1.55');
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(AlertDialog), findsNothing);
  });
}
