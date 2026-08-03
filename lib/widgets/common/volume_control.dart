import 'package:flutter/material.dart';

import '../../services/audio_player_service.dart';

class VolumeControl extends StatelessWidget {
  final bool compact;

  const VolumeControl({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;
    return StreamBuilder<double>(
      stream: audioService.volumeStream,
      initialData: audioService.volume,
      builder: (context, snapshot) {
        final volume = snapshot.data?.clamp(0.0, 1.0) ?? 1.0;
        if (compact) {
          return IconButton(
            tooltip: '音量',
            icon: Icon(_volumeIcon(volume)),
            onPressed: () => _showVolumeSheet(context),
          );
        }
        return _buildSlider(context, volume, audioService);
      },
    );
  }

  Widget _buildSlider(
    BuildContext context,
    double volume,
    AudioPlayerService audioService,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _volumeIcon(volume),
          size: 19,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        SizedBox(
          width: 88,
          child: Slider(value: volume, onChanged: audioService.setVolume),
        ),
      ],
    );
  }

  void _showVolumeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('音量', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const VolumeControl(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _volumeIcon(double volume) {
    if (volume <= 0) return Icons.volume_off_rounded;
    if (volume < 0.5) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }
}
