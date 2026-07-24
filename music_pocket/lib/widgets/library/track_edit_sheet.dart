import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../common/cover_placeholder.dart';

class TrackEditSheet extends ConsumerStatefulWidget {
  final Track track;

  const TrackEditSheet({super.key, required this.track});

  @override
  ConsumerState<TrackEditSheet> createState() => _TrackEditSheetState();

  static Future<void> show(BuildContext context, Track track) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: TrackEditSheet(track: track),
      ),
    );
  }
}

class _TrackEditSheetState extends ConsumerState<TrackEditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _artistCtrl;
  late final TextEditingController _albumCtrl;
  late final TextEditingController _genreCtrl;
  late final TextEditingController _yearCtrl;
  String? _coverPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.track.title);
    _artistCtrl = TextEditingController(text: widget.track.artist);
    _albumCtrl = TextEditingController(text: widget.track.album);
    _genreCtrl = TextEditingController(text: widget.track.genre);
    _yearCtrl = TextEditingController(
      text: widget.track.year?.toString() ?? '',
    );
    _coverPath = widget.track.coverPath;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    _genreCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCustomCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null) return;
    final path = result.files.first.path;
    if (path == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(trackRepositoryProvider);
      final stored = await repo.saveCustomCoverFile(path);
      await repo.setCustomCover(widget.track.id, stored);
      if (!mounted) return;
      setState(() => _coverPath = stored);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearCustomCover() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(trackRepositoryProvider)
          .setCustomCover(widget.track.id, null);
      if (!mounted) return;
      setState(() => _coverPath = null);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final artist = _artistCtrl.text.trim();
    final album = _albumCtrl.text.trim();
    final genre = _genreCtrl.text.trim();
    final yearStr = _yearCtrl.text.trim();
    final year = yearStr.isEmpty ? null : int.tryParse(yearStr);

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('标题不能为空')));
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(trackRepositoryProvider);
    await repo.editTrackMetadata(
      widget.track.id,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      year: year,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除歌曲'),
        content: const Text('确定要从资料库中移除这首歌曲吗？\n原始音频文件不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(trackRepositoryProvider).deleteTrack(widget.track.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('编辑歌曲', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                CoverImage(
                  coverPath: _coverPath,
                  seed: _titleCtrl.text,
                  size: 96,
                  radius: 12,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _saving ? null : _pickCustomCover,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('更改封面'),
                      ),
                      const SizedBox(height: 8),
                      if (_coverPath != null && _coverPath!.isNotEmpty)
                        TextButton.icon(
                          onPressed: _saving ? null : _clearCustomCover,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('移除自定义封面'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field('标题', _titleCtrl),
            _field('艺术家', _artistCtrl),
            _field('专辑', _albumCtrl),
            _field('流派', _genreCtrl),
            _field('年份', _yearCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        enabled: !_saving,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
