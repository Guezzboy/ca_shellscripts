import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/collection_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/owned_item_repository.dart';
import '../repositories/custom_item_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>(
  (_) => CollectionRepository(),
);

final itemRepositoryProvider = Provider<ItemRepository>(
  (_) => ItemRepository(),
);

final ownedItemRepositoryProvider = Provider<OwnedItemRepository>(
  (_) => OwnedItemRepository(),
);

final customItemRepositoryProvider = Provider<CustomItemRepository>(
  (_) => CustomItemRepository(),
);
