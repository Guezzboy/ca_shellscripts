class Collection {
  final String id;
  final String name;
  final String? sourceUrl;
  final int version;
  final int itemCount;
  final int? lastSync;
  final int createdAt;

  const Collection({
    required this.id,
    required this.name,
    this.sourceUrl,
    this.version = 1,
    this.itemCount = 0,
    this.lastSync,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'source_url': sourceUrl,
        'version': version,
        'item_count': itemCount,
        'last_sync': lastSync,
        'created_at': createdAt,
      };

  factory Collection.fromMap(Map<String, dynamic> map) => Collection(
        id: map['id'] as String,
        name: map['name'] as String,
        sourceUrl: map['source_url'] as String?,
        version: map['version'] as int? ?? 1,
        itemCount: map['item_count'] as int? ?? 0,
        lastSync: map['last_sync'] as int?,
        createdAt: map['created_at'] as int,
      );

  Collection copyWith({
    String? name,
    String? sourceUrl,
    int? version,
    int? itemCount,
    int? lastSync,
  }) =>
      Collection(
        id: id,
        name: name ?? this.name,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        version: version ?? this.version,
        itemCount: itemCount ?? this.itemCount,
        lastSync: lastSync ?? this.lastSync,
        createdAt: createdAt,
      );
}
