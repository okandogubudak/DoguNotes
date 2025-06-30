import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Notlarım';
  static const String appVersion = '1.0.0';
  static const String appAuthor = 'Dogu_Notes';
  
  // Security
  static const String defaultAdminPin = '5075';
  static const String pinPrefsKey = 'user_pin';

  static const String firstTimeKey = 'first_time';
  
  // Theme
  static const String themePrefsKey = 'theme_mode';
  static const String isDarkModeKey = 'is_dark_mode';
  
  // Database
  static const String databaseName = 'notes_database.db';
  static const int databaseVersion = 2;
  
  // Shared Preferences Keys
  static const String userPinKey = 'user_pin';
  static const String isFirstTimeKey = 'is_first_time';
  static const String lastBackupKey = 'last_backup';
  
  // Permissions
  static const List<String> requiredPermissions = [
    'camera',
    'microphone',
    'storage',
    'notification',
  ];
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  
  // Note Categories with icons and colors
  static const Map<String, Map<String, dynamic>> noteCategories = {
    'Genel': {
      'icon': '📝',
      'color': '#64B5F6', // Light Blue
      'name': 'Genel',
    },
    'İş': {
      'icon': '💼',
      'color': '#FF5722', // Deep Orange
      'name': 'İş',
    },
    'Önemli': {
      'icon': '⭐',
      'color': '#FFC107', // Amber
      'name': 'Önemli',
    },
    'Şifreler': {
      'icon': '🔑',
      'color': '#4CAF50', // Green
      'name': 'Şifreler',
    },
    'Kişisel': {
      'icon': '👤',
      'color': '#9C27B0', // Purple
      'name': 'Kişisel',
    },
    'Sağlık': {
      'icon': '🏥',
      'color': '#E91E63', // Pink
      'name': 'Sağlık',
    },
  };

  static List<String> get categoryKeys => noteCategories.keys.toList();
  
  static String getCategoryColor(String category, {bool isDarkMode = false}) {
    return noteCategories[category]?['color'] ?? '#64B5F6';
  }
  
  static IconData getCategoryIcon(String category) {
    // Default icons mapping based on category
    switch (category) {
      case 'İş':
        return Icons.work;
      case 'Önemli':
        return Icons.star;
      case 'Şifreler':
        return Icons.vpn_key;
      case 'Kişisel':
        return Icons.person;
      case 'Sağlık':
        return Icons.local_hospital;
      case 'Genel':
        return Icons.folder;
      default:
        return Icons.note;
    }
  }
  
  static String getCategoryName(String category) {
    return noteCategories[category]?['name'] ?? category;
  }
} 