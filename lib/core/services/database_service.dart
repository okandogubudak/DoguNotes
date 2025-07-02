import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/models/note_model.dart';
import '../constants/app_constants.dart';
import '../services/category_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        color TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        isImportant INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        attachments TEXT,
        audioPath TEXT,
        isPinned INTEGER NOT NULL DEFAULT 0,
        isArchived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create index for better performance
    await db.execute('CREATE INDEX idx_notes_category ON notes(category)');
    await db.execute('CREATE INDEX idx_notes_created_at ON notes(createdAt)');
    await db.execute('CREATE INDEX idx_notes_updated_at ON notes(updatedAt)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add isArchived column
      await db.execute('ALTER TABLE notes ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0');
    }
  }

  // Insert a new note
  Future<int> insertNote(NoteModel note) async {
    final db = await database;
    try {
      await db.insert(
        'notes',
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return 1;
    } catch (e) {
      print('Error inserting note: $e');
      return 0;
    }
  }

  // Get all notes (excluding archived)
  Future<List<NoteModel>> getAllNotes() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'isArchived = ?',
        whereArgs: [0],
        orderBy: 'isPinned DESC, updatedAt DESC',
      );
      return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting all notes: $e');
      return [];
    }
  }

  // Get notes by category
  Future<List<NoteModel>> getNotesByCategory(String category) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: category == 'all' ? 'isArchived = ?' : 'category = ? AND isArchived = ?',
        whereArgs: category == 'all' ? [0] : [category, 0],
        orderBy: 'isPinned DESC, updatedAt DESC',
      );
      return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting notes by category: $e');
      return [];
    }
  }

  // Get favorite notes
  Future<List<NoteModel>> getFavoriteNotes() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'isFavorite = ? AND isArchived = ?',
        whereArgs: [1, 0],
        orderBy: 'isPinned DESC, updatedAt DESC',
      );
      return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting favorite notes: $e');
      return [];
    }
  }

  // Get important notes
  Future<List<NoteModel>> getImportantNotes() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'isImportant = ? AND isArchived = ?',
        whereArgs: [1, 0],
        orderBy: 'isPinned DESC, updatedAt DESC',
      );
      return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting important notes: $e');
      return [];
    }
  }

  // Get archived notes
  Future<List<NoteModel>> getArchivedNotes() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'isArchived = ?',
        whereArgs: [1],
        orderBy: 'updatedAt DESC',
      );
      return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting archived notes: $e');
      return [];
    }
  }

  // Update a note
  Future<int> updateNote(NoteModel note) async {
    final db = await database;
    try {
      return await db.update(
        'notes',
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
    } catch (e) {
      print('Error updating note: $e');
      return 0;
    }
  }

  // Delete a note
  Future<int> deleteNote(String id) async {
    final db = await database;
    try {
      return await db.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting note: $e');
      return 0;
    }
  }

  // Search notes
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      // Şifrelenmiş veride LIKE sorgusu çalışmayacağından, tüm notları
      // çekip bellek içinde filtreleme yapıyoruz.
      final notes = await getAllNotes();
      final lower = query.toLowerCase();
      return notes.where((note) =>
          note.title.toLowerCase().contains(lower) ||
          note.content.toLowerCase().contains(lower)).toList();
    } catch (e) {
      print('Error searching notes: $e');
      return [];
    }
  }

  // Get note by id
  Future<NoteModel?> getNoteById(String id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return NoteModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting note by id: $e');
      return null;
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Clear all notes (for testing purposes)
  Future<void> clearAllNotes() async {
    final db = await database;
    await db.delete('notes');
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('notes');
  }

  // Get notes count by category
  Future<int> getNotesCountByCategory(String category) async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notes WHERE category = ? AND isArchived = ?',
        [category, 0],
      );
      return result.first['count'] as int;
    } catch (e) {
      print('Error getting notes count by category: $e');
      return 0;
    }
  }

  // Delete all notes by category
  Future<int> deleteNotesByCategory(String category) async {
    final db = await database;
    try {
      return await db.delete(
        'notes',
        where: 'category = ?',
        whereArgs: [category],
      );
    } catch (e) {
      print('Error deleting notes by category: $e');
      return 0;
    }
  }

  // Update note category
  Future<int> updateNoteCategory(String noteId, String newCategory) async {
    final db = await database;
    try {
      return await db.update(
        'notes',
        {'category': newCategory, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      print('Error updating note category: $e');
      return 0;
    }
  }

  // Update note color
  Future<int> updateNoteColor(String noteId, String newColor) async {
    final db = await database;
    try {
      return await db.update(
        'notes',
        {'color': newColor, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      print('Error updating note color: $e');
      return 0;
    }
  }

  // Transfer all notes from one category to another
  Future<int> transferNotesToCategory(String fromCategory, String toCategory) async {
    final db = await database;
    try {
      // Hedef kategorinin bilgilerini al
      final categoryService = CategoryService.instance;
      final categories = await categoryService.loadCategories();
      final targetCategoryData = categories[toCategory];
      
      String newColor = '#7DD3FC'; // Varsayılan renk
      if (targetCategoryData != null && targetCategoryData['color'] != null) {
        newColor = targetCategoryData['color'] as String;
      } else {
        // AppConstants'tan varsayılan rengi al
        newColor = AppConstants.getCategoryColor(toCategory);
      }
      
      print('Transferring notes from $fromCategory to $toCategory with color $newColor');
      
      // Kategori ve rengi birlikte güncelle
      final result = await db.update(
        'notes',
        {
          'category': toCategory,
          'color': newColor,
          'updatedAt': DateTime.now().toIso8601String()
        },
        where: 'category = ?',
        whereArgs: [fromCategory],
      );
      
      print('Transfer completed: $result notes updated');
      return result;
    } catch (e) {
      print('Error transferring notes to category: $e');
      return 0;
    }
  }
  
  // Transfer single note to category
  Future<int> transferSingleNoteToCategory(String noteId, String toCategory) async {
    final db = await database;
    try {
      // Hedef kategorinin bilgilerini al
      final categoryService = CategoryService.instance;
      final categories = await categoryService.loadCategories();
      final targetCategoryData = categories[toCategory];
      
      String newColor = '#7DD3FC'; // Varsayılan renk
      if (targetCategoryData != null && targetCategoryData['color'] != null) {
        newColor = targetCategoryData['color'] as String;
      } else {
        // AppConstants'tan varsayılan rengi al
        newColor = AppConstants.getCategoryColor(toCategory);
      }
      
      // Tek notu güncelle
      return await db.update(
        'notes',
        {
          'category': toCategory,
          'color': newColor,
          'updatedAt': DateTime.now().toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      print('Error transferring single note to category: $e');
      return 0;
    }
  }

  // Update all notes color by category (yeni metod)
  Future<int> updateNotesColorByCategory(String category, String newColor) async {
    final db = await database;
    try {
      print('DatabaseService - Updating notes color for category: $category to $newColor');
      
      final result = await db.update(
        'notes',
        {
          'color': newColor,
          'updatedAt': DateTime.now().toIso8601String()
        },
        where: 'category = ?',
        whereArgs: [category],
      );
      
      print('DatabaseService - Updated $result notes with new color');
      return result;
    } catch (e) {
      print('Error updating notes color by category: $e');
      return 0;
    }
  }

  // Taşı: Sadece arşivli notları belirtilen kategoriden hedef kategoriye aktar
  Future<int> moveArchivedNotes(String fromCategory, String toCategory) async {
    final db = await database;
    try {
      // Hedef kategorinin rengini al
      final categoryService = CategoryService.instance;
      final categories = await categoryService.loadCategories();
      var newColor = '#7DD3FC';
      final target = categories[toCategory];
      if (target != null && target['color'] != null) {
        newColor = target['color'] as String;
      }

      return await db.update(
        'notes',
        {
          'category': toCategory,
          'color': newColor,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'category = ? AND isArchived = ?',
        whereArgs: [fromCategory, 1],
      );
    } catch (e) {
      print('Error moving archived notes: $e');
      return 0;
    }
  }

  // Sil: Sadece arşivlenmemiş notları belirtilen kategoriden sil
  Future<int> deleteNonArchivedNotes(String category) async {
    final db = await database;
    try {
      return await db.delete(
        'notes',
        where: 'category = ? AND isArchived = ?',
        whereArgs: [category, 0],
      );
    } catch (e) {
      print('Error deleting non-archived notes: $e');
      return 0;
    }
  }
} 