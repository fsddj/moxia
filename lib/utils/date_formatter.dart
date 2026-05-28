class DateFormatter {
  static String format(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';

    return '${date.year}年${date.month}月${date.day}日';
  }

  static String fullDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}年${date.month}月${date.day}日 $hour:$minute';
  }

  static String shortTime(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
