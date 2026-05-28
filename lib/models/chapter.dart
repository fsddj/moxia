class Chapter {
  final int? id;
  final int sectionId;
  final String title;
  final String content;
  final int wordCount;
  final String status;
  final String createdAt;
  final String updatedAt;
  final int sortOrder;

  const Chapter({
    this.id,
    required this.sectionId,
    this.title = '未命名章节',
    this.content = '',
    this.wordCount = 0,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
  });

  Chapter copyWith({
    int? id,
    int? sectionId,
    String? title,
    String? content,
    int? wordCount,
    String? status,
    String? createdAt,
    String? updatedAt,
    int? sortOrder,
  }) {
    return Chapter(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      title: title ?? this.title,
      content: content ?? this.content,
      wordCount: wordCount ?? this.wordCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'section_id': sectionId,
      'title': title,
      'content': content,
      'word_count': wordCount,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sort_order': sortOrder,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] as int?,
      sectionId: map['section_id'] as int,
      title: map['title'] as String? ?? '未命名章节',
      content: map['content'] as String? ?? '',
      wordCount: map['word_count'] as int? ?? 0,
      status: map['status'] as String? ?? 'draft',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
