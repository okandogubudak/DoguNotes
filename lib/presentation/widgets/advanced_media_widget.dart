import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'full_screen_image_viewer.dart';
import '../../core/services/video_service.dart';
import '../../core/services/image_compression_service.dart';

class AdvancedMediaWidget extends StatefulWidget {
  final List<String> mediaPaths;
  final Function(List<String>) onMediaReordered;
  final Function(String) onMediaDeleted;
  final bool showFileSize;
  final bool enableDragDrop;
  final bool enableLazyLoading;

  const AdvancedMediaWidget({
    super.key,
    required this.mediaPaths,
    required this.onMediaReordered,
    required this.onMediaDeleted,
    this.showFileSize = true,
    this.enableDragDrop = true,
    this.enableLazyLoading = true,
  });

  @override
  State<AdvancedMediaWidget> createState() => _AdvancedMediaWidgetState();
}

class _AdvancedMediaWidgetState extends State<AdvancedMediaWidget> {
  final Map<String, int?> _fileSizes = {};
  final VideoService _videoService = VideoService();
  final ImageCompressionService _imageService = ImageCompressionService();
  final Set<String> _visibleItems = {};

  @override
  void initState() {
    super.initState();
    _loadMediaInfo();
  }

  Future<void> _loadMediaInfo() async {
    for (final mediaPath in widget.mediaPaths) {
      await _loadFileInfo(mediaPath);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        _fileSizes[filePath] = await file.length();
      }
    } catch (e) {
      debugPrint('Dosya bilgisi yükleme hatası: $e');
    }
  }

  bool _isVideoFile(String filePath) {
    return _videoService.isVideoFile(filePath);
  }

  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  bool _isAudioFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.mp3', '.wav', '.aac', '.m4a', '.ogg'].contains(extension);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getDoguFileName(String originalPath) {
    final extension = path.extension(originalPath);
    final mediaType = _isVideoFile(originalPath) ? 'Video' : 
                      _isImageFile(originalPath) ? 'Image' : 
                      _isAudioFile(originalPath) ? 'Audio' : 'File';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Dogu_${mediaType}_$timestamp$extension';
  }

  IconData _getMediaIcon(String mediaPath) {
    if (_isVideoFile(mediaPath)) return Icons.play_circle;
    if (_isImageFile(mediaPath)) return Icons.image;
    if (_isAudioFile(mediaPath)) return Icons.audiotrack;
    return Icons.insert_drive_file;
  }

  Color _getMediaColor(String mediaPath) {
    if (_isVideoFile(mediaPath)) return Colors.red;
    if (_isImageFile(mediaPath)) return Colors.blue;
    if (_isAudioFile(mediaPath)) return Colors.green;
    return Colors.grey;
  }

  void _showMediaOptions(String mediaPath) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // File info
            Row(
              children: [
                Icon(
                  _getMediaIcon(mediaPath),
                  color: _getMediaColor(mediaPath),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDoguFileName(mediaPath),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.showFileSize && _fileSizes[mediaPath] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Boyut: ${_formatFileSize(_fileSizes[mediaPath]!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            if (_isImageFile(mediaPath))
              ListTile(
                leading: const Icon(Icons.fullscreen, color: Colors.blue),
                title: const Text('Tam Ekran Görünüm'),
                onTap: () {
                  Navigator.pop(context);
                  _viewFullScreenImage(mediaPath);
                },
              ),
            
            if (_isVideoFile(mediaPath))
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.red),
                title: const Text('Video Bilgileri'),
                onTap: () {
                  Navigator.pop(context);
                  _showVideoInfo(mediaPath);
                },
              ),
            

            
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(mediaPath);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoInfo(String videoPath) async {
    final videoInfo = await _videoService.getVideoInfo(videoPath);
    if (videoInfo != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Video Bilgileri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Dosya Adı', path.basename(videoPath)),
              _buildInfoRow('Dogu Adı', _getDoguFileName(videoPath)),
              _buildInfoRow('Dosya Boyutu', videoInfo.formattedFileSize),
              _buildInfoRow('Süre', videoInfo.formattedDuration),
              _buildInfoRow('Çözünürlük', videoInfo.formattedResolution),
              _buildInfoRow('Bitrate', videoInfo.formattedBitrate),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }



  void _confirmDelete(String mediaPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medya Dosyasını Sil'),
        content: Text('${_getDoguFileName(mediaPath)} dosyasını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onMediaDeleted(mediaPath);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(String mediaPath, int index) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Medya içeriği
            _buildMediaContent(mediaPath),
            
            // Medya tipi ikonu
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getMediaColor(mediaPath).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getMediaIcon(mediaPath),
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            
            // Dosya boyutu
            if (widget.showFileSize && _fileSizes[mediaPath] != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatFileSize(_fileSizes[mediaPath]!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            // Drag handle (if enabled)
            if (widget.enableDragDrop)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            
            // Options button
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showMediaOptions(mediaPath),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            
            // Long press for reorder
            if (widget.enableDragDrop)
              Positioned.fill(
                child: GestureDetector(
                  onLongPress: () => _startReorder(index),
                  child: Container(color: Colors.transparent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(String mediaPath) {
    if (_isImageFile(mediaPath)) {
      return _buildImageThumbnail(mediaPath);
    } else {
      return _buildGenericThumbnail(mediaPath);
    }
  }

  Widget _buildImageThumbnail(String imagePath) {
    return GestureDetector(
      onTap: () => _viewFullScreenImage(imagePath),
      child: Hero(
        tag: 'media_$imagePath',
        child: Image.file(
          File(imagePath),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenericThumbnail(String filePath) {
    return GestureDetector(
      onTap: () => _showMediaOptions(filePath),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: _getMediaColor(filePath).withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getMediaIcon(filePath),
              color: _getMediaColor(filePath),
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              path.extension(filePath).toUpperCase().replaceFirst('.', ''),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getMediaColor(filePath),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewFullScreenImage(String imagePath) {
    final imageFiles = widget.mediaPaths.where(_isImageFile).toList();
    final initialIndex = imageFiles.indexOf(imagePath);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: imageFiles,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
          heroTag: 'media_$imagePath',
        ),
      ),
    );
  }

  void _startReorder(int index) {
    // Basit drag & drop için feedback
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sıralama özelliği yakında!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaPaths.isEmpty) {
      return const Center(
        child: Text(
          'Medya dosyası bulunmuyor',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (widget.enableDragDrop) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.mediaPaths.length,
        onReorder: (int oldIndex, int newIndex) {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final newOrder = List<String>.from(widget.mediaPaths);
          final item = newOrder.removeAt(oldIndex);
          newOrder.insert(newIndex, item);
          widget.onMediaReordered(newOrder);
        },
        itemBuilder: (context, index) {
          return _buildDraggableMediaItem(widget.mediaPaths[index], index);
        },
      );
    } else {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.mediaPaths.asMap().entries.map((entry) {
          return _buildMediaItem(entry.value, entry.key);
        }).toList(),
      );
    }
  }

  Widget _buildDraggableMediaItem(String mediaPath, int index) {
    return Container(
      key: ValueKey(mediaPath),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Medya içeriği
            SizedBox(
              width: 100,
              height: 100,
              child: _buildMediaContent(mediaPath),
            ),
            
            // Drag handle (always visible for drag items)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.drag_handle,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            
            // Medya tipi ikonu
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getMediaColor(mediaPath).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getMediaIcon(mediaPath),
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            
            // Dosya boyutu
            if (widget.showFileSize && _fileSizes[mediaPath] != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatFileSize(_fileSizes[mediaPath]!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            // Options button
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showMediaOptions(mediaPath),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 