import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Request all required permissions with better handling
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    Map<Permission, PermissionStatus> permissions = {};
    
    print('PermissionService - Starting permission requests');
    
    // Request storage permission first (most important)
    try {
      permissions[Permission.storage] = await Permission.storage.request();
      print('PermissionService - Storage permission: ${permissions[Permission.storage]}');
    } catch (e) {
      print('PermissionService - Storage permission error: $e');
    }
    
    // Request manage external storage permission (for Android 11+)
    try {
      permissions[Permission.manageExternalStorage] = await Permission.manageExternalStorage.request();
      print('PermissionService - ManageExternalStorage permission: ${permissions[Permission.manageExternalStorage]}');
    } catch (e) {
      print('PermissionService - ManageExternalStorage permission error: $e');
    }
    
    // Request photos permission (for Android 13+)
    try {
      permissions[Permission.photos] = await Permission.photos.request();
      print('PermissionService - Photos permission: ${permissions[Permission.photos]}');
    } catch (e) {
      print('PermissionService - Photos permission error: $e');
    }
    
    // Request camera permission
    try {
      permissions[Permission.camera] = await Permission.camera.request();
      print('PermissionService - Camera permission: ${permissions[Permission.camera]}');
    } catch (e) {
      print('PermissionService - Camera permission error: $e');
    }
    
    // Request microphone permission
    try {
      permissions[Permission.microphone] = await Permission.microphone.request();
      print('PermissionService - Microphone permission: ${permissions[Permission.microphone]}');
    } catch (e) {
      print('PermissionService - Microphone permission error: $e');
    }
    
    // Request media library permission (for iOS)
    try {
      permissions[Permission.mediaLibrary] = await Permission.mediaLibrary.request();
      print('PermissionService - MediaLibrary permission: ${permissions[Permission.mediaLibrary]}');
    } catch (e) {
      print('PermissionService - MediaLibrary permission error: $e');
    }
    
    // Request notification permission (for Android 13+)
    try {
      if (await Permission.notification.isDenied) {
        permissions[Permission.notification] = await Permission.notification.request();
        print('PermissionService - Notification permission: ${permissions[Permission.notification]}');
      }
    } catch (e) {
      print('PermissionService - Notification permission error: $e');
    }
    
    print('PermissionService - All permissions result: $permissions');
    return permissions;
  }

  // Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  // Check if microphone permission is granted
  Future<bool> isMicrophonePermissionGranted() async {
    return await Permission.microphone.isGranted;
  }

  // Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    return await Permission.storage.isGranted;
  }

  // Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  // Request camera permission
  Future<PermissionStatus> requestCameraPermission() async {
    return await Permission.camera.request();
  }

  // Request microphone permission
  Future<PermissionStatus> requestMicrophonePermission() async {
    return await Permission.microphone.request();
  }

  // Request storage permission
  Future<PermissionStatus> requestStoragePermission() async {
    return await Permission.storage.request();
  }

  // Request notification permission
  Future<PermissionStatus> requestNotificationPermission() async {
    return await Permission.notification.request();
  }

  // Check permission status
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    return await permission.status;
  }

  // Open app settings if permission is permanently denied
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  // Get all permissions status
  Future<Map<Permission, PermissionStatus>> getAllPermissionsStatus() async {
    Map<Permission, PermissionStatus> permissions = {};
    
    permissions[Permission.camera] = await Permission.camera.status;
    permissions[Permission.microphone] = await Permission.microphone.status;
    permissions[Permission.storage] = await Permission.storage.status;
    permissions[Permission.manageExternalStorage] = await Permission.manageExternalStorage.status;
    permissions[Permission.photos] = await Permission.photos.status;
    permissions[Permission.mediaLibrary] = await Permission.mediaLibrary.status;
    permissions[Permission.notification] = await Permission.notification.status;
    
    return permissions;
  }

  // Check if all required permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    final permissions = await getAllPermissionsStatus();
    return permissions.values.every((status) => status == PermissionStatus.granted);
  }

  // Get permission status message
  String getPermissionStatusMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'İzin verildi';
      case PermissionStatus.denied:
        return 'İzin reddedildi';
      case PermissionStatus.restricted:
        return 'İzin kısıtlanmış';
      case PermissionStatus.permanentlyDenied:
        return 'İzin kalıcı olarak reddedildi';
      case PermissionStatus.provisional:
        return 'Geçici izin';
      case PermissionStatus.limited:
        return 'Sınırlı izin';
      default:
        return 'Bilinmeyen durum';
    }
  }

  // Get permission name
  String getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Kamera';
      case Permission.microphone:
        return 'Mikrofon';
      case Permission.storage:
        return 'Depolama';
      case Permission.manageExternalStorage:
        return 'Harici Depolama Yönetimi';
      case Permission.photos:
        return 'Fotoğraflar';
      case Permission.mediaLibrary:
        return 'Medya Kitaplığı';
      case Permission.notification:
        return 'Bildirimler';
      default:
        return permission.toString();
    }
  }
} 