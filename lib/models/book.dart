class Book {
  final int? id;
  final String title;
  final String author;
  final String description;
  final int coverColor;
  final int wordCount;
  final String status;
  final String createdAt;
  final String updatedAt;
  final int sortOrder;

  const Book({
    this.id,
    this.title = '未命名作品',
    this.author = '',
    this.description = '',
    this.coverColor = 0xFFEADDFF,
    this.wordCount = 0,
    this.status = 'active',
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
    int? wordCount,
    String? status,
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
      wordCount: wordCount ?? this.wordCount,
      status: status ?? this.status,
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
      'word_count': wordCount,
      'status': status,
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
      wordCount: map['word_count'] as int? ?? 0,
      status: map['status'] as String? ?? 'active',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
