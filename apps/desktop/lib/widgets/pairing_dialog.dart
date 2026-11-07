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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? NexoraColors.darkSurface : Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NexoraColors.electricBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: NexoraColors.electricBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pair Device',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SizedBox(
                width: 190,
                height: 190,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 190.0,
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
            ),
            const SizedBox(height: 18),
            const Text(
              'Short Authentication Code (SAS)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: NexoraColors.signalTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sasCode,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5.0,
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan this QR code from NEXORA on your Android device to verify mutual authentication keys.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: NexoraColors.electricBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
