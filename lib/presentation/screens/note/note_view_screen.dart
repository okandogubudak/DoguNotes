import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../data/models/note_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notes_provider.dart';
import '../../../core/services/category_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/services/tts_service.dart';
import 'package:video_player/video_player.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../../widgets/full_screen_video_viewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_note_screen.dart';
import 'package:path/path.dart' as path;
import 'package:open_filex/open_filex.dart';


class NoteViewScreen extends StatefulWidget {
  final NoteModel note;
  final VoidCallback? onNoteUpdated;

  const NoteViewScreen({
    super.key,
    required this.note,
    this.onNoteUpdated,
  });

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen>
    with TickerProviderStateMixin {
  final TtsService _ttsService = TtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;
  bool _isSpeaking = false;
  bool _isPlayingAudio = false;
  final bool _isPlayingVideo = false;
  
  Map<String, Map<String, dynamic>> _categories = {};
  bool _categoriesLoaded = false;
  late NoteModel _currentNote;
  
  // Professional Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _initializeProfessionalAnimations();
    _loadCategories();
    _initializeServices();
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('tr_TR', null);
  }

  void _initializeProfessionalAnimations() {
    // Slide animation for entry
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Scale animation for interactive elements
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _loadCategories() async {
    try {
      final categoryService = CategoryService.instance;
      _categories = await categoryService.loadCategories();
      if (mounted) {
        setState(() {
          _categoriesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _categoriesLoaded = true;
        });
      }
    }
  }

  Future<void> _initializeServices() async {
    await _ttsService.initialize();
    
    // Initialize audio player listener
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlayingAudio = false;
      });
    });
    
    // Initialize video if exists
    if (_currentNote.attachments.isNotEmpty) {
      for (String attachment in _currentNote.attachments) {
        if (_isVideoFile(attachment)) {
          _videoController = VideoPlayerController.file(File(attachment));
          await _videoController!.initialize();
          break;
        }
      }
    }
  }

  bool _isVideoFile(String path) {
    final extensions = ['.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv'];
    return extensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  bool _isImageFile(String path) {
    final extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return extensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  bool _isAudioFile(String path) {
    final extensions = ['.mp3', '.wav', '.aac', '.m4a', '.flac'];
    return extensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _audioPlayer.dispose();
    _videoController?.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(isDarkMode),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode ? [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
            ] : [
              const Color(0xFFF8FAFC),
              const Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildNoteHeader(isDarkMode),
                  const SizedBox(height: 24),
                  _buildNoteContent(isDarkMode),
                  const SizedBox(height: 24),
                  if (_currentNote.attachments.isNotEmpty || (_currentNote.audioPath != null && _currentNote.audioPath!.isNotEmpty))
                    _buildMediaSection(isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _currentNote.isArchived
          ? null
          : FloatingActionButton(
              heroTag: 'actions',
              backgroundColor: const Color(0xFF3B82F6),
              onPressed: () => _showActionSheet(isDarkMode),
              child: const Icon(Icons.more_horiz_rounded, color: Colors.white),
            ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isDarkMode) {
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
        'Not Görüntüle',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      actions: _currentNote.isArchived ? null : [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF334155),
          ),
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          onSelected: (String value) {
            switch (value) {
              case 'pdf':
                _generatePDF();
                break;
              case 'share':
                _shareNote();
                break;
              case 'archive':
                _archiveNote();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'pdf',
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 12),
                  Text(
                    'PDF Dışa Aktar',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  const Icon(Icons.share_rounded, color: Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  Text(
                    'Paylaş',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'archive',
              child: Row(
                children: [
                  const Icon(Icons.archive_rounded, color: Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  Text(
                    'Arşive Gönder',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNoteHeader(bool isDarkMode) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_categoriesLoaded && _categories.isNotEmpty)
                DropdownButton<String>(
                  value: _currentNote.category,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  elevation: 2,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(8),
                  onChanged: (String? newValue) async {
                    if (newValue != null && newValue != _currentNote.category) {
                      // Notun kategorisini güncelle
                      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                      final updated = await notesProvider.updateNoteCategory(_currentNote.id, newValue);
                      if (updated) {
                        setState(() {
                          _currentNote = _currentNote.copyWith(category: newValue);
                        });
                      }
                    }
                  },
                  items: _categories.keys.map<DropdownMenuItem<String>>((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key),
                    );
                  }).toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentNote.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              const Spacer(),
              if (_currentNote.isPinned)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: const Icon(
                    Icons.push_pin_rounded,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              if (_currentNote.isFavorite)
                const Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentNote.title.isNotEmpty ? _currentNote.title : 'Başlıksız Not',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          
          // Etiketler
          if (_currentNote.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentNote.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF10B981),
                  ),
                ),
              )).toList(),
            ),
          ],
          
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                'Oluşturulma: ${_formatDate(_currentNote.createdAt)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          if (_currentNote.updatedAt != _currentNote.createdAt) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Güncelleme: ${_formatDate(_currentNote.updatedAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteContent(bool isDarkMode) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'İçerik',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  color: const Color(0xFF10B981),
                ),
                onPressed: _toggleTTS,
                tooltip: _isSpeaking ? 'Okumayı Durdur' : 'Sesli Oku',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SelectableText(
            _currentNote.content.isNotEmpty ? _currentNote.content : 'İçerik bulunmuyor',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Düzenle butonu
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6)),
                ),
                title: const Text('Düzenle'),
                subtitle: const Text('Notu düzenle'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddNoteScreen(noteToEdit: _currentNote),
                    ),
                  );
                  if (result != null && result is NoteModel) {
                    setState(() {
                      _currentNote = result;
                    });
                    widget.onNoteUpdated?.call();
                  }
                },
              ),
              
              const SizedBox(height: 8),
              
              // Sil butonu
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
                ),
                title: const Text('Sil'),
                subtitle: const Text('Notu sil'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog();
                },
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Şimdi';
        }
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notu Sil'),
        content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Dialog'u kapat
              try {
                final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                await notesProvider.deleteNote(_currentNote.id);
                _showSnackBar('Not silindi');
                Navigator.pop(context); // Note view'ı kapat
              } catch (e) {
                _showSnackBar('Not silinemedi: $e', isError: true);
              }
            },
            child: const Text('Sil', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  // Share operations
  void _shareNote() async {
    try {
      final content = '''
${_currentNote.title}

${_currentNote.content}

${_currentNote.tags.isNotEmpty ? '\nEtiketler: ${_currentNote.tags.map((tag) => '#$tag').join(' ')}' : ''}

DoguNotes ile oluşturuldu
''';
      
      await Share.share(content, subject: _currentNote.title);
    } catch (e) {
      debugPrint('Error sharing note: $e');
    }
  }

  // PDF generation
  Future<void> _generatePDF() async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final List<pw.Widget> imageWidgets = [];
      for (final path in _currentNote.attachments) {
        if (path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.jpeg') || path.toLowerCase().endsWith('.png')) {
          final file = File(path);
          if (await file.exists()) {
            final image = pw.MemoryImage(await file.readAsBytes());
            imageWidgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 12),
                child: pw.Center(child: pw.Image(image, width: 300)),
              ),
            );
          }
        }
      }
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Oluşturulma: ${DateFormat('dd.MM.yyyy HH:mm').format(_currentNote.createdAt)}',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    _currentNote.title,
                    style: pw.TextStyle(font: fontBold, fontSize: 22),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  _currentNote.content,
                  style: pw.TextStyle(font: font, fontSize: 14),
                  textAlign: pw.TextAlign.center,
                ),
                if (_currentNote.tags.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Etiketler: ${_currentNote.tags.map((tag) => '#$tag').join(' ')}',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
                ...imageWidgets,
              ],
            );
          },
        ),
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint('Error generating PDF: $e');
    }
  }

  Widget _buildMediaSection(bool isDarkMode) {
    final attachments = _currentNote.attachments;
    final audioPath = _currentNote.audioPath;
    
    // Tüm medya dosyalarını birleştir - dublicate'leri önle
    Set<String> allMediaFilesSet = {};
    if (attachments.isNotEmpty) {
      allMediaFilesSet.addAll(attachments);
    }
    if (audioPath != null && audioPath.isNotEmpty && !allMediaFilesSet.contains(audioPath)) {
      allMediaFilesSet.add(audioPath);
    }
    
    final List<String> allMediaFiles = allMediaFilesSet.toList();
    
    if (allMediaFiles.isEmpty) {
      return Container();
    }
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attachment_rounded,
                color: const Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ekler (${allMediaFiles.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: allMediaFiles.length,
            itemBuilder: (context, index) {
              final filePath = allMediaFiles[index];
              return _buildMediaThumbnail(filePath, isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaThumbnail(String filePath, bool isDarkMode) {
    final file = File(filePath);
    final fileName = path.basename(filePath);
    
    return GestureDetector(
      onTap: () => _openMediaFile(filePath),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: _buildThumbnailContent(filePath, fileName, isDarkMode),
        ),
      ),
    );
  }

  Widget _buildThumbnailContent(String filePath, String fileName, bool isDarkMode) {
    if (_isImageFile(filePath)) {
      return FutureBuilder<bool>(
        future: File(filePath).exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              File(filePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFileIcon(Icons.broken_image_rounded, fileName, isDarkMode);
              },
            );
          } else {
            return _buildFileIcon(Icons.image_rounded, fileName, isDarkMode);
          }
        },
      );
    } else if (_isVideoFile(filePath)) {
      return _buildFileIcon(Icons.play_circle_filled_rounded, fileName, isDarkMode);
    } else if (_isAudioFile(filePath)) {
      return _buildAudioFileIcon(filePath, fileName, isDarkMode);
    } else {
      return _buildFileIcon(Icons.description_rounded, fileName, isDarkMode);
    }
  }

  Widget _buildFileIcon(IconData icon, String fileName, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 4),
          Text(
            fileName.length > 12 ? '${fileName.substring(0, 9)}...' : fileName,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioFileIcon(String filePath, String fileName, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 32,
                color: const Color(0xFF10B981),
              ),
              if (_isPlayingAudio)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fileName.length > 12 ? '${fileName.substring(0, 9)}...' : fileName,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _openMediaFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      _showSnackBar('Dosya bulunamadı', isError: true);
      return;
    }

    try {
      await OpenFilex.open(filePath);
    } catch (e) {
      _showSnackBar('Dosya açılamadı: $e', isError: true);
    }
  }

  Future<void> _playAudio(String audioPath) async {
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.stop();
        setState(() {
          _isPlayingAudio = false;
        });
      } else {
        await _audioPlayer.play(DeviceFileSource(audioPath));
        setState(() {
          _isPlayingAudio = true;
        });
      }
    } catch (e) {
      _showSnackBar('Ses dosyası çalınamadı: $e', isError: true);
    }
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

  Future<void> _archiveNote() async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Arşive Gönder'),
          content: const Text('Bu notu arşive göndermek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Arşive Gönder', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        ),
      );

      if (result == true) {
        final notesProvider = Provider.of<NotesProvider>(context, listen: false);
        final success = await notesProvider.archiveNote(_currentNote.id);
        
        if (success) {
          _showSnackBar('Not arşive gönderildi');
          Navigator.pop(context);
        } else {
          _showSnackBar('Arşive gönderilirken hata oluştu', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Arşive gönderilirken hata oluştu: $e', isError: true);
    }
  }

  void _toggleTTS() async {
    try {
      if (_isSpeaking) {
        await _ttsService.stop();
        setState(() {
          _isSpeaking = false;
        });
      } else {
        final textToSpeak = _currentNote.content.isNotEmpty ? _currentNote.content : 'İçerik bulunmuyor';
        await _ttsService.speak(textToSpeak);
        setState(() {
          _isSpeaking = true;
        });
      }
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }
}

