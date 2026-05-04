/// Returns an emoji icon for a collection based on its name.
String emojiFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('verre') || n.contains('moutarde')) return '\u{1F377}';
  if (n.contains('manga') || n.contains('one piece') || n.contains('livre')) {
    return '\u{1F4DA}';
  }
  if (n.contains('carte') || n.contains('pok\u00e9mon') || n.contains('pokemon')) {
    return '\u{1F3B4}';
  }
  if (n.contains('vinyl') || n.contains('pif')) return '\u{1F4BF}';
  if (n.contains('pin')) return '\u{1F4CC}';
  return '\u{1F4E6}';
}
