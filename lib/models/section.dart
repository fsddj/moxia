class Section {
  final int? id;
  final int bookId;
  final String title;
  final String description;
  final int wordCount;
  final String createdAt;
  final String updatedAt;
  final int sortOrder;

  const Section({
    this.id,
    required this.bookId,
    this.title = '新卷',
    this.description = '',
    this.wordCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
  });

  Section copyWith({
    int? id,
    int? bookId,
    String? title,
    String? description,
    int? wordCount,
    String? createdAt,
    String? updatedAt,
    int? sortOrder,
  }) {
    return Section(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      description: description ?? this.description,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'book_id': bookId,
      'title': title,
      'description': description,
      'word_count': wordCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sort_order': sortOrder,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id'] as int?,
      bookId: map['book_id'] as int,
      title: map['title'] as String? ?? '新卷',
      description: map['description'] as String? ?? '',
      wordCount: map['word_count'] as int? ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
