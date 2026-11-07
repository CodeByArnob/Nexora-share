import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/device_model.dart';
import '../theme/nexora_theme.dart';

class PairingDialog extends StatelessWidget {
  final NexoraDevice localDevice;
  final String sasCode;
  final String qrData;

  const PairingDialog({
    super.key,
    required this.localDevice,
    required this.sasCode,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.qr_code_2, color: NexoraColors.electricBlue, size: 28),
          SizedBox(width: 10),
          Text('Pair Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: NexoraColors.midnightNavy,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: NexoraColors.midnightNavy,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Short Authentication Code (SAS)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: NexoraColors.signalTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sasCode,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                color: NexoraColors.midnightNavy,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan with the other NEXORA device to verify public key fingerprint',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
