import '../database/dao/chapter_dao.dart';
import '../database/dao/section_dao.dart';
import '../models/chapter.dart';

enum SearchScope { currentChapter, currentVolume, entireBook }

class SearchMatch {
  final int chapterId;
  final String chapterTitle;
  final int matchIndex;
  final int startOffset;
  final int endOffset;

  const SearchMatch({
    required this.chapterId,
    required this.chapterTitle,
    required this.matchIndex,
    required this.startOffset,
    required this.endOffset,
  });
}

class SearchService {
  final ChapterDao _chapterDao = ChapterDao();
  final SectionDao _sectionDao = SectionDao();

  Future<List<SearchMatch>> search(String query, SearchScope scope,
      {int? chapterId, int? sectionId, int? bookId}) async {
    if (query.isEmpty) return [];

    final chapters = <Chapter>[];

    switch (scope) {
      case SearchScope.currentChapter:
        if (chapterId != null) {
          final c = await _chapterDao.getById(chapterId);
          if (c != null) chapters.add(c);
        }
        break;
      case SearchScope.currentVolume:
        if (sectionId != null) {
          chapters.addAll(await _chapterDao.getBySectionId(sectionId));
        }
        break;
      case SearchScope.entireBook:
        if (bookId != null) {
          final sections = await _sectionDao.getByBookId(bookId);
          for (final s in sections) {
            chapters.addAll(await _chapterDao.getBySectionId(s.id!));
          }
        }
        break;
    }

    final matches = <SearchMatch>[];
    int globalIndex = 0;
    final lowerQuery = query.toLowerCase();

    for (final chapter in chapters) {
      final content = chapter.content.toLowerCase();
      int start = 0;
      while ((start = content.indexOf(lowerQuery, start)) != -1) {
        matches.add(SearchMatch(
          chapterId: chapter.id!,
          chapterTitle: chapter.title,
          matchIndex: globalIndex,
          startOffset: start,
          endOffset: start + query.length,
        ));
        start++;
        globalIndex++;
      }
    }

    return matches;
  }

  static int replaceAllInText(String text, String query, String replacement) {
    return text.replaceAll(query, replacement).length;
  }
}
