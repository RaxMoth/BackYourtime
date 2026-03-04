import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
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
const _kProfilesKey = 'blocker_profiles_v2';
const _kPinHashKey = 'blocker_pin_hash';
const _kPinSaltKey = 'blocker_pin_salt';

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
    await _ds.requestAuthorization();
    return _loadProfiles();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────

  /// Create a new profile and return its ID.
  Future<String> createProfile({required String name}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final profile = BlockerProfile(
      id: id,
      name: name,
      colorValue: ProfileColor.palette[
              state.requireValue.length % ProfileColor.palette.length]
          .color
          .toARGB32(),
    );
    final updated = [...state.requireValue, profile];
    state = AsyncData(updated);
    await _persist(updated);
    return id;
  }

  /// Update any field of a profile by [id].
  Future<void> updateProfile(BlockerProfile profile) async {
    final list = state.requireValue
        .map((p) => p.id == profile.id ? profile : p)
        .toList();
    state = AsyncData(list);
    await _persist(list);
  }

  /// Delete a profile. Removes its shield if active.
  Future<void> deleteProfile(String id) async {
    final profile = state.requireValue.firstWhere((p) => p.id == id);
    if (profile.isActive) {
      await _ds.removeShield();
      await _ds.stopMonitoring();
    }
    final list = state.requireValue.where((p) => p.id != id).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  // ── Actions on individual profiles ─────────────────────────────────────

  Future<void> pickAppsForProfile(String id) async {
    await _ds.showAppPicker();
    final list = state.requireValue.map((p) {
      if (p.id != id) return p;
      // Mock: random app count between 3-12
      final count = kUseMockScreenTime ? (Random().nextInt(10) + 3) : p.appCount;
      return p.copyWith(hasAppsSelected: true, appCount: count);
    }).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> activateProfile(String id) async {
    final profile = state.requireValue.firstWhere((p) => p.id == id);
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

    final list = state.requireValue.map((p) {
      if (p.id != id) return p;
      return p.copyWith(isActive: true);
    }).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> deactivateProfile(String id) async {
    await _ds.removeShield();
    await _ds.stopMonitoring();
    final list = state.requireValue.map((p) {
      if (p.id != id) return p;
      return p.copyWith(isActive: false);
    }).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  /// Quick toggle from the dashboard.
  Future<void> toggleProfile(String id) async {
    final profile = state.requireValue.firstWhere((p) => p.id == id);
    if (profile.isActive) {
      await deactivateProfile(id);
    } else {
      await activateProfile(id);
    }
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

  Future<List<BlockerProfile>> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfilesKey);
    if (raw == null) return [];
    try {
      final list = (json.decode(raw) as List)
          .map((e) => BlockerProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<BlockerProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_kProfilesKey, encoded);
  }
}
