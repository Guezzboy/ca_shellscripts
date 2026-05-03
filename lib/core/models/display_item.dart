/// Unified DTO for displaying both base items and custom items in the grid.
class DisplayItem {
  final String id;
  final String name;
  final String? number;
  final String? imageUrl;
  final List<String> imagePaths; // local paths for custom items (multi-photo)
  final bool owned;
  final bool isCustom;
  final bool isRare;
  final Map<String, dynamic>? metadata;

  /// ID of the owned_items record (null if base item not owned or if custom).
  final String? ownedRecordId;

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

  const DisplayItem({
    required this.id,
    required this.name,
    this.number,
    this.imageUrl,
    this.imagePaths = const [],
    required this.owned,
    required this.isCustom,
    this.isRare = false,
    this.metadata,
    this.ownedRecordId,
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

  String? get firstImagePath =>
      imagePaths.isNotEmpty ? imagePaths.first : null;

  DisplayItem copyWith({
    bool? owned,
    String? ownedRecordId,
    String? isbn,
    String? author,
    String? publisher,
    String? publishYear,
    String? edition,
    String? genre,
    String? condition,
    double? purchasePrice,
    double? estimatedValue,
    bool? wanted,
  }) =>
      DisplayItem(
        id: id,
        name: name,
        number: number,
        imageUrl: imageUrl,
        imagePaths: imagePaths,
        owned: owned ?? this.owned,
        isCustom: isCustom,
        isRare: isRare,
        metadata: metadata,
        ownedRecordId: ownedRecordId ?? this.ownedRecordId,
        isbn: isbn ?? this.isbn,
        author: author ?? this.author,
        publisher: publisher ?? this.publisher,
        publishYear: publishYear ?? this.publishYear,
        edition: edition ?? this.edition,
        genre: genre ?? this.genre,
        condition: condition ?? this.condition,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        estimatedValue: estimatedValue ?? this.estimatedValue,
        wanted: wanted ?? this.wanted,
      );
}
