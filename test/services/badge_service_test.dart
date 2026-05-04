import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection_app/core/services/badge_service.dart';

void main() {
  group('BadgeService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('unlock — unlocks a badge and returns it', () async {
      final badge = await BadgeService.unlock('first_add');

      expect(badge, isNotNull);
      expect(badge!.id, 'first_add');
      expect(badge.name, 'Premier pas');
    });

    test('unlock — returns null for unknown badge id', () async {
      final badge = await BadgeService.unlock('nonexistent');
      expect(badge, isNull);
    });

    test('unlock — returns null if already unlocked', () async {
      await BadgeService.unlock('first_add');
      final second = await BadgeService.unlock('first_add');

      expect(second, isNull);
    });

    test('isUnlocked — returns true for unlocked badge', () async {
      await BadgeService.unlock('first_add');
      expect(await BadgeService.isUnlocked('first_add'), isTrue);
    });

    test('isUnlocked — returns false for locked badge', () async {
      expect(await BadgeService.isUnlocked('collector'), isFalse);
    });

    test('lastUnlockedBadge — returns most recently unlocked badge', () async {
      await Future.delayed(const Duration(milliseconds: 5));
      await BadgeService.unlock('first_add');
      await Future.delayed(const Duration(milliseconds: 5));
      await BadgeService.unlock('photographer');

      final last = await BadgeService.lastUnlockedBadge();

      expect(last, isNotNull);
      expect(last!.id, 'photographer');
    });

    test('lastUnlockedBadge — returns null when no badges unlocked', () async {
      final last = await BadgeService.lastUnlockedBadge();
      expect(last, isNull);
    });

    test('unlockedBadgeIds — returns set of unlocked IDs', () async {
      await BadgeService.unlock('first_add');
      await BadgeService.unlock('detective');

      final ids = await BadgeService.unlockedBadgeIds();

      expect(ids, containsAll(['first_add', 'detective']));
      expect(ids.length, 2);
    });

    test('unlockedBadges — returns Badge objects for unlocked IDs', () async {
      await BadgeService.unlock('first_add');
      await BadgeService.unlock('backup');

      final badges = await BadgeService.unlockedBadges();

      expect(badges.length, 2);
      expect(badges.map((b) => b.id), containsAll(['first_add', 'backup']));
    });
  });
}
