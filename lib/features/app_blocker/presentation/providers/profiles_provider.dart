import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/screen_time_datasource.dart';
import '../../data/datasources/mock_screen_time_datasource.dart';
import '../../domain/entities/blocker_profile.dart';

// ── Feature flag ───────────────────────────────────────────────────────────
/// Set to `false` once your Apple Developer license is active
/// and the FamilyControls capability is configured.
const kUseMockScreenTime = true;

// ── Persistence keys ───────────────────────────────────────────────────────
const _kProfilesKey = 'blocker_profiles_v3';
const _kSchemaVersionKey = 'blocker_schema_version';
const _kCurrentSchemaVersion = 3;
const _kPinHashKey = 'blocker_pin_hash';
const _kPinSaltKey = 'blocker_pin_salt';

// Legacy keys for migration
const _kLegacyProfilesV2 = 'blocker_profiles_v2';
const _kLegacyProfilesV1 = 'blocker_profiles';

// ── Providers ──────────────────────────────────────────────────────────────

final screenTimeDatasourceProvider = Provider<ScreenTimeDatasource>(
  (_) => kUseMockScreenTime
      ? MockScreenTimeDatasource()
      : ScreenTimeDatasource(),
);

/// Manages the full list of [BlockerProfile]s.
final profilesProvider =
    AsyncNotifierProvider<ProfilesNotifier, List<BlockerProfile>>(
  ProfilesNotifier.new,
);

// ── Notifier ───────────────────────────────────────────────────────────────

class ProfilesNotifier extends AsyncNotifier<List<BlockerProfile>> {
  late ScreenTimeDatasource _ds;

  @override
  Future<List<BlockerProfile>> build() async {
    _ds = ref.read(screenTimeDatasourceProvider);
    try {
      await _ds.requestAuthorization();
    } catch (_) {
      // Permission not yet granted – continue with saved profiles anyway.
    }
    final profiles = await _loadProfiles();
    // Recover from app crash / reboot: mark any "active" profile that has
    // no valid shieldActivatedAt as inactive so the UI stays consistent.
    bool needsPersist = false;
    final recovered = profiles.map((p) {
      if (p.isActive && p.shieldActivatedAt == null) {
        needsPersist = true;
        return p.copyWith(isActive: false);
      }
      return p;
    }).toList();
    if (needsPersist) {
      await _persist(recovered);
    }
    return recovered;
  }

  // ── CRUD ───────────────────────────────────────────────────────────────

  /// Create a new profile and return its ID.
  Future<String> createProfile({required String name}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final profile = BlockerProfile(
      id: id,
      name: name,
      colorValue: ProfileColor.palette[
              _profiles.length % ProfileColor.palette.length]
          .color
          .toARGB32(),
    );
    final updated = [..._profiles, profile];
    state = AsyncData(updated);
    await _persist(updated);
    return id;
  }

  /// Update any field of a profile by [id].
  /// Silently ignores setting changes if the profile is active.
  Future<void> updateProfile(BlockerProfile profile) async {
    final current = _profiles.firstWhere((p) => p.id == profile.id);
    // If the profile is active, only allow name and cosmetic changes.
    // Block rule changes are locked while shield is on.
    final effective = current.isActive
        ? current.copyWith(
            name: profile.name,
            colorValue: profile.colorValue,
            iconLabel: profile.iconLabel,
          )
        : profile;
    final list = _profiles
        .map((p) => p.id == effective.id ? effective : p)
        .toList();
    state = AsyncData(list);
    await _persist(list);
  }

