class WordCounter {
  static int count(String text) {
    if (text.isEmpty) return 0;
    return text.replaceAll(RegExp(r'\s+'), '').length;
  }

  static Map<String, int> detailedStats(String text) {
    return {
      'charCount': text.replaceAll(RegExp(r'\s+'), '').length,
      'charWithSpace': text.length,
      'paragraphCount':
          text.isEmpty ? 0 : text.split(RegExp(r'\n\s*\n')).length,
      'lineCount': text.isEmpty ? 0 : '\n'.allMatches(text).length + 1,
    };
  }
}
