import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManagementService {
  static final CacheManagementService _instance = CacheManagementService._internal();
  factory CacheManagementService() => _instance;
  CacheManagementService._internal();

  // Cache dizinleri
  static const String _thumbnailCacheDir = 'thumbnails';
  static const String _videoCacheDir = 'videos';
  static const String _imageCacheDir = 'images';
  static const String _audioCacheDir = 'audio';
  static const String _exportCacheDir = 'exports';
  static const String _drawingCacheDir = 'drawings';

  // Cache ayarları
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500 MB
  static const int _maxCacheAge = 7 * 24 * 60 * 60 * 1000; // 7 gün
  static const String _lastCleanupKey = 'last_cache_cleanup';
  static const String _cacheStatsKey = 'cache_statistics';

  late Directory _cacheDirectory;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// Cache servisini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final tempDir = await getTemporaryDirectory();
      _cacheDirectory = Directory(path.join(tempDir.path, 'dogu_cache'));
      
      if (!await _cacheDirectory.exists()) {
        await _cacheDirectory.create(recursive: true);
      }

      _prefs = await SharedPreferences.getInstance();
      
      // Cache alt dizinlerini oluştur
      await _createCacheDirectories();
      
      // Otomatik temizlik kontrolü
      await _checkAutoCleanup();
      
      _isInitialized = true;
      developer.log('Cache Management Service başlatıldı');
      
    } catch (e) {
      developer.log('Cache Management Service başlatma hatası: $e');
    }
  }

  /// Cache alt dizinlerini oluştur
  Future<void> _createCacheDirectories() async {
    final dirs = [
      _thumbnailCacheDir,
      _videoCacheDir,
      _imageCacheDir,
      _audioCacheDir,
      _exportCacheDir,
      _drawingCacheDir,
    ];

    for (final dirName in dirs) {
      final dir = Directory(path.join(_cacheDirectory.path, dirName));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  /// Otomatik temizlik kontrolü
  Future<void> _checkAutoCleanup() async {
    final lastCleanup = _prefs.getInt(_lastCleanupKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 24 saatte bir otomatik temizlik
    if (now - lastCleanup > 24 * 60 * 60 * 1000) {
      await performAutoCleanup();
      await _prefs.setInt(_lastCleanupKey, now);
    }
  }

  /// Cache dosya yolu al
  String getCacheFilePath(String fileName, CacheCategory category) {
    String subDir;
    switch (category) {
      case CacheCategory.thumbnail:
        subDir = _thumbnailCacheDir;
        break;
      case CacheCategory.video:
        subDir = _videoCacheDir;
        break;
      case CacheCategory.image:
        subDir = _imageCacheDir;
        break;
      case CacheCategory.audio:
        subDir = _audioCacheDir;
        break;
      case CacheCategory.export:
        subDir = _exportCacheDir;
        break;
      case CacheCategory.drawing:
        subDir = _drawingCacheDir;
        break;
    }
    
    return path.join(_cacheDirectory.path, subDir, fileName);
  }

  /// Cache dosyası mevcut mu kontrol et
  Future<bool> isCacheFileExists(String fileName, CacheCategory category) async {
    final filePath = getCacheFilePath(fileName, category);
    return await File(filePath).exists();
  }

  /// Cache dosyasını al
  Future<File?> getCacheFile(String fileName, CacheCategory category) async {
    final filePath = getCacheFilePath(fileName, category);
    final file = File(filePath);
    
    if (await file.exists()) {
      // Son erişim zamanını güncelle
      await _updateFileAccessTime(file);
      return file;
    }
    
    return null;
  }

  /// Cache dosyasını kaydet
  Future<String?> saveCacheFile(
    List<int> bytes,
    String fileName,
    CacheCategory category,
  ) async {
    try {
      final filePath = getCacheFilePath(fileName, category);
      final file = File(filePath);
      
      await file.writeAsBytes(bytes);
      await _updateCacheStatistics(category, bytes.length);
      
      developer.log('Cache dosyası kaydedildi: $fileName');
      return filePath;
      
    } catch (e) {
      developer.log('Cache dosyası kaydetme hatası: $e');
      return null;
    }
  }

  /// Cache dosyasını sil
  Future<bool> deleteCacheFile(String fileName, CacheCategory category) async {
    try {
      final filePath = getCacheFilePath(fileName, category);
      final file = File(filePath);
      
      if (await file.exists()) {
        final size = await file.length();
        await file.delete();
        await _updateCacheStatistics(category, -size);
        developer.log('Cache dosyası silindi: $fileName');
        return true;
      }
      
      return false;
    } catch (e) {
      developer.log('Cache dosyası silme hatası: $e');
      return false;
    }
  }

  /// Dosya son erişim zamanını güncelle
  Future<void> _updateFileAccessTime(File file) async {
    try {
      // Dosyaya dokunarak access time'ı güncelle
      await file.setLastModified(DateTime.now());
    } catch (e) {
      developer.log('Access time güncelleme hatası: $e');
    }
  }

  /// Cache istatistiklerini güncelle
  Future<void> _updateCacheStatistics(CacheCategory category, int sizeChange) async {
    try {
      final stats = await getCacheStatistics();
      
      switch (category) {
        case CacheCategory.thumbnail:
          stats.thumbnailSize += sizeChange;
          break;
        case CacheCategory.video:
          stats.videoSize += sizeChange;
          break;
        case CacheCategory.image:
          stats.imageSize += sizeChange;
          break;
        case CacheCategory.audio:
          stats.audioSize += sizeChange;
          break;
        case CacheCategory.export:
          stats.exportSize += sizeChange;
          break;
        case CacheCategory.drawing:
          stats.drawingSize += sizeChange;
          break;
      }
      
      stats.totalSize += sizeChange;
      stats.lastUpdated = DateTime.now();
      
      await _saveCacheStatistics(stats);
      
    } catch (e) {
      developer.log('Cache istatistik güncelleme hatası: $e');
    }
  }

  /// Cache istatistiklerini al
  Future<CacheStatistics> getCacheStatistics() async {
    try {
      final data = _prefs.getString(_cacheStatsKey);
      if (data != null) {
        return CacheStatistics.fromJson(data);
      }
    } catch (e) {
      developer.log('Cache istatistik okuma hatası: $e');
    }
    
    return CacheStatistics();
  }

  /// Cache istatistiklerini kaydet
  Future<void> _saveCacheStatistics(CacheStatistics stats) async {
    try {
      await _prefs.setString(_cacheStatsKey, stats.toJson());
    } catch (e) {
      developer.log('Cache istatistik kaydetme hatası: $e');
    }
  }

  /// Gerçek cache boyutunu hesapla
  Future<CacheStatistics> calculateRealCacheSize() async {
    final stats = CacheStatistics();
    
    try {
      final categories = [
        (CacheCategory.thumbnail, _thumbnailCacheDir),
        (CacheCategory.video, _videoCacheDir),
        (CacheCategory.image, _imageCacheDir),
        (CacheCategory.audio, _audioCacheDir),
        (CacheCategory.export, _exportCacheDir),
        (CacheCategory.drawing, _drawingCacheDir),
      ];

      for (final (category, dirName) in categories) {
        final dir = Directory(path.join(_cacheDirectory.path, dirName));
        if (await dir.exists()) {
          final size = await _calculateDirectorySize(dir);
          
          switch (category) {
            case CacheCategory.thumbnail:
              stats.thumbnailSize = size;
              break;
            case CacheCategory.video:
              stats.videoSize = size;
              break;
            case CacheCategory.image:
              stats.imageSize = size;
              break;
            case CacheCategory.audio:
              stats.audioSize = size;
              break;
            case CacheCategory.export:
              stats.exportSize = size;
              break;
            case CacheCategory.drawing:
              stats.drawingSize = size;
              break;
          }
          
          stats.totalSize += size;
        }
      }
      
      stats.lastUpdated = DateTime.now();
      await _saveCacheStatistics(stats);
      
    } catch (e) {
      developer.log('Cache boyutu hesaplama hatası: $e');
    }
    
    return stats;
  }

  /// Dizin boyutunu hesapla
  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0;
    
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      developer.log('Dizin boyutu hesaplama hatası: $e');
    }
    
    return totalSize;
  }

  /// Otomatik cache temizleme
  Future<void> performAutoCleanup() async {
    developer.log('Otomatik cache temizleme başlatılıyor');
    
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      int deletedFiles = 0;
      int freedBytes = 0;

      // Eski dosyaları temizle
      await for (final entity in _cacheDirectory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now - stat.modified.millisecondsSinceEpoch;
          
          if (age > _maxCacheAge) {
            final size = await entity.length();
            await entity.delete();
            deletedFiles++;
            freedBytes += size;
          }
        }
      }
      
      // Cache boyutu kontrolü
      final stats = await calculateRealCacheSize();
      if (stats.totalSize > _maxCacheSize) {
        await _performLRUCleanup(stats.totalSize - _maxCacheSize);
      }
      
      developer.log('Otomatik temizlik tamamlandı: $deletedFiles dosya silindi, ${_formatFileSize(freedBytes)} alan açıldı');
      
    } catch (e) {
      developer.log('Otomatik temizlik hatası: $e');
    }
  }

  /// LRU (Least Recently Used) temizleme
  Future<void> _performLRUCleanup(int targetBytes) async {
    developer.log('LRU temizleme başlatılıyor: ${_formatFileSize(targetBytes)} alan açılacak');
    
    try {
      final files = <FileInfo>[];
      
      // Tüm dosyaları listele ve erişim zamanlarını al
      await for (final entity in _cacheDirectory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          files.add(FileInfo(
            file: entity,
            lastAccessed: stat.modified,
            size: await entity.length(),
          ));
        }
      }
      
      // Erişim zamanına göre sırala (en eski önce)
      files.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
      
      int freedBytes = 0;
      int deletedFiles = 0;
      
      for (final fileInfo in files) {
        if (freedBytes >= targetBytes) break;
        
        await fileInfo.file.delete();
        freedBytes += fileInfo.size;
        deletedFiles++;
      }
      
      developer.log('LRU temizlik tamamlandı: $deletedFiles dosya silindi, ${_formatFileSize(freedBytes)} alan açıldı');
      
    } catch (e) {
      developer.log('LRU temizlik hatası: $e');
    }
  }

  /// Belirli kategori cache'ini temizle
  Future<void> clearCategoryCache(CacheCategory category) async {
    String dirName;
    switch (category) {
      case CacheCategory.thumbnail:
        dirName = _thumbnailCacheDir;
        break;
      case CacheCategory.video:
        dirName = _videoCacheDir;
        break;
      case CacheCategory.image:
        dirName = _imageCacheDir;
        break;
      case CacheCategory.audio:
        dirName = _audioCacheDir;
        break;
      case CacheCategory.export:
        dirName = _exportCacheDir;
        break;
      case CacheCategory.drawing:
        dirName = _drawingCacheDir;
        break;
    }
    
    try {
      final dir = Directory(path.join(_cacheDirectory.path, dirName));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
        developer.log('${category.name} cache temizlendi');
      }
      
      // İstatistikleri güncelle
      final stats = await getCacheStatistics();
      switch (category) {
        case CacheCategory.thumbnail:
          stats.thumbnailSize = 0;
          break;
        case CacheCategory.video:
          stats.videoSize = 0;
          break;
        case CacheCategory.image:
          stats.imageSize = 0;
          break;
        case CacheCategory.audio:
          stats.audioSize = 0;
          break;
        case CacheCategory.export:
          stats.exportSize = 0;
          break;
        case CacheCategory.drawing:
          stats.drawingSize = 0;
          break;
      }
      await _saveCacheStatistics(stats);
      
    } catch (e) {
      developer.log('Kategori cache temizleme hatası: $e');
    }
  }

  /// Tüm cache'i temizle
  Future<void> clearAllCache() async {
    try {
      if (await _cacheDirectory.exists()) {
        await _cacheDirectory.delete(recursive: true);
        await _cacheDirectory.create(recursive: true);
        await _createCacheDirectories();
      }
      
      // İstatistikleri sıfırla
      await _saveCacheStatistics(CacheStatistics());
      
      developer.log('Tüm cache temizlendi');
      
    } catch (e) {
      developer.log('Tüm cache temizleme hatası: $e');
    }
  }

  /// Dosya boyutunu formatla
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Cache kategorileri
enum CacheCategory {
  thumbnail,
  video,
  image,
  audio,
  export,
  drawing,
}

