class Book {
  final int? id;
  final String title;
  final String author;
  final String description;
  final int coverColor;
  final String? coverImage;
  final int? lastChapterId;
  final int wordCount;
  final String createdAt;
  final String updatedAt;
  final int sortOrder;

  const Book({
    this.id,
    this.title = '未命名作品',
    this.author = '',
    this.description = '',
    this.coverColor = 0xFFEADDFF,
    this.coverImage,
    this.lastChapterId,
    this.wordCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
  });

  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? description,
    int? coverColor,
    String? coverImage,
    int? lastChapterId,
    int? wordCount,
    String? createdAt,
    String? updatedAt,
    int? sortOrder,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverColor: coverColor ?? this.coverColor,
      coverImage: coverImage ?? this.coverImage,
      lastChapterId: lastChapterId ?? this.lastChapterId,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'author': author,
      'description': description,
      'cover_color': coverColor,
      'cover_image': coverImage,
      'last_chapter_id': lastChapterId,
      'word_count': wordCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sort_order': sortOrder,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '未命名作品',
      author: map['author'] as String? ?? '',
      description: map['description'] as String? ?? '',
      coverColor: map['cover_color'] as int? ?? 0xFFEADDFF,
      coverImage: map['cover_image'] as String?,
      lastChapterId: map['last_chapter_id'] as int?,
      wordCount: map['word_count'] as int? ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
