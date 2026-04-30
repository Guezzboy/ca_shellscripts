import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/display_item.dart';
import '../repositories/item_repository.dart';
import '../repositories/owned_item_repository.dart';
import '../repositories/custom_item_repository.dart';
import '../repositories/collection_repository.dart';
import 'repository_providers.dart';
import 'collection_providers.dart';

// Items for a given collection (base + custom, with owned status)
final collectionItemsProvider =
    AsyncNotifierProvider.family<CollectionItemsNotifier, List<DisplayItem>, String>(
        CollectionItemsNotifier.new);

class CollectionItemsNotifier
    extends FamilyAsyncNotifier<List<DisplayItem>, String> {
  @override
  Future<List<DisplayItem>> build(String arg) async {
    final repo = ref.watch(itemRepositoryProvider);
    return repo.getDisplayItems(arg);
  }

  Future<void> toggleOwned(DisplayItem item) async {
    if (item.isCustom) return;
    final ownedRepo = ref.read(ownedItemRepositoryProvider);
    if (item.owned && item.ownedRecordId != null) {
      await ownedRepo.markUnowned(item.ownedRecordId!);
    } else if (!item.owned) {
      await ownedRepo.markOwned(item.id, arg);
    }
    ref.invalidateSelf();
    // Also refresh owned count
    ref.invalidate(ownedCountProvider(arg));
  }

  Future<void> addCustomItem({
    required String name,
    String? number,
    String? imagePath,
    required String source,
  }) async {
    final customRepo = ref.read(customItemRepositoryProvider);
    final collectionRepo = ref.read(collectionRepositoryProvider);
    await customRepo.create(
      name: name,
      number: number,
      collectionId: arg,
      imagePath: imagePath,
      source: source,
    );
    await collectionRepo.updateItemCount(arg);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Search within a collection's base items
final itemSearchProvider =
    FutureProvider.family<List<DisplayItem>, ({String collectionId, String query})>(
  (ref, params) async {
    if (params.query.isEmpty) return [];
    final repo = ref.watch(itemRepositoryProvider);
    final items = await repo.searchByName(params.collectionId, params.query);
    return items
        .map((i) => DisplayItem(
              id: i.id,
              name: i.name,
              number: i.number,
              imageUrl: i.imageUrl,
              owned: false,
              isCustom: false,
            ))
        .toList();
  },
);
