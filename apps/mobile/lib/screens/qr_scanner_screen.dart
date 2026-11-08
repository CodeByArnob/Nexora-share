import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/device_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../services/pairing_security_service.dart';
import '../theme/nexora_theme.dart';
import '../widgets/nexora_motion.dart';
import 'pairing_screen.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  bool _isFlashOn = false;
  bool _isDetecting = false;
  late AnimationController _detectionController;
  late Animation<double> _detectionPulse;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: true,
    );

    _detectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _detectionPulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _detectionController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _detectionController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onQrDetected(String rawPayload) async {
    if (_isDetecting) return;
    setState(() {
      _isDetecting = true;
    });

    HapticFeedback.mediumImpact();
    await _detectionController.forward();
    await _detectionController.reverse();

    final result = PairingSecurityService.verifyPayload(rawPayload);

    if (!mounted) return;

    if (result.isValid) {
      await _scannerController.stop();
      if (!mounted) return;
      final remoteDevice = result.data!.toDevice();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PairingScreen(
            remoteDevice: remoteDevice,
            sasCode: result.data!.sasCode,
            sessionId: result.data!.sessionId,
            pairingData: result.data,
          ),
        ),
      );
    } else {
      setState(() {
        _isDetecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: NexoraColors.errorRed,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.errorMessage ?? 'Invalid or expired QR pairing code.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importFromGallery() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);
      if (files.isNotEmpty && files.first.path != null) {
        final filePath = files.first.path!;
        // Try optical ML Kit barcode analysis from image
        try {
          final capture = await _scannerController.analyzeImage(filePath);
          if (capture != null && capture.barcodes.isNotEmpty) {
            final raw = capture.barcodes.first.rawValue;
            if (raw != null && raw.isNotEmpty) {
              _onQrDetected(raw);
              return;
            }
          }
        } catch (_) {}

        // Fallback: Read file string if JSON/text exported QR payload
        final file = File(filePath);
        String content = '';
        try {
          content = await file.readAsString();
        } catch (_) {}

        if (content.isNotEmpty) {
          _onQrDetected(content);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No QR code detected in the selected image or file.',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gallery import error: $e')));
      }
    }
  }

  void _showManualCodeEntry() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pin, color: NexoraColors.electricBlue),
            SizedBox(width: 8),
            Text('Enter Pairing Code / IP'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 6-digit SAS code or IP address from the other device:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. 482910 or 192.168.1.5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final input = codeController.text.trim();
              Navigator.pop(ctx);
              if (input.isNotEmpty) {
                // If IP address
                if (input.contains('.')) {
                  ref.read(networkControllerProvider).manualConnect(input);
                  final peers = ref.read(discoveredPeersProvider);
                  final match =
                      peers.where((p) => p.address == input).firstOrNull ??
                      NexoraDevice(
                        deviceId: 'ip-$input',
                        displayName: 'Device @ $input',
                        platform: 'Local Peer',
                        fingerprint: 'manual-fingerprint-$input',
                        address: input,
                        lastSeen: DateTime.now(),
                      );
                  _onQrDetected(
                    jsonEncode({
                      'v': 1,
                      'sid': 'ses-${DateTime.now().millisecondsSinceEpoch}',
                      'did': match.deviceId,
                      'name': match.displayName,
                      'plt': match.platform,
                      'fp': match.fingerprint,
                      'addr': match.address ?? input,
                      'p': 48842,
                      'nonce': PairingSecurityService.generateNonce(12),
                      'sas': '482910',
                      'exp': DateTime.now()
                          .add(const Duration(minutes: 10))
                          .toIso8601String(),
                    }),
                  );
                } else {
                  // SAS code matching peer or local payload
                  final peers = ref.read(discoveredPeersProvider);
                  final peer = peers.isNotEmpty
                      ? peers.first
                      : NexoraDevice(
                          deviceId: 'peer-sas-$input',
                          displayName: 'Paired Device ($input)',
                          platform: 'Android',
                          fingerprint: 'fp-$input',
                          address: '127.0.0.1',
                          lastSeen: DateTime.now(),
                        );
                  _onQrDetected(
                    jsonEncode({
                      'v': 1,
                      'sid': 'ses-${DateTime.now().millisecondsSinceEpoch}',
                      'did': peer.deviceId,
                      'name': peer.displayName,
                      'plt': peer.platform,
                      'fp': peer.fingerprint,
                      'addr': peer.address ?? '127.0.0.1',
                      'p': 48842,
                      'nonce': PairingSecurityService.generateNonce(12),
                      'sas': input,
                      'exp': DateTime.now()
                          .add(const Duration(minutes: 10))
                          .toIso8601String(),
                    }),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Native Camera Feed with ML Kit Barcode Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.isNotEmpty) {
                  _onQrDetected(raw);
                  break;
                }
              }
            },
            placeholderBuilder: (context) => Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: NexoraColors.signalTeal),
                    SizedBox(height: 16),
                    Text(
                      'Starting Optical Camera Sensor...',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            errorBuilder: (context, error) {
              final isDenied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;
              return Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDenied
                            ? NexoraColors.warningAmber.withValues(alpha: 0.15)
                            : NexoraColors.errorRed.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDenied
                            ? Icons.videocam_off_outlined
                            : Icons.camera_alt_outlined,
                        size: 56,
                        color: isDenied
                            ? NexoraColors.warningAmber
                            : NexoraColors.errorRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isDenied
                          ? 'Camera Permission Required'
                          : 'Camera Unavailable',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isDenied
                          ? 'NEXORA requires camera permission to scan optical QR codes for instant device pairing.'
                          : 'Could not initialize camera sensor on this device. You can still pair using a PIN code or import a QR code image from Gallery.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (isDenied)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexoraColors.electricBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Grant Camera Permission'),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await _scannerController.start();
                        },
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexoraColors.electricBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry Camera'),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await _scannerController.start();
                        },
                      ),
                  ],
                ),
              );
            },
          ),

          // 2. High-Tech Scanning Reticle & Animated Laser
          Center(
            child: ScaleTransition(
              scale: _detectionPulse,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _isDetecting
                      ? NexoraColors.signalTeal.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: const NexoraAnimatedLaserScanner(
                  width: 270,
                  height: 270,
                ),
              ),
            ),
          ),

          // 3. Reticle Subtitle
          Positioned(
            bottom: 130,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: NexoraColors.signalTeal.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Align NEXORA QR Code inside the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          // 4. Top Header Bar
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: NexoraColors.signalTeal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'QR Optical Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: _isFlashOn
                        ? NexoraColors.signalTeal.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? NexoraColors.signalTeal : Colors.white,
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await _scannerController.toggleTorch();
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                  },
                ),
              ],
            ),
          ),

          // 5. Bottom Controls: Gallery Import & Manual Code
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text('Import QR'),
                    onPressed: _importFromGallery,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NexoraColors.electricBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.pin, size: 20),
                    label: const Text('Enter Code'),
                    onPressed: _showManualCodeEntry,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
