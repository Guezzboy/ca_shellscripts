import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection.dart';
import '../models/item.dart';
import '../services/badge_service.dart';
import 'repository_providers.dart';

/// Aggregated stats for the home screen.
class HomeStats {
  final int totalItems;
  final int totalOwned;
  final Item? lastAddedItem;
  final String? lastAddedCollectionName;
  final Map<String, dynamic>? lastAddedCustom;
  final Badge? lastBadge;
  /// List of (collectionName, count) for items added yesterday.
  final List<({String name, int count})> yesterdayEntries;

  const HomeStats({
    required this.totalItems,
    required this.totalOwned,
    this.lastAddedItem,
    this.lastAddedCollectionName,
    this.lastAddedCustom,
    this.lastBadge,
    required this.yesterdayEntries,
  });

  double get percentage => totalItems > 0 ? totalOwned / totalItems : 0.0;
}

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

/// Aggregated home screen stats (total items, owned, recent activity).
final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final colRepo = ref.watch(collectionRepositoryProvider);
  final itemRepo = ref.watch(itemRepositoryProvider);
  final ownedRepo = ref.watch(ownedItemRepositoryProvider);
  final collections = await colRepo.getAll();

  // Total items and owned across all collections
  int totalItems = 0;
  int totalOwned = 0;
  for (final col in collections) {
    totalItems += col.itemCount;
    totalOwned += await ownedRepo.countOwned(col.id);
  }

  // Most recent item (base or custom)
  Item? lastItem;
  String? lastItemColName;
  final recentBase = await itemRepo.getMostRecentBase(1);
  final recentCustom = await itemRepo.getMostRecentCustom(1);

  final baseTs = recentBase.isNotEmpty ? recentBase.first.createdAt : 0;
  final customTs =
      recentCustom.isNotEmpty ? recentCustom.first['created_at'] as int : 0;

  Map<String, dynamic>? lastCustom;
  if (baseTs > 0 || customTs > 0) {
    if (baseTs >= customTs) {
      lastItem = recentBase.first;
      // Find collection name by base_id
      final col = collections.cast<Collection?>().firstWhere(
            (c) => c?.id == lastItem!.baseId,
            orElse: () => null,
          );
      lastItemColName = col?.name;
    }
    if (customTs > baseTs) {
      lastItem = null;
      lastItemColName = null;
      lastCustom = recentCustom.first;
      final col = collections.cast<Collection?>().firstWhere(
            (c) => c?.id == lastCustom!['collection_id'],
            orElse: () => null,
          );
      lastItemColName = col?.name;
    }
  }

  // Most recent badge
  final lastBadge = await BadgeService.lastUnlockedBadge();

  // Yesterday's activity
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));
  final yesterdayById = await itemRepo.countAddedBetween(
    yesterdayStart.millisecondsSinceEpoch,
    todayStart.millisecondsSinceEpoch,
  );

  // Resolve collection names for yesterday's counts
  final yesterdayEntries = <({String name, int count})>[];
  for (final entry in yesterdayById.entries) {
    final col = collections.cast<Collection?>().firstWhere(
          (c) => c?.id == entry.key,
          orElse: () => null,
        );
    if (col != null) {
      yesterdayEntries.add((name: col.name, count: entry.value));
    }
  }

  return HomeStats(
    totalItems: totalItems,
    totalOwned: totalOwned,
    lastAddedItem: lastItem,
    lastAddedCollectionName: lastItemColName,
    lastAddedCustom: lastCustom,
    lastBadge: lastBadge,
    yesterdayEntries: yesterdayEntries,
  );
});
