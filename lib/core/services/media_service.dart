import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:uuid/uuid.dart';
import 'image_compression_service.dart';
import 'package:flutter/foundation.dart';
import 'video_service.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  FlutterSoundRecorder? _audioRecorder;
  final Uuid _uuid = const Uuid();
  bool _isRecorderInitialized = false;

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        final originalFile = File(image.path);
        
        // Auto-compress if needed
        final compressedFile = await ImageCompressionService.compressImage(originalFile.path);
        return compressedFile ?? originalFile;
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        final originalFile = File(image.path);
        
        // Auto-compress if needed
        final compressedFile = await ImageCompressionService.compressImage(originalFile.path);
        return compressedFile ?? originalFile;
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      final compressedFiles = <File>[];
      
      for (final image in images) {
        final originalFile = File(image.path);
        
        // Auto-compress if needed
        final compressedFile = await ImageCompressionService.compressImage(originalFile.path);
        compressedFiles.add(compressedFile ?? originalFile);
      }
      
      return compressedFiles;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // Pick video from camera
  Future<XFile?> pickVideoFromCamera() async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5), // 5 dakika maksimum
      );
      
      if (video != null) {
        // Video'yu Dogu formatında yeniden adlandır
        final videoService = VideoService();
        final renamedPath = await videoService.renameToDoguFormat(video.path);
        return XFile(renamedPath);
      }
      
      return video;
    } catch (e) {
      debugPrint('Video kamera hatası: $e');
      return null;
    }
  }

  // Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      print('Error picking video from gallery: $e');
      return null;
    }
  }

  // Pick files
  Future<List<File>> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );
      
      if (result != null) {
        return result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }

  // Initialize recorder
  Future<void> _initializeRecorder() async {
    if (!_isRecorderInitialized) {
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();
      _isRecorderInitialized = true;
    }
  }

  // Start audio recording
  Future<String?> startAudioRecording() async {
    try {
      await _initializeRecorder();
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'audio_${_uuid.v4()}.aac';
      final filePath = '${directory.path}/$fileName';
      
      await _audioRecorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
      
      return filePath;
    } catch (e) {
      print('Error starting audio recording: $e');
      return null;
    }
  }

  // Stop audio recording
  Future<String?> stopAudioRecording() async {
    try {
      final path = await _audioRecorder!.stopRecorder();
      return path;
    } catch (e) {
      print('Error stopping audio recording: $e');
      return null;
    }
  }

  // Pause audio recording
  Future<void> pauseAudioRecording() async {
    try {
      await _audioRecorder!.pauseRecorder();
    } catch (e) {
      print('Error pausing audio recording: $e');
    }
  }

  // Resume audio recording
  Future<void> resumeAudioRecording() async {
    try {
      await _audioRecorder!.resumeRecorder();
    } catch (e) {
      print('Error resuming audio recording: $e');
    }
  }

  // Check if recording
  Future<bool> isRecording() async {
    try {
      await _initializeRecorder();
      return _audioRecorder!.isRecording;
    } catch (e) {
      print('Error checking recording status: $e');
      return false;
    }
  }

  // Check if paused
  Future<bool> isPaused() async {
    try {
      await _initializeRecorder();
      return _audioRecorder!.isPaused;
    } catch (e) {
      print('Error checking pause status: $e');
      return false;
    }
  }

  // Close recorder
  Future<void> closeRecorder() async {
    if (_isRecorderInitialized && _audioRecorder != null) {
      await _audioRecorder!.closeRecorder();
      _audioRecorder = null;
      _isRecorderInitialized = false;
    }
  }

  // Save file to app directory
  Future<String?> saveFileToAppDirectory(File file, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/$fileName';
      final newFile = await file.copy(newPath);
      return newFile.path;
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }

  // Delete file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error getting file size: $e');
      return 0;
    }
  }

  // Format file size
  String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }
} 