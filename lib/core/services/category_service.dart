import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_constants.dart';
import 'database_service.dart';


class CategoryService {
  static const String _categoriesKey = 'user_categories';
  static CategoryService? _instance;
  
  CategoryService._internal();
  
  static CategoryService get instance {
    _instance ??= CategoryService._internal();
    return _instance!;
  }

  // Kategorileri yükle
  Future<Map<String, Map<String, dynamic>>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey);
      
      if (categoriesJson != null && categoriesJson.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded = json.decode(categoriesJson);
          final Map<String, Map<String, dynamic>> categories = {};
          
          decoded.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              try {
                // IconData'yı tekrar oluştur
                final iconCodePoint = value['iconCodePoint'] as int?;
                if (iconCodePoint != null) {
                  value['icon'] = IconData(iconCodePoint, fontFamily: 'MaterialIcons');
                } else {
                  // Fallback ikon
                  value['icon'] = AppConstants.getCategoryIcon(key);
                }
                
                // Renk kontrolü
                if (value['color'] == null || value['color'].toString().isEmpty) {
                  value['color'] = AppConstants.getCategoryColor(key);
                }
                
                // İsim kontrolü  
                if (value['name'] == null || value['name'].toString().isEmpty) {
                  value['name'] = AppConstants.getCategoryName(key);
                }
                
                categories[key] = Map<String, dynamic>.from(value);
              } catch (e) {
                debugPrint('Kategori parse hatası ($key): $e');
                // Hatalı kategori için varsayılan değerler
                categories[key] = {
                  'icon': AppConstants.getCategoryIcon(key),
                  'color': AppConstants.getCategoryColor(key),
                  'name': AppConstants.getCategoryName(key),
                };
                  }
  }


});
          
          // En az bir kategori olması gerekiyor
          if (categories.isNotEmpty) {
            return categories;
          }
        } catch (e) {
          debugPrint('JSON parse hatası: $e');
        }
      }
      
      // İlk kez çalıştırılıyor veya parse hatası oldu, varsayılan kategorileri kaydet
      final defaultCategories = _createDefaultCategories();
      await saveCategories(defaultCategories);
      return defaultCategories;
      
    } catch (e) {
      debugPrint('Kategori yükleme hatası: $e');
      return _createDefaultCategories();
    }
  }
  
  // Varsayılan kategorileri oluştur
  Map<String, Map<String, dynamic>> _createDefaultCategories() {
    try {
      return Map<String, Map<String, dynamic>>.from(AppConstants.noteCategories);
    } catch (e) {
      debugPrint('Varsayılan kategori oluşturma hatası: $e');
      // Son çare: manuel kategori oluştur
      return {
        'Kişisel': {
          'icon': Icons.person,
          'color': '#2196F3',
          'name': 'Kişisel',
        },
        'İş': {
          'icon': Icons.work,
          'color': '#FF9800',
          'name': 'İş',
        },
        'Alışveriş': {
          'icon': Icons.shopping_cart,
          'color': '#4CAF50',
          'name': 'Alışveriş',
        },
      };
    }
  }

  // Kategorileri kaydet
  Future<bool> saveCategories(Map<String, Map<String, dynamic>> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // IconData'ları codePoint'e çevir
      final Map<String, dynamic> toSave = {};
      categories.forEach((key, value) {
        try {
          final Map<String, dynamic> categoryData = Map<String, dynamic>.from(value);
          
          // IconData'yı codePoint olarak kaydet
          if (categoryData['icon'] is IconData) {
            final IconData icon = categoryData['icon'] as IconData;
            categoryData['iconCodePoint'] = icon.codePoint;
            categoryData.remove('icon'); // IconData'yı kaldır
          } else if (categoryData['iconCodePoint'] == null) {
            // İkon yoksa varsayılan ekle
            final defaultIcon = AppConstants.getCategoryIcon(key);
            categoryData['iconCodePoint'] = defaultIcon.codePoint;
          }
          
          // Gerekli alanları kontrol et
          categoryData['name'] ??= AppConstants.getCategoryName(key);
          categoryData['color'] ??= AppConstants.getCategoryColor(key);
          
          toSave[key] = categoryData;
        } catch (e) {
          debugPrint('Kategori kaydetme hatası ($key): $e');
        }
      });
      
      if (toSave.isNotEmpty) {
        final categoriesJson = json.encode(toSave);
        return await prefs.setString(_categoriesKey, categoriesJson);
      }
      
      return false;
    } catch (e) {
      debugPrint('Kategori kaydetme hatası: $e');
      return false;
    }
  }

  // Yeni kategori ekle
  Future<bool> addCategory(String key, String name, IconData icon, Color color) async {
    try {
      final categories = await loadCategories();
      
      categories[key] = {
        'icon': icon,
        'color': '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
        'darkColor': '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
        'name': name,
      };
      
      return await saveCategories(categories);
    } catch (e) {
      debugPrint('Kategori ekleme hatası: $e');
      return false;
    }
  }

  // Kategoriyi güncelle
  Future<bool> updateCategory(String key, String name, IconData icon, Color color) async {
    try {
      final categories = await loadCategories();
      
      if (categories.containsKey(key)) {
        final newColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
        
        categories[key] = {
          'icon': icon,
          'color': newColor,
          'darkColor': newColor,
          'name': name,
        };
        
        final saveSuccess = await saveCategories(categories);
        
        if (saveSuccess) {
          // Kategori başarıyla kaydedildiyse, o kategorideki notların renklerini de güncelle
          try {
            final DatabaseService databaseService = DatabaseService();
            final updatedNotesCount = await databaseService.updateNotesColorByCategory(key, newColor);
            debugPrint('CategoryService - Updated $updatedNotesCount notes with new color for category: $key');
          } catch (e) {
            debugPrint('CategoryService - Error updating notes colors: $e');
            // Kategori kaydedildi ama notlar güncellenmedi, yine de başarılı say
          }
        }
        
        return saveSuccess;
      }
      
      return false;
    } catch (e) {
      debugPrint('Kategori güncelleme hatası: $e');
      return false;
    }
  }

  // Kategoriyi sil ve notları Genel kategorisine taşı
  Future<bool> deleteCategory(String key) async {
    try {
      debugPrint('Kategori silme başladı: $key');
      final categories = await loadCategories();
      debugPrint('Mevcut kategoriler: ${categories.keys.toList()}');
      
      // Kategori kontrolünü genişlet
      if (!categories.containsKey(key)) {
        debugPrint('Kategori bulunamadı: $key');
        return false;
      }
      
      if (key == 'Genel' || key == 'all') {
        debugPrint('Sistem kategorisi silinemez: $key');
        return false;
      }
      
      // Önce bu kategorideki notları "Genel" kategorisine taşı
      try {
        final DatabaseService databaseService = DatabaseService();
        
        // Arşivde olsa da olmasa da bu kategorideki TÜM notları "Genel" kategorisine taşı
        final transferredCount = await databaseService.transferNotesToCategory(key, 'Genel');
        debugPrint('Kategori silme: $transferredCount not "Genel" kategorisine taşındı');
      } catch (e) {
        debugPrint('Not transfer hatası: $e');
        return false;
      }
      
      // Kategoriyi kaldır
      categories.remove(key);
      debugPrint('Kategori kaldırıldı, kalan kategoriler: ${categories.keys.toList()}');
      
      // Kaydet
      final success = await saveCategories(categories);
      debugPrint('Kaydetme sonucu: $success');
      
      return success;
    } catch (e) {
      debugPrint('Kategori silme hatası: $e');
      return false;
    }
  }

  // Kategoriyi sil ve notları da sil
  Future<bool> deleteCategoryAndNotes(String key) async {
    try {
      debugPrint('Kategori ve notları silme başladı: $key');
      final categories = await loadCategories();
      
      if (!categories.containsKey(key) || key == 'Genel') {
        debugPrint('Kategori silinemez: $key');
        return false;
      }
      
      // Bu kategorideki notları sil
      try {
        final dbService = DatabaseService();
        
        final moved = await dbService.moveArchivedNotes(key, 'Genel');
        debugPrint('Arşivli $moved not "Genel" kategorisine taşındı');

        final deleted = await dbService.deleteNonArchivedNotes(key);
        debugPrint('$deleted arşivlenmemiş not silindi');
      } catch (e) {
        debugPrint('Not silme hatası: $e');
        return false;
      }
      
      // Kategoriyi kaldır
      categories.remove(key);
      return await saveCategories(categories);
    } catch (e) {
      debugPrint('Kategori ve not silme hatası: $e');
      return false;
    }
  }

  // Kategoriyi sil ve notları "Genel" kategorisine taşı (mevcut deleteCategory metodunu wrapper)
  Future<bool> deleteCategoryAndMoveNotes(String key) async {
    return await deleteCategory(key);
  }

  // Kategori var mı kontrol et
  Future<bool> categoryExists(String key) async {
    final categories = await loadCategories();
    return categories.containsKey(key);
  }

  // Kategori bilgilerini al
  Future<Map<String, dynamic>?> getCategoryInfo(String key) async {
    final categories = await loadCategories();
    return categories[key];
  }

  // Tüm kategori anahtarlarını al
  Future<List<String>> getCategoryKeys() async {
    final categories = await loadCategories();
    return categories.keys.toList();
  }

  // Kategori adını al
  Future<String> getCategoryName(String key) async {
    final categories = await loadCategories();
    return categories[key]?['name'] ?? key;
  }

  // Kategori ikonunu al
  Future<IconData> getCategoryIcon(String key) async {
    final categories = await loadCategories();
    final categoryData = categories[key];
    
    if (categoryData != null && categoryData['icon'] is IconData) {
      return categoryData['icon'] as IconData;
    }
    
    // Fallback: varsayılan ikon
    return AppConstants.getCategoryIcon(key);
  }

  // Kategori rengini al
  Future<Color> getCategoryColor(String key, {bool isDarkMode = false}) async {
    final categories = await loadCategories();
    final categoryData = categories[key];
    
    if (categoryData != null) {
      final colorString = isDarkMode 
          ? (categoryData['darkColor'] ?? categoryData['color'])
          : categoryData['color'];
      
      if (colorString is String) {
        try {
          return Color(int.parse(colorString.replaceAll('#', '0xff')));
        } catch (e) {
          debugPrint('Renk parse hatası: $e');
        }
      }
    }
    
    // Fallback: varsayılan renk
    try {
      final colorString = AppConstants.getCategoryColor(key, isDarkMode: isDarkMode);
      return Color(int.parse(colorString.replaceAll('#', '0xff')));
    } catch (e) {
      // Son çare: mavi renk
      return const Color(0xFF2196F3);
    }
  }

  // AppConstants artık güncellenmez çünkü:
  // - AppConstants sadece varsayılan kategoriler için kullanılır
  // - Kullanıcı kategorileri SharedPreferences'ta saklanır
  // - Bu metod geriye dönük uyumluluk için boş bırakıldı
  Future<void> updateAppConstants() async {
    // Bu metod artık hiçbir şey yapmıyor
    // AppConstants unmodifiable olduğu için değiştirilemez
  }
} 