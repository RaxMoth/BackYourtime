import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Persistence key ────────────────────────────────────────────────────────
const _kShieldDailyLog = 'shield_daily_log';

// ── Provider ───────────────────────────────────────────────────────────────

/// Exposes a date → active-shield-count map for the contribution grid.
final shieldActivityProvider =
    AsyncNotifierProvider<ShieldActivityNotifier, Map<String, int>>(
      ShieldActivityNotifier.new,
    );

// ── Notifier ───────────────────────────────────────────────────────────────

class ShieldActivityNotifier extends AsyncNotifier<Map<String, int>> {
  @override
  Future<Map<String, int>> build() async => _load();

  /// Record today's active shield count (keeps the higher value per day).
  Future<void> record(int activeCount) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    // Ensure we have loaded data before merging, to avoid overwriting
    // persisted entries when the initial build() hasn't resolved yet.
    final current = state.valueOrNull ?? await _load();
    final log = {...current};
    final prev = log[today] ?? 0;
    // Keep the peak value seen for the day.
    if (activeCount > prev) {
      log[today] = activeCount;
    } else if (!log.containsKey(today)) {
      log[today] = activeCount;
    }
    state = AsyncData(log);
    await _save(log);
  }

  // ── Persistence helpers ────────────────────────────────────────────────

  static Future<Map<String, int>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kShieldDailyLog);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Map<String, int> log) async {
    final prefs = await SharedPreferences.getInstance();
    // Trim entries older than 6 months to keep storage bounded.
    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    final trimmed = Map.fromEntries(
      log.entries.where((e) {
        final d = DateTime.tryParse(e.key);
        return d != null && d.isAfter(cutoff);
      }),
    );
    await prefs.setString(_kShieldDailyLog, jsonEncode(trimmed));
  }
}
