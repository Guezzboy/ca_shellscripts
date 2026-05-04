import 'package:flutter/material.dart';
import '../../features/badges/widgets/badge_overlay.dart';
import '../../core/repositories/collection_repository.dart';
import '../../core/repositories/owned_item_repository.dart';
import 'badge_service.dart';

typedef ColRepoFactory = CollectionRepository Function();
typedef OwnedRepoFactory = OwnedItemRepository Function();

/// Centralized badge unlock checker.
/// Call after key user actions to evaluate and show new badges.
///
/// Repository parameters default to real instances but can be injected for
/// testing.
class BadgeChecker {
  static ColRepoFactory colRepo = () => CollectionRepository();
  static OwnedRepoFactory ownedRepo = () => OwnedItemRepository();

  /// Show badge overlay if newly unlocked.
  static void _showIfNew(BuildContext context, String badgeId) {
    BadgeService.unlock(badgeId).then((badge) {
      if (badge != null && context.mounted) {
        showBadgeOverlay(
          context,
          emoji: badge.emoji,
          name: badge.name,
          description: badge.description,
        );
      }
    });
  }

  /// Called after the user adds a new item.
  static Future<void> afterAdd(BuildContext context) async {
    final count = await BadgeStats.recordAdd();

    // First add badge
    if (count == 1) {
      _showIfNew(context, 'first_add');
    }

    // Expert: owned items in 3+ collections
    final collections = await colRepo().getAll();
    int colsWithOwned = 0;
    for (final col in collections) {
      final owned = await ownedRepo().countOwned(col.id);
      if (owned > 0) colsWithOwned++;
    }
    if (colsWithOwned >= 3) {
      _showIfNew(context, 'expert');
    }
  }

  /// Called after the user toggles an item as owned.
  static Future<void> afterToggleOwned(
      BuildContext context, String collectionId) async {
    // Collector: check if this collection is now 100% complete
    final collection = await colRepo().getById(collectionId);
    if (collection != null) {
      final totalItems = collection.itemCount;
      final ownedCount = await ownedRepo().countOwned(collectionId);
      if (totalItems > 0 && ownedCount >= totalItems) {
        _showIfNew(context, 'collector');
      }
    }
  }

  /// Called after a photo is added to an item.
  static Future<void> afterAddPhoto(BuildContext context) async {
    final count = await BadgeStats.recordPhoto();
    if (count >= 5) {
      _showIfNew(context, 'photographer');
    }
  }

  /// Called after scanning an ISBN barcode.
  static Future<void> afterScan(BuildContext context) async {
    final count = await BadgeStats.recordScan();
    if (count >= 5) {
      _showIfNew(context, 'detective');
    }
  }

  /// Called after marking items as wanted (pass current wanted count).
  static Future<void> afterWantedChanged(
      BuildContext context, int wantedCount) async {
    await BadgeStats.setWantedCount(wantedCount);
    if (wantedCount >= 10) {
      _showIfNew(context, 'hunter');
    }
  }

  /// Called after exporting collections.
  static void afterExport(BuildContext context) {
    _showIfNew(context, 'backup');
  }
}
