import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class VideoService {
  static final VideoService _instance = VideoService._internal();
  factory VideoService() => _instance;
  VideoService._internal();

  /// Video dosyası mı kontrol et
  bool isVideoFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp', '.m4v'].contains(extension);
  }

  /// Video bilgilerini al (temel bilgiler)
  Future<VideoInfo?> getVideoInfo(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) return null;
      
      final fileSize = await file.length();
      
      // Temel video bilgilerini döndür
      return VideoInfo(
        path: videoPath,
        duration: null, // Video metadata okuma özelliği yok
        width: null,    // Video metadata okuma özelliği yok
        height: null,
        bitrate: null,  // Video metadata okuma özelliği yok
        fileSize: fileSize,
      );
      
    } catch (e) {
      developer.log('Video bilgisi alma hatası: $e');
      return null;
    }
  }

  /// Dosya boyutunu formatla
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Video için Dogu formatında dosya adı oluştur
  String generateDoguVideoFileName(String originalPath) {
    final extension = path.extension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Dogu_Video_$timestamp$extension';
  }

  /// Video'yu geçici dizine kopyala (Dogu formatında)
  Future<String?> copyVideoToCache(String originalPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final newFileName = generateDoguVideoFileName(originalPath);
      final newPath = path.join(tempDir.path, newFileName);
      
      final originalFile = File(originalPath);
      final newFile = await originalFile.copy(newPath);
      
      developer.log('Video cache\'e kopyalandı: $newFileName');
      return newFile.path;
      
    } catch (e) {
      developer.log('Video kopyalama hatası: $e');
      return null;
    }
  }

  /// Video önizleme bilgilerini al
  Future<VideoPreviewInfo> getVideoPreviewInfo(String videoPath) async {
    try {
      final file = File(videoPath);
      final fileSize = await file.length();
      final fileName = path.basename(videoPath);
      final doguFileName = generateDoguVideoFileName(videoPath);
      
      return VideoPreviewInfo(
        originalPath: videoPath,
        fileName: fileName,
        doguFileName: doguFileName,
        fileSize: fileSize,
        formattedFileSize: formatFileSize(fileSize),
        thumbnailPath: null, // Thumbnail özelliği şimdilik yok
        isValid: true,
      );
      
    } catch (e) {
      developer.log('Video önizleme bilgisi alma hatası: $e');
      return VideoPreviewInfo(
        originalPath: videoPath,
        fileName: path.basename(videoPath),
        doguFileName: generateDoguVideoFileName(videoPath),
        fileSize: 0,
        formattedFileSize: '0 B',
        thumbnailPath: null,
        isValid: false,
      );
    }
  }

  /// Cache temizleme
  Future<void> clearVideoCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final videoFiles = tempDir.listSync().where(
        (entity) => entity is File && entity.path.contains('Dogu_Video_')
      );
      
      for (final file in videoFiles) {
        await file.delete();
      }
      
      developer.log('Video cache temizlendi');
    } catch (e) {
      developer.log('Video cache temizleme hatası: $e');
    }
  }

  Future<String> renameToDoguFormat(String originalPath) async {
    try {
      final file = File(originalPath);
      if (!await file.exists()) return originalPath;
      
      final directory = file.parent;
      final extension = path.extension(originalPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newName = 'Dogu_Video_$timestamp$extension';
      final newPath = path.join(directory.path, newName);
      
      final renamedFile = await file.copy(newPath);
      await file.delete(); // Delete original
      
      return renamedFile.path;
    } catch (e) {
      debugPrint('Video yeniden adlandırma hatası: $e');
      return originalPath;
    }
  }
}

/// Video bilgi modeli (basitleştirilmiş)
class VideoInfo {
  final String path;
  final int? duration; // seconds
  final int? width;
  final int? height;
  final int? bitrate; // bps
  final int fileSize; // bytes

  VideoInfo({
    required this.path,
    this.duration,
    this.width,
    this.height,
    this.bitrate,
    required this.fileSize,
  });

  String get formattedDuration {
    if (duration == null) return 'Bilinmiyor';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedResolution {
    if (width == null || height == null) return 'Bilinmiyor';
    return '${width}x$height';
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get formattedBitrate {
    if (bitrate == null) return 'Bilinmiyor';
    if (bitrate! < 1000000) return '${(bitrate! / 1000).toStringAsFixed(0)} kbps';
    return '${(bitrate! / 1000000).toStringAsFixed(1)} Mbps';
  }
}

/// Video önizleme bilgisi
class VideoPreviewInfo {
  final String originalPath;
  final String fileName;
  final String doguFileName;
  final int fileSize;
  final String formattedFileSize;
  final String? thumbnailPath;
  final bool isValid;

  VideoPreviewInfo({
    required this.originalPath,
    required this.fileName,
    required this.doguFileName,
    required this.fileSize,
    required this.formattedFileSize,
    this.thumbnailPath,
    required this.isValid,
  });
} 