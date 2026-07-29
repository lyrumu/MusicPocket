import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final List<String> _selectedPaths = [];
  bool _isImporting = false;
  int _currentIndex = 0;
  int _totalCount = 0;
  String? _currentFileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入音乐'),
        actions: [
          if (_selectedPaths.isNotEmpty && !_isImporting)
            TextButton(
              onPressed: _importFiles,
              child: Text('导入 (${_selectedPaths.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildImportOptions(),
          if (_isImporting) _buildProgress(),
          Expanded(
            child: _selectedPaths.isEmpty
                ? _buildEmptyState()
                : _buildFileList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildOptionCard(
              icon: Icons.file_open,
              title: '选择文件',
              subtitle: '选择音频文件',
              onTap: _isImporting ? null : _pickFiles,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOptionCard(
              icon: Icons.folder,
              title: '选择文件夹',
              subtitle: '扫描整个文件夹',
              onTap: _isImporting ? null : _pickFolder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final progress = _totalCount > 0 ? _currentIndex / _totalCount : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('正在导入 $_currentIndex / $_totalCount'),
          const SizedBox(height: 4),
          if (_currentFileName != null)
            Text(
              _currentFileName!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.audio_file_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('尚未选择文件', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            '支持 MP3, FLAC, WAV, OGG, M4A 等格式',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedPaths.length,
      itemBuilder: (context, index) {
        final path = _selectedPaths[index];
        final name = path.split(Platform.pathSeparator).last;
        return ListTile(
          leading: const Icon(Icons.music_note),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            path,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: _isImporting
              ? null
              : IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      _selectedPaths.removeAt(index);
                    });
                  },
                ),
        );
      },
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: const [
          'mp3',
          'flac',
          'wav',
          'ogg',
          'm4a',
          'aac',
          'wma',
          'opus',
        ],
      );

      if (result == null) return;
      final paths = result.files
          .map((f) => f.path)
          .whereType<String>()
          .toSet()
          .toList();
      _addPaths(paths);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件失败：$e')),
      );
    }
  }

  Future<void> _pickFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) return;

      final dir = Directory(result);
      if (!await dir.exists()) return;

      const audioExtensions = {
        'mp3',
        'flac',
        'wav',
        'ogg',
        'm4a',
        'aac',
        'wma',
        'opus',
      };

      final files = <String>[];
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final name = entity.path.toLowerCase();
        final matched = audioExtensions
            .where((ext) => name.endsWith('.$ext'))
            .isNotEmpty;
        if (matched) {
          files.add(entity.path);
        }
      }
      _addPaths(files);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件夹失败：$e')),
      );
    }
  }

  void _addPaths(List<String> paths) {
    setState(() {
      final existing = _selectedPaths.toSet();
      for (final p in paths) {
        if (!existing.contains(p)) {
          _selectedPaths.add(p);
        }
      }
    });
  }

  Future<void> _importFiles() async {
    final repo = ref.read(trackRepositoryProvider);
    final paths = List<String>.from(_selectedPaths);
    setState(() {
      _isImporting = true;
      _currentIndex = 0;
      _totalCount = paths.length;
      _currentFileName = null;
    });

    var success = 0;
    var skipped = 0;
    var failed = 0;

    for (final sourcePath in paths) {
      if (!mounted) break;
      final name = sourcePath.split(Platform.pathSeparator).last;
      setState(() {
        _currentFileName = name;
      });

      try {
        final result = await repo.importPath(sourcePath);
        if (result.skipped) {
          skipped++;
        } else {
          success++;
        }
      } catch (e) {
        failed++;
      }

      if (!mounted) break;
      setState(() {
        _currentIndex++;
      });
    }

    if (!mounted) return;

    setState(() {
      _isImporting = false;
      _selectedPaths.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('导入完成：成功 $success，跳过 $skipped，失败 $failed')),
    );

    if (success > 0 || failed == 0) {
      Navigator.of(context).pop();
    }
  }
}
