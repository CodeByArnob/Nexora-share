import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/network/transfer_server.dart';
import 'package:nexora_app/widgets/receiver_approval_dialog.dart';

void main() {
  testWidgets('ReceiverApprovalDialog displays metadata and handles acceptance', (tester) async {
    final offer = IncomingTransferOffer(
      transferId: 'test-transfer-123',
      senderName: 'Windows Workstation',
      senderPlatform: 'Windows',
      fileName: 'dataset.tar.gz',
      totalBytes: 52428800, // 50 MB
      totalFiles: 1,
      declaredSha256: 'abc123declaredhash',
    );

    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (context) => ReceiverApprovalDialog(offer: offer),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify metadata displayed to receiver
    expect(find.text('Incoming Transfer'), findsOneWidget);
    expect(find.textContaining('Windows Workstation (Windows)'), findsOneWidget);
    expect(find.text('dataset.tar.gz'), findsOneWidget);
    expect(find.text('Total Size: 50.0 MB'), findsOneWidget);
    expect(find.text('1 file(s)'), findsOneWidget);
    expect(find.text('Destination: Downloads/NEXORA'), findsOneWidget);

    // Tap Accept & Save
    await tester.tap(find.text('Accept & Save'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('ReceiverApprovalDialog decline returns false', (tester) async {
    final offer = IncomingTransferOffer(
      transferId: 'test-transfer-456',
      senderName: 'Unknown Phone',
      senderPlatform: 'Android',
      fileName: 'unwanted.apk',
      totalBytes: 1048576,
      totalFiles: 1,
    );

    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (context) => ReceiverApprovalDialog(offer: offer),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
