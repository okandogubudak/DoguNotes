import 'dart:convert';
import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.title,
    required super.content,
    required super.category,
    required super.color,
    required super.createdAt,
    required super.updatedAt,
    super.isFavorite,
    super.isImportant,
    super.tags,
    super.attachments,
    super.audioPath,
    super.isPinned,
    super.isArchived,
  });

  @override
  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isImportant,
    List<String>? tags,
    List<String>? attachments,
    String? audioPath,
    bool? isPinned,
    bool? isArchived,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isImportant: isImportant ?? this.isImportant,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      audioPath: audioPath ?? this.audioPath,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isImportant: json['isImportant'] as bool? ?? false,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : [],
      audioPath: json['audioPath'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
      'isImportant': isImportant,
      'tags': tags,
      'attachments': attachments,
      'audioPath': audioPath,
      'isPinned': isPinned,
      'isArchived': isArchived,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      color: map['color'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isFavorite: map['isFavorite'] == 1,
      isImportant: map['isImportant'] == 1,
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      attachments: map['attachments'] != null
          ? List<String>.from(jsonDecode(map['attachments'] as String))
          : [],
      audioPath: map['audioPath'] as String?,
      isPinned: map['isPinned'] == 1,
      isArchived: map['isArchived'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'isImportant': isImportant ? 1 : 0,
      'tags': jsonEncode(tags),
      'attachments': jsonEncode(attachments),
      'audioPath': audioPath,
      'isPinned': isPinned ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
    };
  }

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      category: note.category,
      color: note.color,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isFavorite: note.isFavorite,
      isImportant: note.isImportant,
      tags: note.tags,
      attachments: note.attachments,
      audioPath: note.audioPath,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
    );
  }

  Note toEntity() {
    return Note(
      id: id,
      title: title,
      content: content,
      category: category,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isFavorite: isFavorite,
      isImportant: isImportant,
      tags: tags,
      attachments: attachments,
      audioPath: audioPath,
      isPinned: isPinned,
      isArchived: isArchived,
    );
  }
} 