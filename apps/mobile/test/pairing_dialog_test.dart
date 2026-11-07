import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/models/device_model.dart';
import 'package:nexora_app/widgets/pairing_dialog.dart';

void main() {
  testWidgets(
    'PairingDialog renders without LayoutBuilder intrinsic dimension error',
    (WidgetTester tester) async {
      final device = NexoraDevice(
        deviceId: 'test-device',
        displayName: 'Test Phone',
        platform: 'Android',
        address: '192.168.1.100',
        port: 48842,
        fingerprint: 'abcd1234efgh5678',
        lastSeen: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PairingDialog(
              localDevice: device,
              sasCode: '482910',
              qrData: '{"version":1,"device_id":"test"}',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Pair Device'), findsOneWidget);
      expect(find.text('Short Authentication Code (SAS)'), findsOneWidget);
    },
  );
}
