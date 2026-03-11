import 'package:flutter/services.dart';

class ScreenTimeDatasource {
  static const _channel = MethodChannel('com.maxroth.backyourtime/screentime');
  static const _pickerChannel = MethodChannel(
    'com.maxroth.backyourtime/apppicker',
  );

  Future<bool> requestAuthorization() async =>
      await _channel.invokeMethod<bool>('requestAuthorization') ?? false;

  /// Shows the app picker and returns the number of selected items,
  /// or 0 if the user cancelled.
  Future<int> showAppPicker() async =>
      await _pickerChannel.invokeMethod<int>('showPicker') ?? 0;

  Future<bool> applyShield({String? profileName}) async =>
      await _channel.invokeMethod<bool>('applyShield', {
        if (profileName != null) 'profileName': profileName,
      }) ??
      false;

  Future<bool> removeShield() async =>
      await _channel.invokeMethod<bool>('removeShield') ?? false;

  Future<bool> startSchedule({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async =>
      await _channel.invokeMethod<bool>('startSchedule', {
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      }) ??
      false;

  Future<bool> startUsageLimit({required int minutes}) async {
    // Always stop previous monitoring before starting a new usage limit
    await stopMonitoring();
    return await _channel.invokeMethod<bool>('startUsageLimit', {
          'minutes': minutes,
        }) ??
        false;
  }

  Future<bool> stopMonitoring() async =>
      await _channel.invokeMethod<bool>('stopMonitoring') ?? false;

  Future<bool> isShieldActive() async =>
      await _channel.invokeMethod<bool>('isShieldActive') ?? false;
}
