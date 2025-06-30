class Note {
  final String id;
  final String title;
  final String content;
  final String category;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final bool isImportant;
  final List<String> tags;
  final List<String> attachments;
  final String? audioPath;
  final bool isPinned;
  final bool isArchived;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.isImportant = false,
    this.tags = const [],
    this.attachments = const [],
    this.audioPath,
    this.isPinned = false,
    this.isArchived = false,
  });

  Note copyWith({
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
    return Note(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 