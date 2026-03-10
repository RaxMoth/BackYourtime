import 'package:flutter/services.dart';

class ScreenTimeDatasource {
  static const _channel = MethodChannel('com.maxroth.backyourtime/screentime');
  static const _pickerChannel =
      MethodChannel('com.maxroth.backyourtime/apppicker');

  Future<bool> requestAuthorization() async =>
      await _channel.invokeMethod<bool>('requestAuthorization') ?? false;

  Future<bool> showAppPicker() async =>
      await _pickerChannel.invokeMethod<bool>('showPicker') ?? false;

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

  Future<bool> startUsageLimit({required int minutes}) async =>
      await _channel.invokeMethod<bool>('startUsageLimit', {
        'minutes': minutes,
      }) ??
      false;

  Future<bool> stopMonitoring() async =>
      await _channel.invokeMethod<bool>('stopMonitoring') ?? false;

  Future<bool> isShieldActive() async =>
      await _channel.invokeMethod<bool>('isShieldActive') ?? false;
}
