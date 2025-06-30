import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AudioRecorderWidget extends StatelessWidget {
  final String? audioPath;
  final bool isRecording;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onDeleteAudio;
  final bool isPlaying;

  const AudioRecorderWidget({
    super.key,
    this.audioPath,
    this.isRecording = false,
    this.onStartRecording,
    this.onStopRecording,
    this.onPlayAudio,
    this.onDeleteAudio,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ses Kaydı',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (audioPath == null && !isRecording)
            // Record Button - Minimalist
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: IconButton(
                  onPressed: onStartRecording,
                  icon: const Icon(Icons.mic_rounded, size: 24),
                  color: theme.colorScheme.error,
                  tooltip: 'Ses Kaydet',
                ),
              ),
            )
          else if (isRecording)
            // Recording State
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kayıt ediliyor...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onStopRecording,
                  icon: const Icon(Icons.stop, size: 20),
                  label: const Text('Kaydı Durdur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          else if (audioPath != null)
            // Audio Player Controls
            Row(
              children: [
                // Play/Pause Button
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: onPlayAudio,
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Audio Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ses Kaydı',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isPlaying ? 'Oynatılıyor...' : 'Oynatmak için tıklayın',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Delete Button
                IconButton(
                  onPressed: onDeleteAudio,
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
} 