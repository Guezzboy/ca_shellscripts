import 'dart:convert';
import '../models/collection.dart';
import '../models/display_item.dart';
import '../repositories/collection_repository.dart';
import '../repositories/item_repository.dart';

class CollectionExportService {
  final _collectionRepo = CollectionRepository();
  final _itemRepo = ItemRepository();

  /// Exporte toutes les collections avec leurs items et état owned/wanted.
  Future<String> exportAllCollections() async {
    final collections = await _collectionRepo.getAll();
    final exported = <Map<String, dynamic>>[];

    for (final col in collections) {
      exported.add(await _exportCollectionData(col));
    }

    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'collections': exported,
    });
  }

  /// Exporte une seule collection.
  Future<String> exportCollection(String collectionId) async {
    final col = await _collectionRepo.getById(collectionId);
    if (col == null) throw Exception('Collection introuvable');

    return const JsonEncoder.withIndent('  ').convert(
      await _exportCollectionData(col),
    );
  }

  /// Exporte les données brutes (Map) d'une collection.
  Future<Map<String, dynamic>> _exportCollectionData(
      Collection col) async {
    final displayItems = await _itemRepo.getDisplayItems(col.id);

    final items = displayItems.map((di) {
      final item = _itemToJson(di);

      // Ajouter l'état de possession
      item['_state'] = {
        'owned': di.owned,
        if (di.wanted) 'wanted': true,
        if (di.ownedRecordId != null) 'owned_record_id': di.ownedRecordId,
      };

      return item;
    }).toList();

    return {
      'id': col.id,
      'name': col.name,
      'version': col.version,
      'item_count': items.length,
      'source_url': col.sourceUrl,
      'items': items,
    };
  }

  Map<String, dynamic> _itemToJson(DisplayItem di) {
    final map = <String, dynamic>{
      'id': di.id,
      'name': di.name,
      if (di.number != null) 'number': di.number,
      if (di.isCustom) 'is_custom': true,
    };

    // Images
    if (di.imagePaths.isNotEmpty) {
      map['images'] = di.imagePaths;
    } else if (di.imageUrl != null) {
      map['image_url'] = di.imageUrl;
    }

    // Description depuis metadata
    if (di.metadata != null) {
      final m = di.metadata!;
      if (m['description'] != null) map['description'] = m['description'];
      if (m['subtitle'] != null) map['subtitle'] = m['subtitle'];
      if (m['year'] != null) map['year'] = m['year'];
      if (m['series'] != null) map['series'] = m['series'];
    }

    // Book fields
    if (di.isbn != null) map['isbn'] = di.isbn;
    if (di.author != null) map['author'] = di.author;
    if (di.publisher != null) map['publisher'] = di.publisher;
    if (di.publishYear != null) map['publish_year'] = di.publishYear;
    if (di.edition != null) map['edition'] = di.edition;
    if (di.genre != null) map['genre'] = di.genre;
    if (di.condition != null) map['condition'] = di.condition;
    if (di.purchasePrice != null) map['purchase_price'] = di.purchasePrice;
    if (di.estimatedValue != null) map['estimated_value'] = di.estimatedValue;

    return map;
  }
}
