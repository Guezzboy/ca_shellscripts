class Item {
  final String id;
  final String baseId;
  final String name;
  final String? number;
  final String? description;
  final String? imageUrl;
  final String? metadata;
  final int createdAt;
  final int updatedAt;

  const Item({
    required this.id,
    required this.baseId,
    required this.name,
    this.number,
    this.description,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'base_id': baseId,
        'name': name,
        'number': number,
        'description': description,
        'image_url': imageUrl,
        'metadata': metadata,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        id: map['id'] as String,
        baseId: map['base_id'] as String,
        name: map['name'] as String,
        number: map['number'] as String?,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String?,
        metadata: map['metadata'] as String?,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );
}
