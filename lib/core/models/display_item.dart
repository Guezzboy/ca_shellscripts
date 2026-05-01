/// Unified DTO for displaying both base items and custom items in the grid.
class DisplayItem {
  final String id;
  final String name;
  final String? number;
  final String? imageUrl;
  final List<String> imagePaths; // local paths for custom items (multi-photo)
  final bool owned;
  final bool isCustom;

  /// ID of the owned_items record (null if base item not owned or if custom).
  final String? ownedRecordId;

  const DisplayItem({
    required this.id,
    required this.name,
    this.number,
    this.imageUrl,
    this.imagePaths = const [],
    required this.owned,
    required this.isCustom,
    this.ownedRecordId,
  });

  String? get firstImagePath =>
      imagePaths.isNotEmpty ? imagePaths.first : null;
}
