import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/services/category_service.dart';
import '../../../data/models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/audio_recorder_widget.dart';
import '../../widgets/media_attachment_widget.dart';
import '../../../domain/entities/note.dart';
import '../../../core/services/speech_to_text_service.dart';
import '../../../core/services/image_compression_service.dart';
import '../../../core/services/media_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';

class AddNoteScreen extends StatefulWidget {
  final NoteModel? noteToEdit;

  const AddNoteScreen({
    super.key,
    this.noteToEdit,
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String _selectedCategory = 'Genel';
  final List<String> _attachments = [];
  final List<String> _audioPaths = [];
  bool _isRecording = false;
  int? _playingIndex;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  final List<String> _tags = [];
  
  String _selectedColor = '#3B82F6';
  bool _isPinned = false;
  bool _isFavorite = false;
  
  Map<String, Map<String, dynamic>> _categories = {};
  bool _categoriesLoaded = false;
  bool _isLoading = false;
  final SpeechToTextService _speechService = SpeechToTextService();
  final bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCategories();
    
    if (widget.noteToEdit != null) {
      _populateFields();
    }
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

  void _populateFields() {
    final note = widget.noteToEdit!;
    _titleController.text = note.title;
    _contentController.text = note.content;
    _selectedCategory = note.category;
    setState(() {
      _tags.clear();
      _tags.addAll(note.tags);
      _attachments.clear();
      _attachments.addAll(note.attachments);
      _audioPaths.clear();
      if (note.audioPath != null) {
        _audioPaths.add(note.audioPath!);
      }
    });
    _selectedColor = note.color;
    _isPinned = note.isPinned;
    _isFavorite = note.isFavorite;
  }
  
  Future<void> _loadCategories() async {
    try {
      final categoryService = CategoryService.instance;
      _categories = await categoryService.loadCategories();
      setState(() {
        _categoriesLoaded = true;
      });
    } catch (e) {
      setState(() {
        _categoriesLoaded = true;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty && 
        _contentController.text.trim().isEmpty) {
      _showSnackBar('Başlık veya içerik boş olamaz', isError: true);
      return;
    }

        setState(() {
      _isLoading = true;
    });

    try {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      
      if (widget.noteToEdit != null) {
        // Update existing note
        final updatedNote = widget.noteToEdit!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          tags: _tags,
          color: _selectedColor,
          isPinned: _isPinned,
          isFavorite: _isFavorite,
          attachments: _attachments,
          audioPath: _audioPaths.isNotEmpty ? _audioPaths.first : null,
          updatedAt: DateTime.now(),
        );
        
        await notesProvider.updateNote(updatedNote);
        _showSnackBar('Not güncellendi');
        
        // Güncellenen notu geri döndür
        Navigator.of(context).pop(updatedNote);
        return;
      } else {
        // Create new note
        final result = await notesProvider.addNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          color: _selectedColor,
          tags: _tags,
          attachments: _attachments,
          audioPath: _audioPaths.isNotEmpty ? _audioPaths.first : null,
          isFavorite: _isFavorite,
          isPinned: _isPinned,
        );
        
        if (result) {
          _showSnackBar('Not kaydedildi');
        } else {
          _showSnackBar('Not kaydedilemedi', isError: true);
          return;
        }
      }
      
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('Not kaydedilemedi: $e', isError: true);
    }

      setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? const Color(0xFFEF4444) 
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    Color selectedColor = const Color(0xFF3B82F6);
    
    final standardColors = [
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Yeni Kategori Ekle'),
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
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                
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
                  children: standardColors.map((color) {
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
                    await _saveNewCategory(nameController.text.trim(), selectedColor);
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveNewCategory(String name, Color color) async {
    try {
      final categoryService = CategoryService.instance;
      await categoryService.addCategory(name, name, Icons.folder, color);
      
      // Kategorileri yeniden yükle
      await _loadCategories();
      
      // Yeni kategoriyi seç ve rengini de ayarla
      setState(() {
        _selectedCategory = name;
        _selectedColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      });
      
      _showSnackBar('Kategori eklendi');
    } catch (e) {
      _showSnackBar('Kategori eklenirken hata oluştu: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _audioPlayer?.dispose();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input
              _buildTitleInput(isDarkMode),
              
              const SizedBox(height: 20),
              
              // Content Input
              _buildContentInput(isDarkMode),
              
              const SizedBox(height: 24),
              
              // Category Selection
              _buildCategorySection(isDarkMode),
              
              const SizedBox(height: 24),
              
              // Tags Section
              _buildTagsSection(isDarkMode),
              
              const SizedBox(height: 24),
              
              // Note Options
              _buildOptionsSection(isDarkMode),
              
              const SizedBox(height: 24),
              
              // Media Attachments
              _buildMediaSection(isDarkMode),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: null,
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDarkMode ? Colors.white : const Color(0xFF334155),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        widget.noteToEdit != null ? 'Notu Düzenle' : 'Yeni Not',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      actions: [
        if (_isLoading) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
              ),
            ),
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.check_rounded),
            color: const Color(0xFF10B981),
            onPressed: _saveNote,
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTitleInput(bool isDarkMode) {
    return Container(
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
      child: TextField(
        controller: _titleController,
        focusNode: _titleFocus,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Not başlığı...',
          hintStyle: TextStyle(
            color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _contentFocus.requestFocus(),
      ),
    );
  }

  Widget _buildContentInput(bool isDarkMode) {
    return Container(
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
      child: TextField(
        controller: _contentController,
        focusNode: _contentFocus,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Notunuzu buraya yazın...',
          hintStyle: TextStyle(
            color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        maxLines: 10,
        minLines: 6,
        textInputAction: TextInputAction.newline,
      ),
    );
  }

  Widget _buildCategorySection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        
        const SizedBox(height: 12),
        
        if (_categoriesLoaded) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._categories.keys.map((category) {
                final isSelected = category == _selectedCategory;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        final data = _categories[category];
                        if (data != null && data['color'] != null) {
                          if (data['color'] is int) {
                            _selectedColor = '#${(data['color'] as int).toRadixString(16).substring(2).toUpperCase()}';
                          } else if (data['color'] is String) {
                            _selectedColor = data['color'];
                          }
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF3B82F6)
                            : isDarkMode 
                                ? const Color(0xFF1E293B) 
                                : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF3B82F6)
                              : isDarkMode 
                                  ? const Color(0xFF334155) 
                                  : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? Colors.white
                              : isDarkMode 
                                  ? const Color(0xFF94A3B8) 
                                  : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // + butonu - son sırada
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showAddCategoryDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? const Color(0xFF1E293B) 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Yeni',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              'Kategoriler yükleniyor...',
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTagsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etiketler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) => Chip(
              label: Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF10B981),
              deleteIcon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
              onDeleted: () => setState(() => _tags.remove(tag)),
            )),
            
            // Add Tag Button
            ActionChip(
              label: const Text('+ Etiket Ekle'),
              onPressed: _showAddTagDialog,
              backgroundColor: isDarkMode 
                  ? const Color(0xFF1E293B) 
                  : Colors.white,
              side: BorderSide(
                color: isDarkMode 
                    ? const Color(0xFF334155) 
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not Seçenekleri',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  'Sabitle',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Bu not en üstte görünür',
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value),
                activeColor: const Color(0xFF3B82F6),
              ),
              
              Divider(
                height: 1,
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              
              SwitchListTile(
                title: Text(
                  'Favorilere Ekle',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Favori notlarında görünür',
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                value: _isFavorite,
                onChanged: (value) => setState(() => _isFavorite = value),
                activeColor: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDarkMode) {
    final isEdit = widget.noteToEdit != null;
    final buttonColor = isEdit ? const Color(0xFFFF9500) : const Color(0xFF3B82F6);
    final buttonText = isEdit ? 'Güncelle' : 'Kaydet';
    final loadingText = isEdit ? 'Güncelleniyor...' : 'Kaydediliyor...';
    
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _saveNote,
      backgroundColor: buttonColor,
      icon: _isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Icon(isEdit ? Icons.update_rounded : Icons.check_rounded, color: Colors.white),
      label: Text(
        _isLoading ? loadingText : buttonText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Etiket Ekle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Etiket adı',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() => _tags.add(tag));
              }
                  Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(bool isDarkMode) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ana medya ekleme butonu
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showMediaOptions(isDarkMode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_rounded, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Medya Ekle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Eklenen medya dosyalarını göster
          if (_attachments.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eklenen Dosyalar (${_attachments.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MediaAttachmentWidget(
                    attachments: _attachments,
                    onRemoveAttachment: (String path) {
                      setState(() {
                        _attachments.remove(path);
                        _audioPaths.remove(path);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMediaOptions(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Başlık
              Text(
                'Medya Seçin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),
              
              // Kamera seçenekleri
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF3B82F6)),
                      ),
                      title: const Text('Fotoğraf Çek'),
                      subtitle: const Text('Kamera ile fotoğraf çek'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.videocam_rounded, color: Color(0xFF10B981)),
                      ),
                      title: const Text('Video Kaydet'),
                      subtitle: const Text('Kamera ile video kaydet'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideoFromCamera();
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Galeri seçenekleri
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Color(0xFF3B82F6)),
                      ),
                      title: const Text('Resim'),
                      subtitle: const Text('Galeriden resim seç'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.video_library_rounded, color: Color(0xFF10B981)),
                      ),
                      title: const Text('Video'),
                      subtitle: const Text('Galeriden video seç'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideoFromGallery();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.attach_file_rounded, color: Color(0xFFEF4444)),
                      ),
                      title: const Text('Belge'),
                      subtitle: const Text('Dosya ekle'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickFile();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mic_rounded, color: Color(0xFFF59E0B)),
                      ),
                      title: const Text('Ses Kaydı'),
                      subtitle: const Text('Ses kaydet'),
                      onTap: () {
                        Navigator.pop(context);
                        _startAudioRecording();
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ses Kayıtları',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        AudioRecorderWidget(
          audioPath: null,
          isRecording: _isRecording,
          onStartRecording: () async {
            setState(() => _isRecording = true);
            // Kayıt başlat
            final mediaService = MediaService();
            await mediaService.startAudioRecording();
          },
          onStopRecording: () async {
            setState(() => _isRecording = false);
            // Kayıt durdur
            final mediaService = MediaService();
            final path = await mediaService.stopAudioRecording();
            if (path != null) {
              setState(() {
                _audioPaths.add(path);
                // Ses kaydını medya eklerine de ekle
                if (!_attachments.contains(path)) {
                  _attachments.add(path);
                }
              });
            }
          },
          onDeleteAudio: null,
        ),
        const SizedBox(height: 12),
        ..._audioPaths.asMap().entries.map((entry) {
          final index = entry.key;
          final path = entry.value;
          final isPlaying = _playingIndex == index && _isPlaying;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Color(0xFF3B82F6)),
                  onPressed: () async {
                    if (_playingIndex == index && _isPlaying) {
                      await _audioPlayer?.pause();
                      setState(() => _isPlaying = false);
                    } else {
                      _audioPlayer?.dispose();
                      _audioPlayer = AudioPlayer();
                      _audioPlayer!.onPlayerComplete.listen((_) {
                        setState(() {
                          _isPlaying = false;
                          _playingIndex = null;
                        });
                      });
                      await _audioPlayer!.play(DeviceFileSource(path));
                      setState(() {
                        _playingIndex = index;
                        _isPlaying = true;
                      });
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Ses kaydı ${index + 1}'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
                  onPressed: () async {
                    setState(() {
                      if (_playingIndex == index) {
                        _audioPlayer?.stop();
                        _isPlaying = false;
                        _playingIndex = null;
                      }
                      _audioPaths.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      
      if (result != null) {
        setState(() {
          _attachments.addAll(result.paths.where((path) => path != null).cast<String>());
        });
      }
    } catch (e) {
      _showSnackBar('Resim seçilemedi: $e', isError: true);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );
      
      if (result != null) {
        setState(() {
          _attachments.addAll(result.paths.where((path) => path != null).cast<String>());
        });
      }
    } catch (e) {
      _showSnackBar('Video seçilemedi: $e', isError: true);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );
      
      if (result != null) {
        setState(() {
          _attachments.addAll(result.paths.where((path) => path != null).cast<String>());
        });
      }
    } catch (e) {
      _showSnackBar('Dosya seçilemedi: $e', isError: true);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        final String renamedPath = await _renameAndSaveFile(image.path, 'pic');
        setState(() {
          _attachments.add(renamedPath);
        });
      }
    } catch (e) {
      _showSnackBar('Kamera ile fotoğraf çekilemedi: $e', isError: true);
    }
  }

  Future<void> _pickVideoFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );
      
      if (video != null) {
        final String renamedPath = await _renameAndSaveFile(video.path, 'vid');
        setState(() {
          _attachments.add(renamedPath);
        });
      }
    } catch (e) {
      _showSnackBar('Kamera ile video çekilemedi: $e', isError: true);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
      );
      
      for (XFile image in images) {
        final String renamedPath = await _renameAndSaveFile(image.path, 'pic');
        setState(() {
          _attachments.add(renamedPath);
        });
      }
    } catch (e) {
      _showSnackBar('Galeriden fotoğraf seçilemedi: $e', isError: true);
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      
      if (video != null) {
        final String renamedPath = await _renameAndSaveFile(video.path, 'vid');
        setState(() {
          _attachments.add(renamedPath);
        });
      }
    } catch (e) {
      _showSnackBar('Galeriden video seçilemedi: $e', isError: true);
    }
  }

  Future<String> _renameAndSaveFile(String originalPath, String type) async {
    try {
      final File originalFile = File(originalPath);
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String mediaDir = path.join(appDir.path, 'media');
      
      // Media klasörünü oluştur
      await Directory(mediaDir).create(recursive: true);
      
      // Dosya uzantısını al
      final String extension = path.extension(originalPath);
      
      // Tip bazında kısaltılmış adlar
      String shortType;
      switch (type.toLowerCase()) {
        case 'pic':
        case 'image':
          shortType = 'pic';
          break;
        case 'vid':
        case 'video':
          shortType = 'vid';
          break;
        case 'audio':
        case 'sound':
          shortType = 'aac';
          break;
        default:
          shortType = 'doc';
      }
      
      // Aynı tip dosyaların sayısını say
      final List<FileSystemEntity> existingFiles = Directory(mediaDir)
          .listSync()
          .where((entity) => entity is File && 
                 path.basename(entity.path).startsWith('DG_$shortType'))
          .toList();
      
      final int nextNumber = existingFiles.length + 1;
      final String paddedNumber = nextNumber.toString().padLeft(2, '0');
      
      // Yeni dosya adı - kısa format
      final String newFileName = 'DG_$shortType$paddedNumber$extension';
      final String newPath = path.join(mediaDir, newFileName);
      
      // Dosyayı kopyala
      await originalFile.copy(newPath);
      
      return newPath;
    } catch (e) {
      debugPrint('Dosya yeniden adlandırılamadı: $e');
      return originalPath;
    }
  }

  Future<void> _startAudioRecording() async {
    try {
      setState(() => _isRecording = true);
      final mediaService = MediaService();
      await mediaService.startAudioRecording();
      
      // Kayıt bitirme dialog'u göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Ses Kaydediliyor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Kayıt devam ediyor...'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _stopAudioRecording();
              },
              child: const Text('Kayıt Durdur'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isRecording = false);
      _showSnackBar('Ses kaydı başlatılamadı: $e', isError: true);
    }
  }

  Future<void> _stopAudioRecording() async {
    try {
      setState(() => _isRecording = false);
      final mediaService = MediaService();
      final path = await mediaService.stopAudioRecording();
      if (path != null) {
        setState(() {
          _audioPaths.add(path);
          // Ses kaydını medya eklerine ekle
          if (!_attachments.contains(path)) {
            _attachments.add(path);
          }
        });
        _showSnackBar('Ses kaydı tamamlandı');
      }
    } catch (e) {
      _showSnackBar('Ses kaydı kaydedilemedi: $e', isError: true);
    }
  }
}