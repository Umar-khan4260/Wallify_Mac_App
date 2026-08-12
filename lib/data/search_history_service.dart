import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that persists the user's recent search terms in
/// SharedPreferences.
///
/// Ordered most-recent-first, capped at [maxEntries] (oldest dropped when
/// exceeded). Widgets can listen to [listenable] with a
/// [ValueListenableBuilder] to rebuild reactively.
class SearchHistoryService {
  SearchHistoryService._();
  static final SearchHistoryService instance = SearchHistoryService._();

  static const String _prefsKey = 'search_history';

  /// Maximum number of search terms kept, most recent first.
  static const int maxEntries = 10;

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Live list of recent search terms (most recent first). Call
  /// [ValueListenableBuilder] on this to rebuild reactively.
  final ValueNotifier<List<String>> listenable = ValueNotifier([]);

  /// Call once at startup (e.g. in [main]) before using the service.
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    _reload();
  }

  /// Adds [query] to the front of the history. Trims and ignores empty input;
  /// dedupes case-insensitively (existing matches are moved to the front
  /// rather than duplicated); drops the oldest entry when over [maxEntries].
  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final list = List<String>.from(listenable.value);
    list.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    list.insert(0, trimmed);
    if (list.length > maxEntries) {
      list.removeRange(maxEntries, list.length);
    }
    listenable.value = list;
    await _persist();
  }

  /// Removes a single entry (case-insensitive match), persisting only when
  /// something was actually removed.
  Future<void> removeOne(String query) async {
    final list = List<String>.from(listenable.value);
    final trimmed = query.trim();
    list.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    if (list.length == listenable.value.length) return;
    listenable.value = list;
    await _persist();
  }

  /// Empties the history and removes the persisted key.
  Future<void> clearHistory() async {
    if (listenable.value.isEmpty) return;
    listenable.value = [];
    await _persist();
  }

  // ── private helpers ────────────────────────────────────────────────────────

  void _reload() {
    final saved = _prefs.getStringList(_prefsKey) ?? const [];
    final list = saved
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(maxEntries)
        .toList();
    listenable.value = list;
  }

  Future<void> _persist() async {
    if (listenable.value.isEmpty) {
      await _prefs.remove(_prefsKey);
    } else {
      await _prefs.setStringList(_prefsKey, listenable.value);
    }
  }
}
