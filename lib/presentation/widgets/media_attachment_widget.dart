import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';
import '../../core/constants/app_constants.dart';
import 'full_screen_image_viewer.dart';
import 'advanced_media_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dogunotes/presentation/widgets/full_screen_video_viewer.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

class MediaAttachmentWidget extends StatefulWidget {
  final List<String> attachments;
  final Function(String)? onRemoveAttachment;
  final Function(String)? onAddAttachment;
  final Function(List<String>)? onReorderAttachments;

  const MediaAttachmentWidget({
    super.key,
    required this.attachments,
    this.onRemoveAttachment,
    this.onAddAttachment,
    this.onReorderAttachments,
  });

  @override
  State<MediaAttachmentWidget> createState() => _MediaAttachmentWidgetState();
}

class _MediaAttachmentWidgetState extends State<MediaAttachmentWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  String? _currentPlayingPath;
  bool _isEditMode = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onMediaReordered(List<String> newOrder) {
    widget.onReorderAttachments?.call(newOrder);
  }

  void _onMediaDeleted(String mediaPath) {
    widget.onRemoveAttachment?.call(mediaPath);
  }

  void _openFullScreenImage(int index) {
    // Get only image files
    final imageFiles = widget.attachments.where((path) => _isImageFile(path)).toList();
    final imageIndex = widget.attachments.take(index + 1).where((path) => _isImageFile(path)).length - 1;
    
    if (imageFiles.isNotEmpty && imageIndex >= 0) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => FullScreenImageViewer(
            imagePaths: imageFiles,
            initialIndex: imageIndex.clamp(0, imageFiles.length - 1),
            heroTag: 'image_$index',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  bool _isVideoFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv', '.webm'].contains(extension);
  }

  bool _isAudioFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a'].contains(extension);
  }

  bool _isPdfFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.pdf';
  }

  String _getDisplayName(String filePath) {
    final fileName = path.basename(filePath);
    if (fileName.startsWith('DG_')) {
      final parts = fileName.split('_');
      if (parts.length >= 3) {
        final number = parts[1];
        final type = parts[2].split('.')[0];
        
        switch (type) {
          case 'pic':
            return 'Fotoğraf $number';
          case 'vid':
            return 'Video $number';
          case 'aud':
            return 'Ses $number';
          default:
            return fileName;
        }
      }
    }
    return fileName;
  }

  void _openFile(String filePath) async {
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $filePath');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAttachments = widget.attachments.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.attach_file,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ekler ($totalAttachments)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (totalAttachments > 0)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode;
                    });
                  },
                  icon: Icon(
                    _isEditMode ? Icons.done : Icons.edit,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: _isEditMode ? 'Düzenlemeyi bitir' : 'Düzenle',
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Tüm ekler (görsel, video, ses, belge)
          if (widget.attachments.isNotEmpty) ...[
            Column(
              children: widget.attachments.map((filePath) => _buildUniversalMediaCard(filePath, theme)).toList(),
            ),
          ],
          
          // Boş durum
          if (totalAttachments == 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Henüz medya eklenmedi',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fotoğraf, video veya ses dosyası ekleyin',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUniversalMediaCard(String filePath, ThemeData theme) {
    final displayName = _getDisplayName(filePath);
    final isImage = _isImageFile(filePath);
    final isVideo = _isVideoFile(filePath);
    final isAudio = _isAudioFile(filePath);
    final isPdf = _isPdfFile(filePath);
    final file = File(filePath);
    final fileSize = file.existsSync() ? file.lengthSync() : 0;
    final fileSizeText = _formatFileSize(fileSize);
    final isPlaying = _isPlayingAudio && _currentPlayingPath == filePath;

    return Card(
      color: isImage
          ? Colors.blue.withOpacity(0.1)
          : isVideo
              ? Colors.green.withOpacity(0.1)
              : isAudio
                  ? Colors.orange.withOpacity(0.1)
                  : isPdf
                      ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isImage
                ? Colors.blue.withOpacity(0.2)
                : isVideo
                    ? Colors.green.withOpacity(0.2)
                    : isAudio
                        ? Colors.orange.withOpacity(0.2)
                        : isPdf
                            ? Colors.red.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: isImage
              ? ClipOval(
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  ),
                )
              : isVideo
                  ? const Icon(Icons.videocam_rounded, color: Colors.green, size: 24)
                  : isAudio
                      ? Icon(isPlaying ? Icons.volume_up : Icons.audiotrack, color: Colors.orange)
                      : isPdf
                          ? const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24)
                      : const Icon(Icons.insert_drive_file_rounded, color: Colors.grey, size: 24),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(fileSizeText),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAudio)
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.orange,
                  size: 28,
                ),
                onPressed: () => _toggleAudioPlayback(filePath),
              ),
              IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => widget.onRemoveAttachment?.call(filePath),
              ),
          ],
        ),
        onTap: () {
          OpenFilex.open(filePath);
        },
      ),
    );
  }

  Future<void> _toggleAudioPlayback(String audioPath) async {
    try {
      if (_isPlayingAudio && _currentPlayingPath == audioPath) {
        await _audioPlayer.stop();
        setState(() {
          _isPlayingAudio = false;
          _currentPlayingPath = null;
        });
      } else {
        if (_isPlayingAudio) {
          await _audioPlayer.stop();
        }
        await _audioPlayer.play(DeviceFileSource(audioPath));
        setState(() {
          _isPlayingAudio = true;
          _currentPlayingPath = audioPath;
        });
      }
    } catch (e) {
      debugPrint('Ses çalma hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ses dosyası çalınamadı: $e')),
      );
    }
  }

  Future<void> _openPdfFile(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF dosyası bulunamadı')),
        );
        return;
      }

      // PDF dosyasını sistem uygulaması ile aç
      final uri = Uri.file(pdfPath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF dosyası açılamadı')),
        );
      }
    } catch (e) {
      debugPrint('PDF açma hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF dosyası açılamadı: $e')),
      );
    }
  }

  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

// Video oynatıcı ekranı
class _VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const _VideoPlayerScreen({required this.videoPath});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
    _controller.addListener(() {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          path.basename(widget.videoPath),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    Align(
                      alignment: Alignment.center,
                      child: IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
} 