import 'package:flutter_test/flutter_test.dart';
import 'package:unspend/features/app_blocker/domain/entities/blocker_profile.dart';

void main() {
  group('BlockerTask JSON round-trip', () {
    test('preserves all fields', () {
      const task = BlockerTask(id: 't1', title: 'Read', isDone: true);
      final restored = BlockerTask.fromJson(task.toJson());
      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.isDone, task.isDone);
    });

    test('fromJson tolerates missing/null fields with safe defaults', () {
      final t = BlockerTask.fromJson(<String, dynamic>{});
      expect(t.id, '');
      expect(t.title, '');
      expect(t.isDone, false);
    });
  });

  group('BlockerProfile JSON round-trip', () {
    test('preserves every field including nested tasks', () {
      const profile = BlockerProfile(
        id: 'p1',
        name: 'Focus',
        colorValue: 0xFF1E88E5,
        iconLabel: 'Work',
        isActive: true,
        scheduleEnabled: true,
        scheduleStartHour: 22,
        scheduleStartMinute: 30,
        scheduleEndHour: 6,
        scheduleEndMinute: 15,
        usageLimitEnabled: true,
        usageLimitMinutes: 90,
        taskModeEnabled: true,
        tasks: [
          BlockerTask(id: 'a', title: 'Task A', isDone: false),
          BlockerTask(id: 'b', title: 'Task B', isDone: true),
        ],
        hasAppsSelected: true,
        appCount: 12,
        tasksLastResetDate: '2026-07-06',
        shieldActivatedAt: '2026-07-06T08:00:00.000Z',
        totalSavedMinutes: 240,
      );

      final restored = BlockerProfile.fromJson(profile.toJson());

      expect(restored.id, profile.id);
      expect(restored.name, profile.name);
      expect(restored.colorValue, profile.colorValue);
      expect(restored.iconLabel, profile.iconLabel);
      expect(restored.isActive, profile.isActive);
      expect(restored.scheduleEnabled, profile.scheduleEnabled);
      expect(restored.scheduleStartHour, profile.scheduleStartHour);
      expect(restored.scheduleStartMinute, profile.scheduleStartMinute);
      expect(restored.scheduleEndHour, profile.scheduleEndHour);
      expect(restored.scheduleEndMinute, profile.scheduleEndMinute);
      expect(restored.usageLimitEnabled, profile.usageLimitEnabled);
      expect(restored.usageLimitMinutes, profile.usageLimitMinutes);
      expect(restored.taskModeEnabled, profile.taskModeEnabled);
      expect(restored.tasks.length, 2);
      expect(restored.tasks[1].isDone, true);
      expect(restored.hasAppsSelected, profile.hasAppsSelected);
      expect(restored.appCount, profile.appCount);
      expect(restored.tasksLastResetDate, profile.tasksLastResetDate);
      expect(restored.shieldActivatedAt, profile.shieldActivatedAt);
      expect(restored.totalSavedMinutes, profile.totalSavedMinutes);
    });

    test('fromJson clamps out-of-range values from corrupt storage', () {
      final restored = BlockerProfile.fromJson({
        'id': 'x',
        'name': 'Corrupt',
        'scheduleStartHour': 99,
        'scheduleStartMinute': -5,
        'scheduleEndHour': -1,
        'scheduleEndMinute': 250,
        'usageLimitMinutes': 99999,
        'appCount': -3,
        'totalSavedMinutes': -100,
      });
      expect(restored.scheduleStartHour, 23);
      expect(restored.scheduleStartMinute, 0);
      expect(restored.scheduleEndHour, 0);
      expect(restored.scheduleEndMinute, 59);
      expect(restored.usageLimitMinutes, 1440);
      expect(restored.appCount, 0);
      expect(restored.totalSavedMinutes, 0);
    });

    test('fromJson fills defaults for an empty map', () {
      final p = BlockerProfile.fromJson(<String, dynamic>{});
      expect(p.id, '');
      expect(p.name, 'Untitled');
      expect(p.colorValue, 0xFFE53935);
      expect(p.iconLabel, 'Custom');
      expect(p.isActive, false);
      expect(p.tasks, isEmpty);
    });
  });

  group('Schedule window math (overnight-safe)', () {
    BlockerProfile window(int sh, int sm, int eh, int em) => BlockerProfile(
      id: 's',
      name: 'S',
      scheduleEnabled: true,
      scheduleStartHour: sh,
      scheduleStartMinute: sm,
      scheduleEndHour: eh,
      scheduleEndMinute: em,
    );

    int at(int h, int m) => h * 60 + m;

    test('daytime window 09:00–17:00', () {
      final p = window(9, 0, 17, 0);
      expect(p.isMinuteInsideScheduleWindow(at(8, 59)), false);
      expect(p.isMinuteInsideScheduleWindow(at(9, 0)), true); // inclusive start
      expect(p.isMinuteInsideScheduleWindow(at(12, 30)), true);
      expect(p.isMinuteInsideScheduleWindow(at(17, 0)), false); // exclusive end
      expect(p.isMinuteInsideScheduleWindow(at(23, 0)), false);
    });

    test('overnight window 22:00–06:00 spans midnight', () {
      final p = window(22, 0, 6, 0);
      expect(
        p.isMinuteInsideScheduleWindow(at(22, 0)),
        true,
      ); // inclusive start
      expect(p.isMinuteInsideScheduleWindow(at(23, 59)), true);
      expect(p.isMinuteInsideScheduleWindow(at(0, 0)), true);
      expect(p.isMinuteInsideScheduleWindow(at(5, 59)), true);
      expect(p.isMinuteInsideScheduleWindow(at(6, 0)), false); // exclusive end
      expect(p.isMinuteInsideScheduleWindow(at(12, 0)), false);
      expect(p.isMinuteInsideScheduleWindow(at(21, 59)), false);
    });

    test('overnight window with minutes 23:30–06:15', () {
      final p = window(23, 30, 6, 15);
      expect(p.isMinuteInsideScheduleWindow(at(23, 29)), false);
      expect(p.isMinuteInsideScheduleWindow(at(23, 30)), true);
      expect(p.isMinuteInsideScheduleWindow(at(6, 14)), true);
      expect(p.isMinuteInsideScheduleWindow(at(6, 15)), false);
    });

    test('returns false when schedule disabled or unset', () {
      const disabled = BlockerProfile(id: 'd', name: 'D');
      expect(disabled.isMinuteInsideScheduleWindow(at(12, 0)), false);

      const enabledButNoTimes = BlockerProfile(
        id: 'e',
        name: 'E',
        scheduleEnabled: true,
      );
      expect(enabledButNoTimes.isMinuteInsideScheduleWindow(at(12, 0)), false);
    });
  });

  group('Derived requirement getters', () {
    test('isManualOnly true only when no rules enabled', () {
      const manual = BlockerProfile(id: 'm', name: 'M');
      expect(manual.isManualOnly, true);

      const scheduled = BlockerProfile(
        id: 's',
        name: 'S',
        scheduleEnabled: true,
      );
      expect(scheduled.isManualOnly, false);
    });

    test('allTasksDone requires a non-empty, fully-done list', () {
      const none = BlockerProfile(id: 'a', name: 'A', tasks: []);
      expect(none.allTasksDone, false);

      const partial = BlockerProfile(
        id: 'b',
        name: 'B',
        tasks: [
          BlockerTask(id: '1', title: 'x', isDone: true),
          BlockerTask(id: '2', title: 'y', isDone: false),
        ],
      );
      expect(partial.allTasksDone, false);
      expect(partial.pendingTaskCount, 1);

      const done = BlockerProfile(
        id: 'c',
        name: 'C',
        tasks: [BlockerTask(id: '1', title: 'x', isDone: true)],
      );
      expect(done.allTasksDone, true);
      expect(done.pendingTaskCount, 0);
    });

    test('areRequirementsMet: inactive profile is always met', () {
      const p = BlockerProfile(id: 'p', name: 'P', isActive: false);
      expect(p.areRequirementsMet, true);
    });

    test('areRequirementsMet: active manual-only never met', () {
      const p = BlockerProfile(id: 'p', name: 'P', isActive: true);
      expect(p.areRequirementsMet, false);
    });

    test('areRequirementsMet: task mode blocks until all tasks done', () {
      const blocked = BlockerProfile(
        id: 'p',
        name: 'P',
        isActive: true,
        taskModeEnabled: true,
        tasks: [BlockerTask(id: '1', title: 'x', isDone: false)],
      );
      expect(blocked.areRequirementsMet, false);

      const cleared = BlockerProfile(
        id: 'p',
        name: 'P',
        isActive: true,
        taskModeEnabled: true,
        tasks: [BlockerTask(id: '1', title: 'x', isDone: true)],
      );
      expect(cleared.areRequirementsMet, true);
    });
  });
}
