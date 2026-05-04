import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A badge that can be unlocked by the user.
class Badge {
  final String id;
  final String emoji;
  final String name;
  final String description;

  const Badge({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
  });
}

/// All available badges with their unlock criteria.
class BadgeDefinitions {
  static const all = [
    Badge(
      id: 'first_add',
      emoji: '🏆',
      name: 'Premier pas',
      description: 'Tu as ajouté ton premier objet à une collection.',
    ),
    Badge(
      id: 'collector',
      emoji: '📚',
      name: 'Collectionneur',
      description: 'Tu as complété une collection à 100%.',
    ),
    Badge(
      id: 'hunter',
      emoji: '🔍',
      name: 'Chasseur de trésors',
      description: 'Tu as marqué 10 objets comme recherchés.',
    ),
    Badge(
      id: 'photographer',
      emoji: '📷',
      name: 'Photographe',
      description: 'Tu as ajouté des photos à 5 objets.',
    ),
    Badge(
      id: 'expert',
      emoji: '🌟',
      name: 'Expert',
      description: 'Tu as des objets dans 3 collections différentes.',
    ),
    Badge(
      id: 'detective',
      emoji: '🔬',
      name: 'Détective',
      description: 'Tu as scanné 5 codes-barres ISBN.',
    ),
    Badge(
      id: 'backup',
      emoji: '💾',
      name: 'Sauvegarde',
      description: 'Tu as exporté ta collection.',
    ),
  ];

  static Badge? byId(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Persists unlocked badges and triggers overlay display.
class BadgeService {
  static const _unlockedKey = 'badges_unlocked';
  static const _unlockedAtKey = 'badges_unlocked_at';

  /// Returns the set of unlocked badge IDs.
  static Future<Set<String>> unlockedBadgeIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_unlockedKey) ?? [];
    return list.toSet();
  }

  /// Returns all unlocked Badge objects.
  static Future<List<Badge>> unlockedBadges() async {
    final ids = await unlockedBadgeIds();
    return ids.map((id) => BadgeDefinitions.byId(id)).whereType<Badge>().toList();
  }

  /// Unlock a badge and return it if it was newly unlocked.
  /// Returns null if already unlocked or badge doesn't exist.
  static Future<Badge?> unlock(String badgeId) async {
    final badge = BadgeDefinitions.byId(badgeId);
    if (badge == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList(_unlockedKey) ?? [];
    if (unlocked.contains(badgeId)) return null; // already unlocked

    unlocked.add(badgeId);
    await prefs.setStringList(_unlockedKey, unlocked);

    // Store unlock timestamp
    final atMap = _decodeAtMap(prefs);
    atMap[badgeId] = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_unlockedAtKey, json.encode(atMap));

    return badge;
  }

  /// Returns the most recently unlocked badge, or null if none unlocked yet.
  static Future<Badge?> lastUnlockedBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final atMap = _decodeAtMap(prefs);
    if (atMap.isEmpty) return null;

    // Find the badge with the highest timestamp
    String? lastId;
    int lastTs = 0;
    for (final entry in atMap.entries) {
      if (entry.value > lastTs) {
        lastTs = entry.value;
        lastId = entry.key;
      }
    }
    return lastId != null ? BadgeDefinitions.byId(lastId) : null;
  }

  /// Check if a badge is already unlocked.
  static Future<bool> isUnlocked(String badgeId) async {
    final ids = await unlockedBadgeIds();
    return ids.contains(badgeId);
  }

  static Map<String, int> _decodeAtMap(SharedPreferences prefs) {
    final raw = prefs.getString(_unlockedAtKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }
}

/// Stat counters persisted across sessions for badge criteria.
class BadgeStats {
  static const _totalAddsKey = 'badge_stats_total_adds';
  static const _totalPhotosKey = 'badge_stats_total_photos';
  static const _totalScansKey = 'badge_stats_total_scans';
  static const _wantedCountKey = 'badge_stats_wanted_count';

  static Future<int> _get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  static Future<int> _set(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    return value;
  }

  static Future<int> _increment(String key, [int amount = 1]) async {
    final current = await _get(key);
    return _set(key, current + amount);
  }

  // ── Public API ──

  static Future<int> get totalAdds => _get(_totalAddsKey);
  static Future<int> get totalPhotos => _get(_totalPhotosKey);
  static Future<int> get totalScans => _get(_totalScansKey);
  static Future<int> get wantedCount => _get(_wantedCountKey);

  static Future<int> recordAdd() => _increment(_totalAddsKey);
  static Future<int> recordPhoto() => _increment(_totalPhotosKey);
  static Future<int> recordScan() => _increment(_totalScansKey);
  static Future<int> recordWanted() => _increment(_wantedCountKey);
  static Future<int> setWantedCount(int count) => _set(_wantedCountKey, count);
}
