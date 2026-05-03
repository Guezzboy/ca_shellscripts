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

  // Book-specific optional fields
  final String? isbn;
  final String? author;
  final String? publisher;
  final String? publishYear;
  final String? edition;
  final String? genre;
  final String? condition;
  final double? purchasePrice;
  final double? estimatedValue;
  final bool wanted;

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
    this.isbn,
    this.author,
    this.publisher,
    this.publishYear,
    this.edition,
    this.genre,
    this.condition,
    this.purchasePrice,
    this.estimatedValue,
    this.wanted = false,
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
        'isbn': isbn,
        'author': author,
        'publisher': publisher,
        'publish_year': publishYear,
        'edition': edition,
        'genre': genre,
        'condition': condition,
        'purchase_price': purchasePrice,
        'estimated_value': estimatedValue,
        'wanted': wanted ? 1 : 0,
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
        isbn: map['isbn'] as String?,
        author: map['author'] as String?,
        publisher: map['publisher'] as String?,
        publishYear: map['publish_year'] as String?,
        edition: map['edition'] as String?,
        genre: map['genre'] as String?,
        condition: map['condition'] as String?,
        purchasePrice: map['purchase_price'] is double
            ? map['purchase_price'] as double
            : (map['purchase_price'] as num?)?.toDouble(),
        estimatedValue: map['estimated_value'] is double
            ? map['estimated_value'] as double
            : (map['estimated_value'] as num?)?.toDouble(),
        wanted: (map['wanted'] as int?) == 1,
      );
}
