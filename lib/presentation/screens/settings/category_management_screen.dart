import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/category_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notes_provider.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  Map<String, Map<String, dynamic>> _categories = {};
  bool _isLoading = true;
  bool _isEditMode = false;
  
  // Standart renkler
  final List<Color> _standardColors = [
    const Color(0xFF3B82F6), // Mavi
    const Color(0xFF10B981), // Yeşil
    const Color(0xFFEF4444), // Kırmızı
    const Color(0xFFF59E0B), // Sarı
    const Color(0xFF8B5CF6), // Mor
    const Color(0xFFEC4899), // Pembe
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF84CC16), // Lime
    const Color(0xFFF97316), // Turuncu
    const Color(0xFF6B7280), // Gri
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCategories();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  Future<void> _loadCategories() async {
    try {
      final categoryService = CategoryService.instance;
      _categories = await categoryService.loadCategories();
    } catch (e) {
      // Handle error
    } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildProfessionalAppBar(isDarkMode),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header Stats
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kategoriler',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_categories.length} kategori',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode 
                                      ? const Color(0xFF94A3B8) 
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showAddCategoryDialog,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                  
                  // Düzenleme modu bilgisi
                  if (_isEditMode)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Düzenleme modu aktif - Kategorileri sürükleyerek sıralayın',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Categories List
                  Expanded(
                    child: _categories.isEmpty
                        ? _buildEmptyState(isDarkMode)
                        : _isEditMode
                            ? _buildReorderableList(isDarkMode)
                            : _buildRegularList(isDarkMode),
                  ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDarkMode ? Colors.white : const Color(0xFF334155),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Kategori Yönetimi',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      actions: [
        if (_categories.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 20,
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _isEditMode,
                  onChanged: (value) {
                    setState(() {
                      _isEditMode = value;
                    });
                  },
                  activeColor: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCategoryCard(String name, Map<String, dynamic> data, bool isDarkMode) {
    // Güvenli renk parse etme
    int colorValue = 0xFF3B82F6;
    if (data['color'] != null) {
      if (data['color'] is int) {
        colorValue = data['color'];
      } else if (data['color'] is String) {
        try {
          final String hexString = data['color'] as String;
          final formatted = hexString.startsWith('#')
              ? '0xff${hexString.substring(1)}'
              : hexString;
          colorValue = int.parse(formatted);
        } catch (e) {
          colorValue = 0xFF3B82F6;
        }
      }
    }
    
    // Güvenli icon parse etme
    int iconValue = Icons.folder.codePoint;
    if (data['icon'] != null) {
      if (data['icon'] is int) {
        iconValue = data['icon'];
      } else if (data['icon'] is String) {
        try {
          iconValue = int.parse(data['icon']);
        } catch (e) {
          iconValue = Icons.folder.codePoint;
        }
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Color(colorValue),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showEditCategoryDialog(name, data),
            ),
            if (name != 'Genel') // Cannot delete default category
            IconButton(
                icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
                onPressed: () => _showDeleteConfirmation(name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF1E293B) 
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 50,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz kategori yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notlarınızı düzenlemek için kategoriler ekleyin',
            style: TextStyle(
              color: isDarkMode 
                  ? const Color(0xFF94A3B8) 
                  : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddCategoryDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('İlk Kategoriyi Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(String name, Map<String, dynamic> data) {
    _showCategoryDialog(name: name, data: data);
  }

  void _showCategoryDialog({String? name, Map<String, dynamic>? data}) {
    final nameController = TextEditingController(text: name);
    
    // Güvenli renk parse etme
    int colorValue = 0xFF3B82F6;
    if (data?['color'] != null) {
      if (data!['color'] is int) {
        colorValue = data['color'];
      } else if (data['color'] is String) {
        try {
          final String hexString = data['color'] as String;
          final formatted = hexString.startsWith('#')
              ? '0xff${hexString.substring(1)}'
              : hexString;
          colorValue = int.parse(formatted);
        } catch (e) {
          colorValue = 0xFF3B82F6;
        }
      }
    }
    Color selectedColor = Color(colorValue);
    
    // Güvenli icon parse etme
    int iconValue = Icons.folder.codePoint;
    if (data?['icon'] != null) {
      if (data!['icon'] is int) {
        iconValue = data['icon'];
      } else if (data['icon'] is String) {
        try {
          iconValue = int.parse(data['icon']);
        } catch (e) {
          iconValue = Icons.folder.codePoint;
        }
      }
    }
    IconData selectedIcon = IconData(iconValue, fontFamily: 'MaterialIcons');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(name == null ? 'Kategori Ekle' : 'Kategori Düzenle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Renk seçici
                const Text(
                  'Renk Seçin:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _standardColors.map((color) {
                    final isSelected = selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: isSelected 
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    await _saveCategory(
                      nameController.text.trim(),
                      '', // Açıklama boş
                      selectedColor,
                      selectedIcon,
                      isEditing: name != null,
                      oldName: name,
                    );
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(name == null ? 'Ekle' : 'Güncelle'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveCategory(
    String name,
    String description,
    Color color,
    IconData icon,
    {bool isEditing = false, String? oldName}
  ) async {
    try {
      final categoryService = CategoryService.instance;
      
      if (isEditing && oldName != null) {
        await categoryService.updateCategory(oldName, name, icon, color);
      } else {
        await categoryService.addCategory(name, name, icon, color);
      }
      
      await _loadCategories();

      // Notları ve kategori renklerini güncelle
      if (mounted) {
        final notesProvider = Provider.of<NotesProvider>(context, listen: false);
        await notesProvider.refreshNotesAfterCategoryOperation();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _saveCategoryOrder() async {
    try {
      final categoryService = CategoryService.instance;
      await categoryService.saveCategories(_categories);
    } catch (e) {
      debugPrint('Kategori sıralaması kaydedilemedi: $e');
    }
  }

  void _showDeleteConfirmation(String name) {
    bool deleteNotesWithCategory = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
        title: const Text('Kategori Sil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name kategorisini silmek istediğinizden emin misiniz?'),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu kategorideki notlar ne olsun?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Switch(
                            value: deleteNotesWithCategory,
                            onChanged: (value) {
                              setDialogState(() {
                                deleteNotesWithCategory = value;
                              });
                            },
                            activeColor: const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deleteNotesWithCategory 
                                  ? 'Notları da sil (geri alınamaz)'
                                  : 'Notları "Genel" kategorisine taşı',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
                  await _deleteCategory(name, deleteNotesWithCategory);
            },
            child: const Text('Sil', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(String name, [bool deleteNotesWithCategory = false]) async {
    try {
      final categoryService = CategoryService.instance;
      
      if (deleteNotesWithCategory) {
        // Notları da sil
        await categoryService.deleteCategoryAndNotes(name);
      } else {
        // Notları "Genel" kategorisine taşı
        await categoryService.deleteCategoryAndMoveNotes(name);
      }
      
        await _loadCategories();
      
      // Ana ekranı güncelle
      if (mounted) {
        final notesProvider = Provider.of<NotesProvider>(context, listen: false);
        await notesProvider.refreshNotesAfterCategoryOperation();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deleteNotesWithCategory 
              ? 'Kategori ve notları silindi' 
              : 'Kategori silindi, notlar "Genel" kategorisine taşındı'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  // Normal liste
  Widget _buildRegularList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _categories.keys.length,
      itemBuilder: (context, index) {
        final categoryName = _categories.keys.elementAt(index);
        final categoryData = _categories[categoryName]!;
        return _buildCategoryCard(categoryName, categoryData, isDarkMode);
      },
    );
  }

  // Sıralanabilir liste
  Widget _buildReorderableList(bool isDarkMode) {
    final categoryKeys = _categories.keys.toList();
    
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      buildDefaultDragHandles: false,
      itemCount: categoryKeys.length,
      itemBuilder: (context, index) {
        final categoryName = categoryKeys[index];
        final categoryData = _categories[categoryName]!;
        return _buildReorderableCategoryCard(
          categoryName,
          categoryData,
          isDarkMode,
          key: ValueKey(categoryName),
          index: index,
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        // 'Genel' kategorisi (index 0) hareket ettirilemez
        if (oldIndex == 0 || newIndex == 0) {
          return; // işlemi iptal et
        }

        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }

          final String item = categoryKeys.removeAt(oldIndex);
          categoryKeys.insert(newIndex, item);

          // Ensure 'Genel' first
          if (categoryKeys.first != 'Genel') {
            categoryKeys.remove('Genel');
            categoryKeys.insert(0, 'Genel');
          }

          final newCategories = <String, Map<String, dynamic>>{};
          for (String key in categoryKeys) {
            newCategories[key] = _categories[key]!;
          }
          _categories = newCategories;
          
          // Sıralamayı kaydet
          _saveCategoryOrder();
        });
      },
    );
  }

  // Sıralanabilir kategori kartı
  Widget _buildReorderableCategoryCard(String name, Map<String, dynamic> data, bool isDarkMode, {required Key key, required int index}) {
    // Güvenli renk parse etme
    int colorValue = 0xFF3B82F6;
    if (data['color'] != null) {
      if (data['color'] is int) {
        colorValue = data['color'];
      } else if (data['color'] is String) {
        try {
          final String hexString = data['color'] as String;
          final formatted = hexString.startsWith('#')
              ? '0xff${hexString.substring(1)}'
              : hexString;
          colorValue = int.parse(formatted);
        } catch (e) {
          colorValue = 0xFF3B82F6;
        }
      }
    }
    
    // Güvenli icon parse etme
    int iconValue = Icons.folder.codePoint;
    if (data['icon'] != null) {
      if (data['icon'] is int) {
        iconValue = data['icon'];
      } else if (data['icon'] is String) {
        try {
          iconValue = int.parse(data['icon']);
        } catch (e) {
          iconValue = Icons.folder.codePoint;
        }
      }
    }
    
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (name != 'Genel') ...[
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                IconData(iconValue, fontFamily: 'MaterialIcons'),
                color: Color(colorValue),
                size: 20,
              ),
            ),
          ],
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showEditCategoryDialog(name, data),
            ),
            if (name != 'Genel')
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
                onPressed: () => _showDeleteConfirmation(name),
              ),
          ],
        ),
      ),
    );
  }
} 