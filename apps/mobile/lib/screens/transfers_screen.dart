import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_model.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTransfers = ref.watch(activeTransfersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: activeTransfers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No active transfers',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Incoming and outgoing file streams will appear here.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeTransfers.length,
              itemBuilder: (context, index) {
                final t = activeTransfers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: t.direction == TransferDirection.send
                                  ? NexoraColors.electricBlue.withValues(alpha: 0.15)
                                  : NexoraColors.signalTeal.withValues(alpha: 0.15),
                              child: Icon(
                                t.direction == TransferDirection.send
                                    ? Icons.upload
                                    : Icons.download,
                                color: t.direction == TransferDirection.send
                                    ? NexoraColors.electricBlue
                                    : NexoraColors.signalTeal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.remoteDeviceName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    t.currentFile.isEmpty ? 'Preparing transfer...' : t.currentFile,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              t.formattedSpeed,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: t.progressPercentage,
                          color: NexoraColors.electricBlue,
                          backgroundColor: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(t.progressPercentage * 100).toStringAsFixed(1)}% • ETA: ${t.etaSeconds}s',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.pause, size: 20),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
