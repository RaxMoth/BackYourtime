import 'screen_time_datasource.dart';

/// In-memory mock that simulates all ScreenTime calls.
/// Use this for UI development on simulator / desktop / web.
class MockScreenTimeDatasource implements ScreenTimeDatasource {
  bool _shieldActive = false;

  @override
  Future<bool> requestAuthorization() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> showAppPicker() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<bool> applyShield() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _shieldActive = true;
    return true;
  }

  @override
  Future<bool> removeShield() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _shieldActive = false;
    return true;
  }

  @override
  Future<bool> startSchedule({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> startUsageLimit({required int minutes}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> stopMonitoring() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Future<bool> isShieldActive() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _shieldActive;
  }
}
