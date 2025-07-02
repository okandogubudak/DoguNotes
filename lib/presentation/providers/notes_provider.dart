import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/database_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/export_service.dart';
import '../../data/models/note_model.dart';


class NotesProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<NoteModel> _notes = [];
  List<NoteModel> _filteredNotes = [];
  List<NoteModel> _archivedNotes = [];
  List<NoteModel> _filteredArchivedNotes = [];
  String _selectedCategory = 'Genel';
  String _searchQuery = '';
  String _archiveSearchQuery = '';
  bool _isLoading = false;

  // Getters
  List<NoteModel> get notes => _filteredNotes;
  List<NoteModel> get allNotes => _notes;
  List<NoteModel> get archivedNotes => _filteredArchivedNotes;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get archiveSearchQuery => _archiveSearchQuery;
  bool get isLoading => _isLoading;

  // Load all notes
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Veritabanı katmanında `getAllNotes()` yalnızca arşivlenmemiş notları getiriyor.
      // Bu nedenle arşivlenmiş notları ayrıca çekmemiz gerekiyor.
      final nonArchivedNotes = await _databaseService.getAllNotes(); // isArchived = 0
      _archivedNotes = await _databaseService.getArchivedNotes(); // isArchived = 1

      _notes = nonArchivedNotes;
      _applyFilters();
      _applyArchiveFilters();
    } catch (e) {
      print('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new note
  Future<bool> addNote({
    required String title,
    required String content,
    String category = 'Personal',
    String color = '#7DD3FC',
    List<String> tags = const [],
    List<String> attachments = const [],
    String? audioPath,
    bool isFavorite = false,
    bool isImportant = false,
    bool isPinned = false,
  }) async {
    try {
      final now = DateTime.now();
      final note = NoteModel(
        id: _uuid.v4(),
        title: title,
        content: content,
        category: category,
        color: color,
        createdAt: now,
        updatedAt: now,
        tags: tags,
        attachments: attachments,
        audioPath: audioPath,
        isFavorite: isFavorite,
        isImportant: isImportant,
        isPinned: isPinned,
      );

      final result = await _databaseService.insertNote(note);
      if (result > 0) {
        _notes.insert(0, note);
        _applyFilters();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding note: $e');
      return false;
    }
  }

  // Update note
  Future<bool> updateNote(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      final result = await _databaseService.updateNote(updatedNote);
      
      if (result > 0) {
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = updatedNote;
          _applyFilters();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  // Delete note
  Future<bool> deleteNote(String noteId) async {
    try {
      final result = await _databaseService.deleteNote(noteId);
      if (result > 0) {
        _notes.removeWhere((note) => note.id == noteId);
        _applyFilters();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String noteId) async {
    try {
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final note = _notes[noteIndex];
        final updatedNote = note.copyWith(
          isFavorite: !note.isFavorite,
          updatedAt: DateTime.now(),
        );
        
        final result = await _databaseService.updateNote(updatedNote);
        if (result > 0) {
          _notes[noteIndex] = updatedNote;
          _applyFilters();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Toggle important
  Future<bool> toggleImportant(String noteId) async {
    try {
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final note = _notes[noteIndex];
        final updatedNote = note.copyWith(
          isImportant: !note.isImportant,
          updatedAt: DateTime.now(),
        );
        
        final result = await _databaseService.updateNote(updatedNote);
        if (result > 0) {
          _notes[noteIndex] = updatedNote;
          _applyFilters();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error toggling important: $e');
      return false;
    }
  }

  // Update note category
  Future<bool> updateNoteCategory(String noteId, String newCategory) async {
    try {
      // Tek notu transfer et (renk ile birlikte)
      final result = await _databaseService.transferSingleNoteToCategory(noteId, newCategory);
      
      if (result > 0) {
        final noteIndex = _notes.indexWhere((note) => note.id == noteId);
        if (noteIndex != -1) {
          final note = _notes[noteIndex];
          
          // Yeni kategorinin rengini al
          final newColor = AppConstants.getCategoryColor(newCategory);
          
          final updatedNote = note.copyWith(
            category: newCategory,
            color: newColor,
            updatedAt: DateTime.now(),
          );
          _notes[noteIndex] = updatedNote;
          _applyFilters();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating note category: $e');
      return false;
    }
  }

  // Toggle pin
  Future<bool> togglePin(String noteId) async {
    try {
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final note = _notes[noteIndex];
        final updatedNote = note.copyWith(
          isPinned: !note.isPinned,
          updatedAt: DateTime.now(),
        );
        
        final result = await _databaseService.updateNote(updatedNote);
        if (result > 0) {
          _notes[noteIndex] = updatedNote;
          _applyFilters();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error toggling pin: $e');
      return false;
    }
  }

  // Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Refresh notes after category operations
  Future<void> refreshNotesAfterCategoryOperation() async {
    try {
      final allNotes = await _databaseService.getAllNotes();
      _notes = allNotes.where((note) => !note.isArchived).toList();
      _archivedNotes = allNotes.where((note) => note.isArchived).toList();
      _applyFilters();
      _applyArchiveFilters();
      notifyListeners();
    } catch (e) {
      print('Error refreshing notes after category operation: $e');
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Set archive search query
  void setArchiveSearchQuery(String query) {
    _archiveSearchQuery = query;
    _applyArchiveFilters();
    notifyListeners();
  }

  // Apply filters
  void _applyFilters() {
    List<NoteModel> filtered = List.from(_notes);

    // Filter out archived notes (only show non-archived)
    filtered = filtered.where((note) => !note.isArchived).toList();

    // Apply category filter
    if (_selectedCategory != 'Genel') {
      filtered = filtered.where((note) => note.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) =>
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sıralama mantığı
    if (_selectedCategory == 'Genel') {
      // Genel kategoride en yeni not (createdAt) her zaman üstte
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // Diğer kategorilerde: pin → favori → son güncelleme
      filtered.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        if (a.isPinned && b.isPinned) {
          return a.createdAt.compareTo(b.createdAt);
        }

        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;

        return b.updatedAt.compareTo(a.updatedAt);
      });
    }

    _filteredNotes = filtered;
  }

  // Get note by id
  NoteModel? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notes count by category
  int getNotesCountByCategory(String category) {
    final nonArchivedNotes = _notes.where((note) => !note.isArchived).toList();
    
    if (category == 'Genel') return nonArchivedNotes.length;
    return nonArchivedNotes.where((note) => note.category == category).length;
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // Refresh notes
  Future<void> refreshNotes() async {
    await loadNotes();
  }

  // Refresh method for any external changes
  Future<void> refresh() async {
    await loadNotes();
  }

  // Share notes to external apps
  Future<bool> shareNotes() async {
    try {
      final notificationService = NotificationService();
      
      // Create backup data
      final backupData = {
        'app_name': AppConstants.appName,
        'app_version': AppConstants.appVersion,
        'export_date': DateTime.now().toIso8601String(),
        'notes_count': _notes.length,
        'notes': _notes.map((note) => note.toMap()).toList(),
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);
      
      // Get temporary directory and create file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'notes_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      // Write file
      await file.writeAsString(jsonString);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Notlarınızın yedeği - ${_notes.length} not',
        subject: 'Notes Backup - ${AppConstants.appName}',
      );
      
      return true;
    } catch (e) {
      print('Error sharing notes: $e');
      return false;
    }
  }

  // Export notes to JSON
  Future<bool> exportNotes() async {
    try {
      final notificationService = NotificationService();
      
      // Create backup data
      final backupData = {
        'app_name': AppConstants.appName,
        'app_version': AppConstants.appVersion,
        'export_date': DateTime.now().toIso8601String(),
        'notes_count': _notes.length,
        'notes': _notes.map((note) => note.toMap()).toList(),
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);
      
      // Get documents directory and create file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'notes_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      // Write file
      await file.writeAsString(jsonString);
      
      // Share the file so user can save it where they want
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Notlarınızın yedeği - ${_notes.length} not',
        subject: 'Notes Backup - ${AppConstants.appName}',
      );
      
      // Show success notification
      await notificationService.showNotification(
        id: 1002,
        title: 'Dışa Aktarma Tamamlandı',
        body: '${_notes.length} not dışa aktarıldı ve paylaşım menüsü açıldı',
      );
      
      return true;
    } catch (e) {
      print('Error exporting notes: $e');
      final notificationService = NotificationService();
      await notificationService.showNotification(
        id: 1003,
        title: 'Dışa Aktarma Başarısız',
        body: 'Notlar dışa aktarılırken bir hata oluştu: $e',
      );
      return false;
    }
  }

  // Import notes from JSON
  Future<bool> importNotes() async {
    try {
      final notificationService = NotificationService();
      
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup data
      if (!backupData.containsKey('notes') || 
          !backupData.containsKey('app_name') || 
          backupData['app_name'] != AppConstants.appName) {
        throw Exception('Geçersiz yedek dosyası formatı');
      }

      final notesList = backupData['notes'] as List<dynamic>;
      
      // Import notes
      int importedCount = 0;
      for (final noteMap in notesList) {
        try {
          // Create new note with new ID to avoid conflicts
          final noteModel = NoteModel.fromMap(noteMap);
          final newNote = NoteModel(
            id: _uuid.v4(),
            title: noteModel.title,
            content: noteModel.content,
            category: noteModel.category,
            color: noteModel.color,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isFavorite: noteModel.isFavorite,
            isImportant: noteModel.isImportant,
            tags: noteModel.tags,
            attachments: noteModel.attachments,
            audioPath: noteModel.audioPath,
            isPinned: noteModel.isPinned,
            isArchived: noteModel.isArchived,
          );
          
          final result = await _databaseService.insertNote(newNote);
          if (result > 0) {
            importedCount++;
          }
        } catch (e) {
          print('Error importing note: $e');
          continue;
        }
      }

      // Reload notes
      await loadNotes();
      
      // Show success notification
      await notificationService.showNotification(
        id: 1004,
        title: 'İçe Aktarma Tamamlandı',
        body: '$importedCount not başarıyla içe aktarıldı',
      );
      
      return importedCount > 0;
    } catch (e) {
      print('Error importing notes: $e');
      final notificationService = NotificationService();
      await notificationService.showNotification(
        id: 1005,
        title: 'İçe Aktarma Başarısız',
        body: 'Notlar içe aktarılırken bir hata oluştu',
      );
      return false;
    }
  }

  // Backup notes automatically
  Future<void> autoBackup() async {
    try {
      final notificationService = NotificationService();
      
      // Create backup data
      final backupData = {
        'app_name': AppConstants.appName,
        'app_version': AppConstants.appVersion,
        'backup_date': DateTime.now().toIso8601String(),
        'notes_count': _notes.length,
        'notes': _notes.map((note) => note.toMap()).toList(),
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);
      
      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'auto_backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');
      
      // Write file
      await file.writeAsString(jsonString);
      
      // Keep only last 5 backups
      await _cleanupOldBackups(backupDir);
      
      // Show success notification
      await notificationService.showBackupSuccessNotification();
      
    } catch (e) {
      print('Error in auto backup: $e');
      final notificationService = NotificationService();
      await notificationService.showBackupFailedNotification();
    }
  }

  // Clean up old backup files
  Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir.list().where((entity) => 
          entity is File && entity.path.endsWith('.json')).toList();
      
      if (files.length > 5) {
        // Sort by modification date
        files.sort((a, b) => 
            (a as File).lastModifiedSync().compareTo((b as File).lastModifiedSync()));
        
        // Delete older files
        for (int i = 0; i < files.length - 5; i++) {
          await (files[i] as File).delete();
        }
      }
    } catch (e) {
      print('Error cleaning up backups: $e');
    }
  }

  // Get backup files
  Future<List<File>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!await backupDir.exists()) {
        return [];
      }
      
      final files = await backupDir.list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      // Sort by modification date (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      print('Error getting backup files: $e');
      return [];
    }
  }

  // Restore from backup file
  Future<bool> restoreFromBackup(File backupFile) async {
    try {
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup data
      if (!backupData.containsKey('notes') || 
          !backupData.containsKey('app_name') || 
          backupData['app_name'] != AppConstants.appName) {
        throw Exception('Geçersiz yedek dosyası formatı');
      }

      // Clear existing notes
      await _databaseService.clearAllData();
      _notes.clear();

      final notesList = backupData['notes'] as List<dynamic>;
      
      // Restore notes
      int restoredCount = 0;
      for (final noteMap in notesList) {
        try {
          final noteModel = NoteModel.fromMap(noteMap);
          final result = await _databaseService.insertNote(noteModel);
          if (result > 0) {
            restoredCount++;
          }
        } catch (e) {
          print('Error restoring note: $e');
          continue;
        }
      }

      // Reload notes
      await loadNotes();
      
      final notificationService = NotificationService();
      await notificationService.showNotification(
        id: 1006,
        title: 'Geri Yükleme Tamamlandı',
        body: '$restoredCount not başarıyla geri yüklendi',
      );
      
      return restoredCount > 0;
    } catch (e) {
      print('Error restoring from backup: $e');
      final notificationService = NotificationService();
      await notificationService.showNotification(
        id: 1007,
        title: 'Geri Yükleme Başarısız',
        body: 'Yedekten geri yükleme sırasında bir hata oluştu',
      );
      return false;
    }
  }

  // Archive methods
  Future<void> loadArchivedNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _archivedNotes = await _databaseService.getArchivedNotes();
      _applyArchiveFilters();
    } catch (e) {
      print('Error loading archived notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> archiveNote(String noteId) async {
    try {
      print('Archiving note with ID: $noteId');
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final note = _notes[noteIndex];
        print('Found note to archive: ${note.title}');
        final archivedNote = note.copyWith(
          updatedAt: DateTime.now(),
          isArchived: true,
        );
        
        final result = await _databaseService.updateNote(archivedNote);
        print('Database update result: $result');
        if (result > 0) {
          _notes.removeAt(noteIndex);
          _archivedNotes.add(archivedNote);
          print('Added to archived notes. Total archived: ${_archivedNotes.length}');
          _applyFilters();
          _applyArchiveFilters();
          notifyListeners();
          return true;
        }
      } else {
        print('Note not found in _notes list');
      }
      return false;
    } catch (e) {
      print('Error archiving note: $e');
      return false;
    }
  }

  Future<bool> unarchiveNote(String noteId) async {
    try {
      final noteIndex = _archivedNotes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final note = _archivedNotes[noteIndex];
        final unarchivedNote = note.copyWith(
          updatedAt: DateTime.now(),
          isArchived: false,
        );
        
        final result = await _databaseService.updateNote(unarchivedNote);
        if (result > 0) {
          _archivedNotes.removeAt(noteIndex);
          _notes.add(unarchivedNote);
          _applyArchiveFilters();
          _applyFilters();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error unarchiving note: $e');
      return false;
    }
  }

  void searchArchivedNotes(String query) {
    _archiveSearchQuery = query;
    _applyArchiveFilters();
    notifyListeners();
  }

  void clearArchiveSearch() {
    _archiveSearchQuery = '';
    _applyArchiveFilters();
    notifyListeners();
  }

  void _applyArchiveFilters() {
    _filteredArchivedNotes = _archivedNotes.where((note) {
      final matchesSearch = _archiveSearchQuery.isEmpty ||
          note.title.toLowerCase().contains(_archiveSearchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_archiveSearchQuery.toLowerCase());
      
      return matchesSearch;
    }).toList();

    // Sort by pinned first, then favorites, then updated date
    _filteredArchivedNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      if (a.isPinned && b.isPinned) {
        return a.createdAt.compareTo(b.createdAt);
      }

      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;

      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  // Export single note as PDF with Turkish character support
  Future<bool> exportNoteToPdf(NoteModel note) async {
    try {
      final pdf = pw.Document();
      
      // Use PDF Google Fonts that support Turkish characters
      final ttf = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with app logo and title
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey400, width: 2),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            note.title.isNotEmpty ? note.title : 'Başlıksız Not',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue100,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Text(
                              note.category,
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 12,
                                color: PdfColors.blue800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Oluşturulma: ${_formatDate(note.createdAt)}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          if (note.updatedAt != note.createdAt)
                            pw.Text(
                              'Güncelleme: ${_formatDate(note.updatedAt)}',
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 24),
                
                // Content section
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NOT İÇERİĞİ',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        note.content.isNotEmpty ? note.content : 'İçerik bulunmuyor.',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 14,
                          lineSpacing: 1.5,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tags section
                if (note.tags.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  pw.Text(
                    'ETİKETLER',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: note.tags.map((tag) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange100,
                        borderRadius: pw.BorderRadius.circular(16),
                        border: pw.Border.all(color: PdfColors.orange300),
                      ),
                      child: pw.Text(
                        tag,
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                          color: PdfColors.orange800,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                
                // Attachments info
                if (note.attachments.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  pw.Text(
                    'EKLER',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  ...note.attachments.map((attachment) {
                    final fileName = attachment.split('/').last;
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green100,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColors.green300),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Icon(pw.IconData(0xe226), color: PdfColors.green600, size: 16),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            fileName,
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: PdfColors.green800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                
                // Audio info
                if (note.audioPath != null) ...[
                  pw.SizedBox(height: 24),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.purple100,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.purple300),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Icon(pw.IconData(0xe3a3), color: PdfColors.purple600, size: 16),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'Ses kaydı mevcut',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            color: PdfColors.purple800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Footer
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey400, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${AppConstants.appName} v${AppConstants.appVersion}',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            'PDF oluşturulma: ${_formatDate(DateTime.now())}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 9,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Sayfa 1/1',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Save PDF with Turkish-safe filename
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeTitle = note.title
          .replaceAll(RegExp(r'[^\w\s-.]'), '_')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();
      final fileName = 'not_${safeTitle.isNotEmpty ? safeTitle : 'isimsiz'}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      
      // PDF oluşturma ve paylaşma - her zaman sadece PDF
      final exportService = ExportService();
      final pdfBytes = await exportService.createNotePDF(note, includeImages: true);
      
      if (pdfBytes != null) {
        await file.writeAsBytes(pdfBytes);
        
        // PDF'i paylaş (görseller ve medya dahil)
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '📄 ${note.title}\n\nPDF formatında not paylaşımı (görseller dahil)',
          subject: note.title,
        );
      } else {
        // Basit PDF paylaş
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '📄 ${note.title}\n\nPDF formatında not paylaşımı',
          subject: note.title,
        );
      }
      
      return true;
    } catch (e) {
      print('Error exporting note to PDF: $e');
      return false;
    }
  }
  


  // Export single note as PDF
  Future<bool> exportNoteInAppFormat(NoteModel note) async {
    try {
      final exportService = ExportService();
      final directory = await getApplicationDocumentsDirectory();
      
      // PDF olarak export et
      final pdfPath = await exportService.exportNoteAsPDF(
        note: note,
        exportPath: directory.path,
        includeImages: true,
      );
      
      if (pdfPath != null) {
        // PDF dosyasını paylaş
        await Share.shareXFiles(
          [XFile(pdfPath)],
          text: '📄 ${note.title} - PDF formatında not (görseller dahil)\n\nDoguNotes ile oluşturuldu.',
          subject: note.title,
        );
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error exporting note as PDF: $e');
      return false;
    }
  }

  // Share note as PDF (with embedded images)
  Future<bool> shareNoteWithAttachments(NoteModel note) async {
    try {
      final exportService = ExportService();
      final directory = await getApplicationDocumentsDirectory();
      
      // PDF olarak export et (tüm görseller dahil)
      final pdfPath = await exportService.exportNoteAsPDF(
        note: note,
        exportPath: directory.path,
        includeImages: true,
      );
      
      if (pdfPath != null) {
        // PDF dosyasını paylaş (görseller PDF içine gömülü)
        await Share.shareXFiles(
          [XFile(pdfPath)],
          text: '📄 ${note.title} - PDF formatında not\n\n✅ Tüm görseller PDF içine gömülü\n📝 İçerik ve medya dahil\n\nDoguNotes ile oluşturuldu.',
          subject: note.title,
        );
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error sharing note as PDF: $e');
      return false;
    }
  }

  // Format date helper
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 