import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection.dart';
import 'repository_providers.dart';

// All collections list
final collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
        CollectionsNotifier.new);

class CollectionsNotifier extends AsyncNotifier<List<Collection>> {
  @override
  Future<List<Collection>> build() async {
    final repo = ref.watch(collectionRepositoryProvider);
    return repo.getAll();
  }

  Future<Collection> create(String name, {String? sourceUrl}) async {
    final repo = ref.read(collectionRepositoryProvider);
    final collection = await repo.create(name, sourceUrl: sourceUrl);
    ref.invalidateSelf();
    return collection;
  }

  Future<void> delete(String id) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Single collection by ID
final collectionByIdProvider =
    FutureProvider.family<Collection?, String>((ref, id) async {
  final repo = ref.watch(collectionRepositoryProvider);
  return repo.getById(id);
});

// Owned count for a collection
final ownedCountProvider =
    FutureProvider.family<int, String>((ref, collectionId) async {
  final repo = ref.watch(ownedItemRepositoryProvider);
  return repo.countOwned(collectionId);
});
