import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_model.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(transferHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear History',
              onPressed: () {
                ref.read(transferHistoryProvider.notifier).state = [];
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No transfer history',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Records of completed and verified transfers will be stored here.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.direction == TransferDirection.send
                          ? NexoraColors.electricBlue.withValues(alpha: 0.1)
                          : NexoraColors.signalTeal.withValues(alpha: 0.1),
                      child: Icon(
                        item.direction == TransferDirection.send ? Icons.upload : Icons.download,
                        color: item.direction == TransferDirection.send
                            ? NexoraColors.electricBlue
                            : NexoraColors.signalTeal,
                      ),
                    ),
                    title: Text(item.remoteDeviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.totalFiles} files • ${item.createdAt.toLocal().toString().split('.')[0]}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: NexoraColors.signalTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(color: NexoraColors.signalTeal, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
