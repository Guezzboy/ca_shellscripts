class OwnedItem {
  final String id;
  final String itemId;
  final String collectionId;
  final bool owned;
  final String? notes;
  final int addedAt;

  const OwnedItem({
    required this.id,
    required this.itemId,
    required this.collectionId,
    required this.owned,
    this.notes,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'item_id': itemId,
        'collection_id': collectionId,
        'owned': owned ? 1 : 0,
        'notes': notes,
        'added_at': addedAt,
      };

  factory OwnedItem.fromMap(Map<String, dynamic> map) => OwnedItem(
        id: map['id'] as String,
        itemId: map['item_id'] as String,
        collectionId: map['collection_id'] as String,
        owned: (map['owned'] as int) == 1,
        notes: map['notes'] as String?,
        addedAt: map['added_at'] as int,
      );
}
