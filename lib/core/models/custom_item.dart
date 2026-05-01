import 'dart:convert';

class CustomItem {
  final String id;
  final String name;
  final String? number;
  final String collectionId;
  final List<String> imagePaths;
  final String source;
  final int createdAt;

  const CustomItem({
    required this.id,
    required this.name,
    this.number,
    required this.collectionId,
    this.imagePaths = const [],
    required this.source,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'number': number,
        'collection_id': collectionId,
        'image_path': imagePaths.isEmpty ? null : json.encode(imagePaths),
        'source': source,
        'created_at': createdAt,
      };

  factory CustomItem.fromMap(Map<String, dynamic> map) => CustomItem(
        id: map['id'] as String,
        name: map['name'] as String,
        number: map['number'] as String?,
        collectionId: map['collection_id'] as String,
        imagePaths: _parsePaths(map['image_path'] as String?),
        source: map['source'] as String,
        createdAt: map['created_at'] as int,
      );

  static List<String> _parsePaths(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (json.decode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return [raw]; // backward compat: single path stored as plain string
    }
  }
}
