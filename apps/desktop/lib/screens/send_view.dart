import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';

class SendView extends ConsumerStatefulWidget {
  const SendView({super.key});

  @override
  ConsumerState<SendView> createState() => _SendViewState();
}

class _SendViewState extends ConsumerState<SendView> {
  final List<File> _stagedFiles = [];
  bool _isDragging = false;
  NexoraDevice? _selectedDevice;

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  Future<void> _pickFiles() async {
    final files = await FilePicker.pickFiles(type: FileType.any);

    if (files.isNotEmpty) {
      setState(() {
        for (final pFile in files) {
          if (pFile.path != null) {
            final f = File(pFile.path!);
            if (!_stagedFiles.any((existing) => existing.path == f.path)) {
              _stagedFiles.add(f);
            }
          }
        }
      });
    }
  }

  Future<void> _pickFolder() async {
    final folderPath = await FilePicker.getDirectoryPath();
    if (folderPath != null) {
      final dir = Directory(folderPath);
      final list = await dir.list(recursive: false).toList();
      setState(() {
        for (final entity in list) {
          if (entity is File &&
              !_stagedFiles.any((existing) => existing.path == entity.path)) {
            _stagedFiles.add(entity);
          }
        }
      });
    }
  }

  Future<void> _sendStagedFiles() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a target device to send to.'),
        ),
      );
      return;
    }

    if (_stagedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file to send.'),
        ),
      );
      return;
    }

    final controller = ref.read(networkControllerProvider);
    final target = _selectedDevice!;
    final filesToSend = List<File>.from(_stagedFiles);

    setState(() {
      _stagedFiles.clear();
    });

    ref.read(activeNavSectionProvider.notifier).state =
        DesktopNavSection.transfers;

    await controller.sendFiles(peer: target, files: filesToSend);
  }

  @override
  Widget build(BuildContext context) {
    final peers = ref.watch(discoveredPeersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Files',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Select target peer device and files to initiate peer-to-peer streaming.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Step 1: Select Target Device
            const Text(
              '1. Select Destination Device',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (peers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).cardTheme.color ??
                      NexoraColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No nearby NEXORA peers discovered. Ensure target phone or PC is connected to the same network.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).cardTheme.color ??
                      NexoraColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<NexoraDevice>(
                    isExpanded: true,
                    value:
                        _selectedDevice != null &&
                            peers.any(
                              (p) => p.deviceId == _selectedDevice!.deviceId,
                            )
                        ? peers.firstWhere(
                            (p) => p.deviceId == _selectedDevice!.deviceId,
                          )
                        : (peers.isNotEmpty ? peers.first : null),
                    hint: const Text('Select a nearby discovered device'),
                    onChanged: (device) {
                      setState(() {
                        _selectedDevice = device;
                      });
                    },
                    items: peers.map((p) {
                      final pLower = p.platform.toLowerCase();
                      final isAndroid = pLower.contains('android');
                      final isLinux = pLower.contains('linux');
                      final iconData = isAndroid
                          ? Icons.phone_android
                          : (isLinux ? Icons.terminal : Icons.laptop_windows);
                      final iconColor = isAndroid
                          ? NexoraColors.signalTeal
                          : (isLinux
                                ? Colors.purpleAccent
                                : NexoraColors.electricBlue);
                      return DropdownMenuItem<NexoraDevice>(
                        value: p,
                        child: Row(
                          children: [
                            Icon(iconData, color: iconColor, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '${p.displayName} (${p.platform} - ${p.address ?? "local"})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // Step 2: Drag-and-drop / File Pickers
            const Text(
              '2. Select Files to Send',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropTarget(
              onDragEntered: (detail) => setState(() => _isDragging = true),
              onDragExited: (detail) => setState(() => _isDragging = false),
              onDragDone: (detail) {
                setState(() {
                  _isDragging = false;
                  for (final xFile in detail.files) {
                    final f = File(xFile.path);
                    if (f.existsSync()) {
                      if (!_stagedFiles.any(
                        (existing) => existing.path == f.path,
                      )) {
                        _stagedFiles.add(f);
                      }
                    } else if (Directory(xFile.path).existsSync()) {
                      final dir = Directory(xFile.path);
                      for (final entity in dir.listSync(recursive: true)) {
                        if (entity is File &&
                            !_stagedFiles.any(
                              (existing) => existing.path == entity.path,
                            )) {
                          _stagedFiles.add(entity);
                        }
                      }
                    }
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: _isDragging
                      ? NexoraColors.electricBlue.withValues(alpha: 0.08)
                      : (Theme.of(context).cardTheme.color ??
                            NexoraColors.lightCard),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDragging
                        ? NexoraColors.signalTeal
                        : NexoraColors.electricBlue.withValues(alpha: 0.5),
                    width: _isDragging ? 2.5 : 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NexoraColors.electricBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: NexoraColors.electricBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Drop files or folders here to send',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Files stream directly with 1MB bounded chunking and SHA-256 verification',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NexoraColors.electricBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _pickFiles,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Browse Files'),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: NexoraColors.electricBlue,
                            side: const BorderSide(
                              color: NexoraColors.electricBlue,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _pickFolder,
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('Select Folder'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Staged Files Queue
            if (_stagedFiles.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Staged for Sending (${_stagedFiles.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _stagedFiles.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stagedFiles.length,
                itemBuilder: (context, index) {
                  final file = _stagedFiles[index];
                  final name = file.path.split(RegExp(r'[\\/]')).last;
                  final size = file.existsSync() ? file.lengthSync() : 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).cardTheme.color ??
                          NexoraColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file,
                          color: NexoraColors.electricBlue,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatBytes(size),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _stagedFiles.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NexoraColors.signalTeal,
                    foregroundColor: NexoraColors.midnightNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _sendStagedFiles,
                  icon: const Icon(Icons.send_rounded, size: 22),
                  label: Text(
                    'Send ${_stagedFiles.length} File(s) Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