  /// Delete a profile. Removes its shield if active.
  Future<void> deleteProfile(String id) async {
    final profile = _profiles.firstWhere((p) => p.id == id);
    if (profile.isActive) {
      await _ds.removeShield();
      await _ds.stopMonitoring();
    }
    final list = _profiles.where((p) => p.id != id).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  // ── Actions on individual profiles ─────────────────────────────────────

  Future<void> pickAppsForProfile(String id) async {
    await _ds.showAppPicker();
    final list = _profiles.map((p) {
      if (p.id != id) return p;
      // Mock: random app count between 3-12
      final count = kUseMockScreenTime ? (Random().nextInt(10) + 3) : p.appCount;
      return p.copyWith(hasAppsSelected: true, appCount: count);
    }).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> activateProfile(String id) async {
    final profile = _profiles.firstWhere((p) => p.id == id);
    if (!profile.hasAppsSelected) return;

    // Apply all enabled rules — they stack.
    // 1) Always apply the immediate shield (manual base).
    await _ds.applyShield();

    // 2) Schedule: hard-block during a time window.
    if (profile.scheduleEnabled &&
        profile.scheduleStartHour != null &&
        profile.scheduleEndHour != null) {
      await _ds.startSchedule(
        startHour: profile.scheduleStartHour!,
        startMinute: profile.scheduleStartMinute ?? 0,
        endHour: profile.scheduleEndHour!,
        endMinute: profile.scheduleEndMinute ?? 0,
      );
    }

    // 3) Usage limit: soft-block after daily budget.
    if (profile.usageLimitEnabled && profile.usageLimitMinutes != null) {
      await _ds.startUsageLimit(minutes: profile.usageLimitMinutes!);
    }

    // 4) Task mode: reset tasks to undone so the user must complete them.
    //    Also record today's date for the daily-reset check.
    BlockerProfile activatedProfile = profile;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (profile.taskModeEnabled && profile.tasks.isNotEmpty) {
      activatedProfile = profile.copyWith(
        tasks: profile.tasks.map((t) => t.copyWith(isDone: false)).toList(),
        tasksLastResetDate: todayStr,
      );
    } else {
      activatedProfile = profile.copyWith(tasksLastResetDate: todayStr);
    }

    final list = _profiles.map((p) {
      if (p.id != id) return p;
      return activatedProfile.copyWith(
        isActive: true,
        shieldActivatedAt: DateTime.now().toIso8601String(),
      );
    }).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> deactivateProfile(String id) async {
    await _ds.removeShield();
    await _ds.stopMonitoring();
    final list = _profiles.map((p) {
      if (p.id != id) return p;
      // Accumulate saved minutes from this session.
      int sessionMinutes = 0;
      if (p.shieldActivatedAt != null) {
        final activated = DateTime.tryParse(p.shieldActivatedAt!);
        if (activated != null) {
          sessionMinutes = DateTime.now().difference(activated).inMinutes;
        }
      }
      return p.copyWith(
        isActive: false,
        totalSavedMinutes: p.totalSavedMinutes + sessionMinutes,
      );
    }).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  /// Quick toggle from the dashboard.
  Future<void> toggleProfile(String id) async {
    final profile = _profiles.firstWhere((p) => p.id == id);
    if (profile.isActive) {
      await deactivateProfile(id);
    } else {
      await activateProfile(id);
    }
  }

  // ── Task management ────────────────────────────────────────────────

  /// Add a new task to a profile. Ignored when the profile is active.
  Future<void> addTask(String profileId, String title) async {
    final profile = _profiles.firstWhere((p) => p.id == profileId);
    if (profile.isActive) return;
    final taskId = DateTime.now().microsecondsSinceEpoch.toString();
    final list = _profiles.map((p) {
      if (p.id != profileId) return p;
      return p.copyWith(
        tasks: [...p.tasks, BlockerTask(id: taskId, title: title)],
      );
    }).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  /// Remove a task from a profile. Ignored when the profile is active.
  Future<void> removeTask(String profileId, String taskId) async {
    final profile = _profiles.firstWhere((p) => p.id == profileId);
    if (profile.isActive) return;
    final list = _profiles.map((p) {
      if (p.id != profileId) return p;
      return p.copyWith(
        tasks: p.tasks.where((t) => t.id != taskId).toList(),
      );
    }).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  /// Toggle a task's done state.
  ///
  /// Daily reset: if the day changed since last reset, reset all tasks first.
  Future<void> toggleTask(String profileId, String taskId) async {
    var profile = _profiles.firstWhere((p) => p.id == profileId);

    // Daily reset check.
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (profile.tasksLastResetDate != null &&
        profile.tasksLastResetDate != todayStr) {
      profile = profile.copyWith(
        tasks: profile.tasks.map((t) => t.copyWith(isDone: false)).toList(),
        tasksLastResetDate: todayStr,
      );
    }

    final updatedTasks = profile.tasks
        .map((t) => t.id == taskId ? t.copyWith(isDone: !t.isDone) : t)
        .toList();
    final updatedProfile = profile.copyWith(tasks: updatedTasks);

    final list = _profiles.map((p) {
      if (p.id != profileId) return p;
      return updatedProfile;
    }).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  // ── PIN management ─────────────────────────────────────────────────────

  Future<bool> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = List.generate(16, (_) => Random.secure().nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final hash = sha256.convert(utf8.encode('$salt:$pin')).toString();
    await prefs.setString(_kPinSaltKey, salt);
    await prefs.setString(_kPinHashKey, hash);
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_kPinSaltKey);
    final storedHash = prefs.getString(_kPinHashKey);
    if (salt == null || storedHash == null) return false;
    final hash = sha256.convert(utf8.encode('$salt:$pin')).toString();
    return hash == storedHash;
  }

  Future<bool> hasPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kPinHashKey);
  }

  // ── Persistence helpers ────────────────────────────────────────────────

  /// Safely access the current profile list. Returns empty list if loading
  /// or in an error state (avoids [StateError] from `requireValue`).
  List<BlockerProfile> get _profiles => state.valueOrNull ?? [];

  Future<List<BlockerProfile>> _loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── Migration: move data from older keys to current key ──────────
      await _migrateIfNeeded(prefs);

      final raw = prefs.getString(_kProfilesKey);
      if (raw == null) return [];
      final list = (json.decode(raw) as List)
          .map((e) => BlockerProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      // Corrupt data – start fresh rather than crash.
      debugPrint('[ProfilesNotifier] Failed to load profiles: $e');
      return [];
    }
  }

  /// Migrates profile data from legacy storage keys to the current version.
  Future<void> _migrateIfNeeded(SharedPreferences prefs) async {
    final version = prefs.getInt(_kSchemaVersionKey) ?? 0;
    if (version >= _kCurrentSchemaVersion) return;

    // v0/v1 → v3: read from legacy key and write to new key.
    if (version < 3) {
      final legacy = prefs.getString(_kProfilesKey) ??
          prefs.getString(_kLegacyProfilesV2) ??
          prefs.getString(_kLegacyProfilesV1);
      if (legacy != null) {
        // Re-parse through fromJson which fills in defaults for new fields.
        try {
          final list = (json.decode(legacy) as List)
              .map((e) => BlockerProfile.fromJson(e as Map<String, dynamic>))
              .toList();
          final encoded =
              json.encode(list.map((p) => p.toJson()).toList());
          await prefs.setString(_kProfilesKey, encoded);
        } catch (e) {
          debugPrint('[ProfilesNotifier] Migration parse failed: $e');
        }
        // Clean up legacy keys.
        await prefs.remove(_kLegacyProfilesV1);
        await prefs.remove(_kLegacyProfilesV2);
      }
    }

    await prefs.setInt(_kSchemaVersionKey, _kCurrentSchemaVersion);
    debugPrint('[ProfilesNotifier] Migrated to schema v$_kCurrentSchemaVersion');
  }

  Future<void> _persist(List<BlockerProfile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(profiles.map((p) => p.toJson()).toList());
      await prefs.setString(_kProfilesKey, encoded);
    } catch (e) {
      debugPrint('[ProfilesNotifier] Failed to persist profiles: $e');
    }
  }
}
