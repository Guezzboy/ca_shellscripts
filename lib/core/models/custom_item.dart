class CustomItem {
  final String id;
  final String name;
  final String? number;
  final String collectionId;
  final String? imagePath;
  final String source; // 'photo' | 'manual' | 'import'
  final int createdAt;

  const CustomItem({
    required this.id,
    required this.name,
    this.number,
    required this.collectionId,
    this.imagePath,
    required this.source,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'number': number,
        'collection_id': collectionId,
        'image_path': imagePath,
        'source': source,
        'created_at': createdAt,
      };

  factory CustomItem.fromMap(Map<String, dynamic> map) => CustomItem(
        id: map['id'] as String,
        name: map['name'] as String,
        number: map['number'] as String?,
        collectionId: map['collection_id'] as String,
        imagePath: map['image_path'] as String?,
        source: map['source'] as String,
        createdAt: map['created_at'] as int,
      );
}
