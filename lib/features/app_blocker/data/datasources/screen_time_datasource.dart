import 'package:flutter/services.dart';

class ScreenTimeDatasource {
  static const _channel = MethodChannel('com.maxroth.backyourtime/screentime');
  static const _pickerChannel = MethodChannel(
    'com.maxroth.backyourtime/apppicker',
  );

  Future<bool> requestAuthorization() async =>
      await _channel.invokeMethod<bool>('requestAuthorization') ?? false;

  /// Shows the app picker scoped to [profileId] and returns the number of
  /// selected items (or 0 if cancelled). Each profile keeps its own
  /// selection — picking apps for profile A doesn't affect profile B.
  Future<int> showAppPicker({required String profileId}) async =>
      await _pickerChannel.invokeMethod<int>('showPicker', {
        'profileId': profileId,
      }) ??
      0;

  Future<bool> applyShield({
    required String profileId,
    String? profileName,
  }) async =>
      await _channel.invokeMethod<bool>('applyShield', {
        'profileId': profileId,
        'profileName': ?profileName,
      }) ??
      false;

  Future<bool> removeShield({required String profileId}) async =>
      await _channel.invokeMethod<bool>('removeShield', {
        'profileId': profileId,
      }) ??
      false;

  Future<bool> startSchedule({
    required String profileId,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async =>
      await _channel.invokeMethod<bool>('startSchedule', {
        'profileId': profileId,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      }) ??
      false;

  Future<bool> startUsageLimit({
    required String profileId,
    required int minutes,
  }) async =>
      await _channel.invokeMethod<bool>('startUsageLimit', {
        'profileId': profileId,
        'minutes': minutes,
      }) ??
      false;

  /// Stop monitoring for [profileId] only, or all profiles if null.
  Future<bool> stopMonitoring({String? profileId}) async =>
      await _channel.invokeMethod<bool>('stopMonitoring', {
        'profileId': ?profileId,
      }) ??
      false;

  /// Returns true if the named profile currently has an active shield at the
  /// OS level. Pass the profile ID to check a specific profile.
  Future<bool> isShieldActive({required String profileId}) async =>
      await _channel.invokeMethod<bool>('isShieldActive', {
        'profileId': profileId,
      }) ??
      false;

  /// Stash active profile pointers without applying a shield. Used when the
  /// profile is "armed" (usage-limit-only) but the shield should only engage
  /// later via a DeviceActivity event.
  Future<bool> cacheActiveProfile({
    required String profileId,
    String? profileName,
  }) async =>
      await _channel.invokeMethod<bool>('cacheActiveProfile', {
        'profileId': profileId,
        'profileName': ?profileName,
      }) ??
      false;

  /// Whether the given profile has any app/category/domain picked.
  Future<bool> hasSelection({required String profileId}) async =>
      await _channel.invokeMethod<bool>('hasSelection', {
        'profileId': profileId,
      }) ??
      false;
}