/// Cache istatistikleri
class CacheStatistics {
  int thumbnailSize;
  int videoSize;
  int imageSize;
  int audioSize;
  int exportSize;
  int drawingSize;
  int totalSize;
  DateTime lastUpdated;

  CacheStatistics({
    this.thumbnailSize = 0,
    this.videoSize = 0,
    this.imageSize = 0,
    this.audioSize = 0,
    this.exportSize = 0,
    this.drawingSize = 0,
    this.totalSize = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  String toJson() {
    return '{'
        '"thumbnailSize": $thumbnailSize,'
        '"videoSize": $videoSize,'
        '"imageSize": $imageSize,'
        '"audioSize": $audioSize,'
        '"exportSize": $exportSize,'
        '"drawingSize": $drawingSize,'
        '"totalSize": $totalSize,'
        '"lastUpdated": "${lastUpdated.toIso8601String()}"'
        '}';
  }

  factory CacheStatistics.fromJson(String json) {
    // Basit JSON parsing (production'da proper JSON parser kullanın)
    final data = json.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
    final pairs = data.split(',');
    
    int thumbnailSize = 0;
    int videoSize = 0;
    int imageSize = 0;
    int audioSize = 0;
    int exportSize = 0;
    int drawingSize = 0;
    int totalSize = 0;
    DateTime lastUpdated = DateTime.now();
    
    for (final pair in pairs) {
      final keyValue = pair.split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = keyValue[1].trim();
        
        switch (key) {
          case 'thumbnailSize':
            thumbnailSize = int.tryParse(value) ?? 0;
            break;
          case 'videoSize':
            videoSize = int.tryParse(value) ?? 0;
            break;
          case 'imageSize':
            imageSize = int.tryParse(value) ?? 0;
            break;
          case 'audioSize':
            audioSize = int.tryParse(value) ?? 0;
            break;
          case 'exportSize':
            exportSize = int.tryParse(value) ?? 0;
            break;
          case 'drawingSize':
            drawingSize = int.tryParse(value) ?? 0;
            break;
          case 'totalSize':
            totalSize = int.tryParse(value) ?? 0;
            break;
          case 'lastUpdated':
            lastUpdated = DateTime.tryParse(value) ?? DateTime.now();
            break;
        }
      }
    }
    
    return CacheStatistics(
      thumbnailSize: thumbnailSize,
      videoSize: videoSize,
      imageSize: imageSize,
      audioSize: audioSize,
      exportSize: exportSize,
      drawingSize: drawingSize,
      totalSize: totalSize,
      lastUpdated: lastUpdated,
    );
  }

  String get formattedTotalSize => _formatFileSize(totalSize);
  String get formattedThumbnailSize => _formatFileSize(thumbnailSize);
  String get formattedVideoSize => _formatFileSize(videoSize);
  String get formattedImageSize => _formatFileSize(imageSize);
  String get formattedAudioSize => _formatFileSize(audioSize);
  String get formattedExportSize => _formatFileSize(exportSize);
  String get formattedDrawingSize => _formatFileSize(drawingSize);

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Dosya bilgisi
class FileInfo {
  final File file;
  final DateTime lastAccessed;
  final int size;

  FileInfo({
    required this.file,
    required this.lastAccessed,
    required this.size,
  });
} 