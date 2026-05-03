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
    List<String> imagePaths = const [],
    required String source,
  }) async {
    final customRepo = ref.read(customItemRepositoryProvider);
    final collectionRepo = ref.read(collectionRepositoryProvider);
    await customRepo.create(
      name: name,
      number: number,
      collectionId: arg,
      imagePaths: imagePaths,
      source: source,
    );
    await collectionRepo.updateItemCount(arg);
    ref.invalidateSelf();
    ref.invalidate(ownedCountProvider(arg));
  }

  Future<void> deleteCustomItem(String itemId) async {
    final customRepo = ref.read(customItemRepositoryProvider);
    final collectionRepo = ref.read(collectionRepositoryProvider);
    await customRepo.delete(itemId);
    await collectionRepo.updateItemCount(arg);
    ref.invalidateSelf();
    ref.invalidate(ownedCountProvider(arg));
  }

  Future<void> toggleWanted(DisplayItem item) async {
    if (item.isCustom) return;
    final repo = ref.read(itemRepositoryProvider);
    await repo.toggleWanted(item.id, !item.wanted);
    ref.invalidateSelf();
  }

  /// Cycle state: neutral → wanted → owned → neutral
  Future<void> cycleState(DisplayItem item) async {
    if (item.isCustom) return;
    final ownedRepo = ref.read(ownedItemRepositoryProvider);
    final itemRepo = ref.read(itemRepositoryProvider);

    if (!item.owned && !item.wanted) {
      // neutral → wanted
      await itemRepo.toggleWanted(item.id, true);
    } else if (item.wanted && !item.owned) {
      // wanted → owned (clear wanted first)
      await itemRepo.toggleWanted(item.id, false);
      await ownedRepo.markOwned(item.id, arg);
    } else {
      // owned → neutral (also clear wanted if set)
      if (item.wanted) {
        await itemRepo.toggleWanted(item.id, false);
      }
      if (item.ownedRecordId != null) {
        await ownedRepo.markUnowned(item.ownedRecordId!);
      }
    }
    ref.invalidateSelf();
    ref.invalidate(ownedCountProvider(arg));
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
              wanted: i.wanted,
            ))
        .toList();
  },
);
