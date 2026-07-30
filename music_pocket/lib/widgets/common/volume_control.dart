import 'package:flutter/material.dart';

import '../../services/audio_player_service.dart';

class VolumeControl extends StatelessWidget {
  const VolumeControl({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audioService = AudioPlayerService.instance;

    return StreamBuilder<double>(
      stream: audioService.volumeStream,
      initialData: audioService.volume,
      builder: (context, snapshot) {
        final volume = snapshot.data?.clamp(0.0, 1.0) ?? 1.0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _volumeIcon(volume),
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
            SizedBox(
              width: 80,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor: theme.colorScheme.outline.withAlpha(50),
                  thumbColor: theme.colorScheme.primary,
                  overlayColor: theme.colorScheme.primary.withAlpha(30),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 4),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 8),
                ),
                child: Slider(
                  value: volume,
                  onChanged: (v) => audioService.setVolume(v),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _volumeIcon(double volume) {
    if (volume <= 0) return Icons.volume_off_rounded;
    if (volume < 0.5) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }
}
