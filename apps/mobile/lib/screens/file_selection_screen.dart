import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../theme/nexora_theme.dart';
import 'transfer_confirmation_screen.dart';

enum FileCategory { all, images, videos, audio, documents, downloads, folders }

class SelectedFileItem {
  final File file;
  final String name;
  final int size;
  final FileCategory category;
  bool isSelected;

  SelectedFileItem({
    required this.file,
    required this.name,
    required this.size,
    required this.category,
    this.isSelected = true,
  });
}

class FileSelectionScreen extends ConsumerStatefulWidget {
  final NexoraDevice targetPeer;
  final List<File>? initialFiles;

  const FileSelectionScreen({
    super.key,
    required this.targetPeer,
    this.initialFiles,
  });

  @override
  ConsumerState<FileSelectionScreen> createState() =>
      _FileSelectionScreenState();
}

class _FileSelectionScreenState extends ConsumerState<FileSelectionScreen> {
  final List<SelectedFileItem> _items = [];
  bool _isGridView = false;
  FileCategory _activeCategory = FileCategory.all;

  @override
  void initState() {
    super.initState();
    if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
      for (final f in widget.initialFiles!) {
        _addFileToStaging(f);
      }
    }
  }

  FileCategory _detectCategory(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return FileCategory.images;
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm')) {
      return FileCategory.videos;
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac')) {
      return FileCategory.audio;
    }
    if (lower.endsWith('.pdf') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.xlsx')) {
      return FileCategory.documents;
    }
    if (lower.contains('download')) {
      return FileCategory.downloads;
    }
    return FileCategory.all;
  }

  void _addFileToStaging(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    if (_items.any((item) => item.file.path == file.path)) return;

    int size = 0;
    try {
      size = file.lengthSync();
    } catch (_) {
      size = 1024 * 512;
    }

    final cat = _detectCategory(file.path);
    _items.add(
      SelectedFileItem(
        file: file,
        name: name,
        size: size,
        category: cat,
        isSelected: true,
      ),
    );
  }

  Future<void> _pickFiles() async {
    HapticFeedback.lightImpact();
    final files = await FilePicker.pickFiles(type: FileType.any);

    if (files.isNotEmpty) {
      setState(() {
        for (final p in files) {
          if (p.path != null) {
            _addFileToStaging(File(p.path!));
          }
        }
      });
    }
  }

  Future<void> _pickFolder() async {
    HapticFeedback.lightImpact();
    final folderPath = await FilePicker.getDirectoryPath();
    if (folderPath != null) {
      final dir = Directory(folderPath);
      try {
        final entities = await dir.list(recursive: false).toList();
        setState(() {
          for (final entity in entities) {
            if (entity is File) {
              _addFileToStaging(entity);
            }
          }
        });
      } catch (_) {}
    }
  }

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

  IconData _getCategoryIcon(FileCategory cat) {
    switch (cat) {
      case FileCategory.images:
        return Icons.image_outlined;
      case FileCategory.videos:
        return Icons.videocam_outlined;
      case FileCategory.audio:
        return Icons.audiotrack_outlined;
      case FileCategory.documents:
        return Icons.description_outlined;
      case FileCategory.downloads:
        return Icons.download_outlined;
      case FileCategory.folders:
        return Icons.folder_outlined;
      case FileCategory.all:
        return Icons.insert_drive_file_outlined;
    }
  }

  List<SelectedFileItem> get _filteredItems {
    if (_activeCategory == FileCategory.all) return _items;
    return _items.where((i) => i.category == _activeCategory).toList();
  }

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  int get _selectedTotalBytes =>
      _items.where((i) => i.isSelected).fold<int>(0, (sum, i) => sum + i.size);

  void _proceedToReview() {
    final selectedFiles = _items
        .where((i) => i.isSelected)
        .map((i) => i.file)
        .toList();

    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file to send.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransferConfirmationScreen(
          targetPeer: widget.targetPeer,
          files: selectedFiles,
          totalBytes: _selectedTotalBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Files to Send',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'To: ${widget.targetPeer.displayName} (${widget.targetPeer.platform})',
              style: TextStyle(
                fontSize: 12,
                color: NexoraColors.signalTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isGridView
                ? 'Switch to List View'
                : 'Switch to Grid View',
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: FileCategory.values.map((cat) {
                final isSelected = _activeCategory == cat;
                final label = cat.name.toUpperCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700),
                      ),
                    ),
                    selectedColor: NexoraColors.electricBlue,
                    backgroundColor: isDark
                        ? NexoraColors.darkSurfaceVariant
                        : const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.white,
                    onSelected: (_) {
                      setState(() {
                        _activeCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // File List / Grid or Empty State
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: NexoraColors.electricBlue.withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.folder_open,
                              size: 48,
                              color: NexoraColors.electricBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Files Staged Yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Add Files" or "Add Folder" below to pick photos, videos, documents, or archives from your storage.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Files'),
                                onPressed: _pickFiles,
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.create_new_folder_outlined,
                                  size: 18,
                                ),
                                label: const Text('Add Folder'),
                                onPressed: _pickFolder,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : _isGridView
                ? GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildGridCard(item, isDark);
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildListItem(item, isDark);
                    },
                  ),
          ),

          // Floating Bottom Selection Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? NexoraColors.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? NexoraColors.darkBorder
                      : NexoraColors.lightBorder,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Quick add icons
                  IconButton(
                    tooltip: 'Add Files',
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: NexoraColors.electricBlue,
                    ),
                    onPressed: _pickFiles,
                  ),
                  IconButton(
                    tooltip: 'Add Entire Folder',
                    icon: const Icon(
                      Icons.folder_open,
                      color: NexoraColors.signalTeal,
                    ),
                    onPressed: _pickFolder,
                  ),
                  const SizedBox(width: 8),

                  // Selection counter
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_selectedCount files selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _formatBytes(_selectedTotalBytes),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Proceed to Review & Send Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NexoraColors.electricBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Review & Send'),
                    onPressed: _selectedCount > 0 ? _proceedToReview : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(SelectedFileItem item, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: NexoraColors.electricBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getCategoryIcon(item.category),
            color: NexoraColors.electricBlue,
          ),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          _formatBytes(item.size),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: Checkbox(
          value: item.isSelected,
          activeColor: NexoraColors.signalTeal,
          onChanged: (val) {
            setState(() {
              item.isSelected = val ?? false;
            });
          },
        ),
      ),
    );
  }

  Widget _buildGridCard(SelectedFileItem item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? NexoraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isSelected
              ? NexoraColors.signalTeal
              : (isDark ? NexoraColors.darkBorder : NexoraColors.lightBorder),
          width: item.isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            item.isSelected = !item.isSelected;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: item.isSelected,
                    activeColor: NexoraColors.signalTeal,
                    onChanged: (val) {
                      setState(() {
                        item.isSelected = val ?? false;
                      });
                    },
                  ),
                ),
              ),
              Icon(
                _getCategoryIcon(item.category),
                size: 34,
                color: NexoraColors.electricBlue,
              ),
              Column(
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatBytes(item.size),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
