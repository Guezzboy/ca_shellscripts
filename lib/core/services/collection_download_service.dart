import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../repositories/collection_repository.dart';
import '../repositories/item_repository.dart';

/// Supporte trois formats JSON :
///
/// Format standard :
/// { "name": "...", "version": 1, "items": [...] }
///
/// Format structuré (nouveau) :
/// { "collection": { "id": "...", "name": "...", "totalItems": N }, "items": [...] }
///
/// Format Amora/étendu :
/// { "collection": { "nom": "...", "verres": [...], "marque": "...", ... } }
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
    final response = await _dio.get<dynamic>(url);
    final raw = response.data;
    final data = raw is String
        ? json.decode(raw) as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return importJson(data);
  }

  Future<({String collectionId, int itemCount})> importJson(
      Map<String, dynamic> data) async {
    // Structured format: root-level "items" array alongside "collection" object
    if (data.containsKey('collection') && data.containsKey('items')) {
      return _importStructuredFormat(data);
    }
    // Amora format: items nested inside collection.verres
    if (data.containsKey('collection')) {
      return _importAmoraFormat(data['collection'] as Map<String, dynamic>);
    }
    return _importStandardFormat(data);
  }

  // ── Format structuré ─────────────────────────────────────────────────────

  Future<({String collectionId, int itemCount})> _importStructuredFormat(
      Map<String, dynamic> data) async {
    final col = data['collection'] as Map<String, dynamic>;
    final name = col['name'] as String? ?? 'Collection importée';
    final sourceId = col['id'] as String?;

    final collection = await _collectionRepo.create(name);
    final collectionId = collection.id;
    final baseId = sourceId ?? collectionId;
    final now = DateTime.now().millisecondsSinceEpoch;

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((raw) {
      final map = raw as Map<String, dynamic>;
      final stableId = map['id'] as String?;

      final images = map['images'] as List<dynamic>? ?? [];
      final imageUrl = images.isNotEmpty ? images.first as String? : null;

      final metadata = json.encode({
        'subtitle': map['subtitle'],
        'year': map['year'],
        'series': map['series'],
        'extra_images': images.length > 1 ? images.skip(1).toList() : null,
      });

      return Item(
        id: stableId != null ? '${baseId}_$stableId' : _uuid.v4(),
        baseId: collectionId,
        name: map['name'] as String? ?? 'Item',
        description: map['description'] as String?,
        imageUrl: imageUrl,
        metadata: metadata,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    await _itemRepo.insertBatch(items);
    await _collectionRepo.update(
      collection.copyWith(itemCount: items.length, lastSync: now),
    );
    return (collectionId: collectionId, itemCount: items.length);
  }

  // ── Format standard ───────────────────────────────────────────────────────

  Future<({String collectionId, int itemCount})> _importStandardFormat(
      Map<String, dynamic> data) async {
    final name = data['name'] as String? ?? 'Collection importée';
    final version = data['version'] as int? ?? 1;
    final sourceId = data['id'] as String?;

    final collection = await _collectionRepo.create(name);
    final collectionId = collection.id;
    final baseId = sourceId ?? collectionId;
    final now = DateTime.now().millisecondsSinceEpoch;

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((raw) {
      final map = raw as Map<String, dynamic>;
      final stableId = map['id'] as String?;
      return Item(
        id: stableId != null ? '${baseId}_$stableId' : _uuid.v4(),
        baseId: collectionId,
        name: map['name'] as String? ?? 'Item',
        number: map['number'] as String?,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String?,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    await _itemRepo.insertBatch(items);
    await _collectionRepo.update(
      collection.copyWith(version: version, itemCount: items.length, lastSync: now),
    );
    return (collectionId: collectionId, itemCount: items.length);
  }

  // ── Format Amora (collection.verres) ─────────────────────────────────────

  Future<({String collectionId, int itemCount})> _importAmoraFormat(
      Map<String, dynamic> col) async {
    final name = col['nom'] as String? ?? 'Collection importée';
    final marque = col['marque'] as String?;
    final licence = col['licence'] as String?;

    // Nom enrichi avec marque/licence si disponibles
    final displayName = [name, if (marque != null) marque].join(' — ');

    final collection = await _collectionRepo.create(displayName);
    final collectionId = collection.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    final rawItems = col['verres'] as List<dynamic>? ?? [];
    final items = rawItems.map((raw) {
      final map = raw as Map<String, dynamic>;
      final id = (map['id'] as num).toInt();

      final artworkUrl = map['artwork_url'] as String?;
      final spriteUrl = map['sprite_url'] as String?;
      final imageUrl = (artworkUrl?.isNotEmpty ?? false) ? artworkUrl : spriteUrl;

      // Métadonnées spécifiques stockées en JSON
      final metadata = json.encode({
        'type': map['type'],
        'generation': map['generation'],
        'annee_edition': map['annee_edition'],
        'serie': map['serie'],
        'couleur_dominante': map['couleur_dominante'],
        'rare': map['rare'] ?? false,
        'numero_pokedex': map['numero_pokedex'],
        'sprite_url': spriteUrl,
        'licence': licence,
      });

      return Item(
        id: '${collectionId}_$id',
        baseId: collectionId,
        name: map['pokemon'] as String? ?? 'Item $id',
        number: id.toString().padLeft(3, '0'),
        description: map['serie'] as String?,
        imageUrl: imageUrl,
        metadata: metadata,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    await _itemRepo.insertBatch(items);
    await _collectionRepo.update(
      collection.copyWith(itemCount: items.length, lastSync: now),
    );
    return (collectionId: collectionId, itemCount: items.length);
  }
}
