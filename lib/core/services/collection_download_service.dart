import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../repositories/collection_repository.dart';
import '../repositories/item_repository.dart';

/// Expected JSON format from a remote collection source:
/// {
///   "id": "stable-collection-id",      // optional — used as base_id
///   "name": "Collection Name",
///   "version": 1,
///   "items": [
///     {
///       "id": "item-stable-id",         // optional
///       "name": "Item name",
///       "number": "001",
///       "description": "Optional desc",
///       "image_url": "https://..."
///     }
///   ]
/// }
class CollectionDownloadService {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
  final _uuid = const Uuid();
  final _collectionRepo = CollectionRepository();
  final _itemRepo = ItemRepository();

  Future<({String collectionId, int itemCount})> downloadFromUrl(
      String url) async {
    final response = await _dio.get<Map<String, dynamic>>(url);
    final data = response.data!;
    return _importData(data);
  }

  Future<({String collectionId, int itemCount})> importJson(
      Map<String, dynamic> data) async {
    return _importData(data);
  }

  Future<({String collectionId, int itemCount})> _importData(
      Map<String, dynamic> data) async {
    final name = data['name'] as String? ?? 'Collection importée';
    final version = data['version'] as int? ?? 1;
    final sourceId = data['id'] as String?;

    // Create or update the collection
    final collection = await _collectionRepo.create(name);
    final collectionId = collection.id;
    final baseId = sourceId ?? collectionId;

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;

    final items = rawItems.map((rawItem) {
      final map = rawItem as Map<String, dynamic>;
      final stableId = map['id'] as String?;
      return Item(
        id: stableId != null ? '${baseId}_$stableId' : _uuid.v4(),
        baseId: collectionId,
        name: map['name'] as String? ?? 'Item sans nom',
        number: map['number'] as String?,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String?,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    await _itemRepo.insertBatch(items);
    await _collectionRepo.update(
      collection.copyWith(
        version: version,
        itemCount: items.length,
        lastSync: now,
      ),
    );

    return (collectionId: collectionId, itemCount: items.length);
  }
}
