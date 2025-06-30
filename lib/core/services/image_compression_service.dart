import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class ImageCompressionService {
  static const int _maxFileSizeBytes = 1024 * 1024; // 1MB
  static const int _maxDimension = 1920; // Max width/height for images
  static const int _initialQuality = 85;
  static const int _minQuality = 60;

  /// Compress image to be under 1MB while maintaining quality
  static Future<File?> compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      // Read original image
      final originalBytes = await file.readAsBytes();
      
      // If already under 1MB, return original
      if (originalBytes.length <= _maxFileSizeBytes) {
        return file;
      }

      // Decode image
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) return null;

      // Resize if too large
      image = _resizeIfNeeded(image);

      // Compress with varying quality
      final compressedFile = await _compressWithQuality(image, imagePath);
      
      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Resize image if dimensions are too large
  static img.Image _resizeIfNeeded(img.Image image) {
    final maxDim = max(image.width, image.height);
    
    if (maxDim > _maxDimension) {
      final ratio = _maxDimension / maxDim;
      final newWidth = (image.width * ratio).round();
      final newHeight = (image.height * ratio).round();
      
      return img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.cubic,
      );
    }
    
    return image;
  }

  /// Compress image with quality adjustment until under size limit
  static Future<File?> _compressWithQuality(img.Image image, String originalPath) async {
    int quality = _initialQuality;
    Uint8List? compressedBytes;
    
    while (quality >= _minQuality) {
      // Encode as JPEG
      compressedBytes = Uint8List.fromList(
        img.encodeJpg(
          image,
          quality: quality,
        ),
      );
      
      // Check if under size limit
      if (compressedBytes.length <= _maxFileSizeBytes) {
        break;
      }
      
      // Reduce quality
      quality -= 5;
    }
    
    if (compressedBytes == null) return null;

    // Create compressed file
    final directory = path.dirname(originalPath);
    final filename = path.basenameWithoutExtension(originalPath);
    final extension = '.jpg'; // Always save as JPEG for better compression
    final compressedPath = path.join(directory, '${filename}_compressed$extension');
    
    final compressedFile = File(compressedPath);
    await compressedFile.writeAsBytes(compressedBytes);
    
    return compressedFile;
  }

  /// Get image dimensions without loading full image
  static Future<Map<String, int>?> getImageDimensions(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        return {
          'width': image.width,
          'height': image.height,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting image dimensions: $e');
      return null;
    }
  }

  /// Calculate file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if image needs compression
  static Future<bool> needsCompression(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return false;
      
      final stat = await file.stat();
      return stat.size > _maxFileSizeBytes;
    } catch (e) {
      return false;
    }
  }

  /// Compress multiple images in batch
  static Future<List<String>> compressMultipleImages(List<String> imagePaths) async {
    final compressedPaths = <String>[];
    
    for (final imagePath in imagePaths) {
      final compressedFile = await compressImage(imagePath);
      if (compressedFile != null) {
        compressedPaths.add(compressedFile.path);
      } else {
        compressedPaths.add(imagePath); // Keep original if compression fails
      }
    }
    
    return compressedPaths;
  }

  /// Create thumbnail for image
  static Future<File?> createThumbnail(String imagePath, {int size = 150}) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final originalBytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) return null;

      // Create square thumbnail
      final thumbnail = img.copyResizeCropSquare(image, size: size);

      // Encode with lower quality for thumbnails
      final thumbnailBytes = Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: 70),
      );

      // Save thumbnail
      final directory = path.dirname(imagePath);
      final filename = path.basenameWithoutExtension(imagePath);
      final thumbnailPath = path.join(directory, '${filename}_thumb.jpg');
      
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      
      return thumbnailFile;
    } catch (e) {
      print('Error creating thumbnail: $e');
      return null;
    }
  }

  /// Auto-enhance image (basic improvements)
  static Future<File?> autoEnhanceImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final originalBytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) return null;

      // Apply basic enhancements
      image = img.adjustColor(
        image,
        contrast: 1.05,  // Slight contrast boost
        saturation: 1.02, // Slight saturation boost
        brightness: 1.01,  // Slight brightness boost
      );

      // Apply noise reduction
      image = img.gaussianBlur(image, radius: 1);

      // Encode enhanced image
      final enhancedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: 90),
      );

      // Save enhanced image
      final directory = path.dirname(imagePath);
      final filename = path.basenameWithoutExtension(imagePath);
      final enhancedPath = path.join(directory, '${filename}_enhanced.jpg');
      
      final enhancedFile = File(enhancedPath);
      await enhancedFile.writeAsBytes(enhancedBytes);
      
      return enhancedFile;
    } catch (e) {
      print('Error enhancing image: $e');
      return null;
    }
  }
} 