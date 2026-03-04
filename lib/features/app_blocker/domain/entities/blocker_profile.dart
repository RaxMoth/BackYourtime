import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';

// ── Task entity ────────────────────────────────────────────────────────────

/// A single to-do item that must be completed before apps are unblocked.
class BlockerTask {
  final String id;
  final String title;
  final bool isDone;

  const BlockerTask({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  BlockerTask copyWith({String? id, String? title, bool? isDone}) =>
      BlockerTask(
        id: id ?? this.id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  factory BlockerTask.fromJson(Map<String, dynamic> j) => BlockerTask(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        isDone: j['isDone'] as bool? ?? false,
      );
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Pre-defined accent colours a user can assign to a profile.
class ProfileColor {
  final String name;
  final Color color;
  const ProfileColor(this.name, this.color);

  static const List<ProfileColor> palette = [
    ProfileColor('Red', Color(0xFFE53935)),
    ProfileColor('Orange', Color(0xFFFF9800)),
    ProfileColor('Amber', Color(0xFFFFC107)),
    ProfileColor('Green', Color(0xFF43A047)),
    ProfileColor('Teal', Color(0xFF00897B)),
    ProfileColor('Blue', Color(0xFF1E88E5)),
    ProfileColor('Indigo', Color(0xFF5C6BC0)),
    ProfileColor('Purple', Color(0xFF8E24AA)),
    ProfileColor('Pink', Color(0xFFD81B60)),
  ];
}

/// Pre-defined icons a user can assign to a profile.
class ProfileIcon {
  final String label;
  final IconData icon;
  const ProfileIcon(this.label, this.icon);

  static const List<ProfileIcon> options = [
    ProfileIcon('Social', Icons.people_alt_rounded),
    ProfileIcon('Games', Icons.sports_esports_rounded),
    ProfileIcon('Video', Icons.play_circle_rounded),
    ProfileIcon('News', Icons.article_rounded),
    ProfileIcon('Shopping', Icons.shopping_bag_rounded),
    ProfileIcon('Chat', Icons.chat_bubble_rounded),
    ProfileIcon('Music', Icons.music_note_rounded),
    ProfileIcon('Photos', Icons.photo_library_rounded),
    ProfileIcon('Work', Icons.work_rounded),
    ProfileIcon('Custom', Icons.apps_rounded),
  ];

  static ProfileIcon fromLabel(String label) =>
      options.firstWhere((o) => o.label == label, orElse: () => options.last);
}

/// A single blocking profile – a named group of apps + its configuration.
///
/// Block rules are stackable:
///   • [scheduleEnabled] – hard-block during a daily time window
///   • [usageLimitEnabled] – soft-block after a daily screen-time budget
///   • [taskModeEnabled] – block until all [tasks] are marked done
///   • None enabled – "manual" mode, user taps Block Now / Deactivate
///
/// All rules are stackable. For example Schedule + Task Mode means the
/// apps are blocked during the window AND until all tasks are completed.
class BlockerProfile {
  final String id;
  final String name;
  final int colorValue;
  final String iconLabel;
  final bool isActive;

  // ── Schedule rule ────────────────────────────────────────────────────
  final bool scheduleEnabled;
  final int? scheduleStartHour;
  final int? scheduleStartMinute;
  final int? scheduleEndHour;
  final int? scheduleEndMinute;

  // ── Usage-limit rule ─────────────────────────────────────────────────
  final bool usageLimitEnabled;
  final int? usageLimitMinutes;

  // ── Task-mode rule ───────────────────────────────────────────────────
  final bool taskModeEnabled;
  final List<BlockerTask> tasks;

  /// Whether the user has picked apps for this profile.
  final bool hasAppsSelected;

  /// Number of apps selected (for display only).
  final int appCount;

  // ── Task reset tracking ──────────────────────────────────────────────
  /// Date (yyyy-MM-dd) when tasks were last reset. Used for daily reset.
  final String? tasksLastResetDate;

  // ── Stats tracking ───────────────────────────────────────────────────
  /// When the shield was last activated (ISO-8601). Null if never activated.
  final String? shieldActivatedAt;

  /// Cumulative minutes saved across all sessions.
  final int totalSavedMinutes;

  const BlockerProfile({
    required this.id,
    required this.name,
    this.colorValue = 0xFFE53935,
    this.iconLabel = 'Custom',
    this.isActive = false,
    this.scheduleEnabled = false,
    this.scheduleStartHour,
    this.scheduleStartMinute,
    this.scheduleEndHour,
    this.scheduleEndMinute,
    this.usageLimitEnabled = false,
    this.usageLimitMinutes,
    this.taskModeEnabled = false,
    this.tasks = const [],
    this.hasAppsSelected = false,
    this.appCount = 0,
    this.tasksLastResetDate,
    this.shieldActivatedAt,
    this.totalSavedMinutes = 0,
  });

  Color get color => Color(colorValue);
  ProfileIcon get profileIcon => ProfileIcon.fromLabel(iconLabel);

  /// Whether the profile is purely manual (no automated rules).
  bool get isManualOnly =>
      !scheduleEnabled && !usageLimitEnabled && !taskModeEnabled;

  /// Whether all tasks are completed (relevant when [taskModeEnabled]).
  bool get allTasksDone =>
      tasks.isNotEmpty && tasks.every((t) => t.isDone);

  /// Number of remaining tasks.
  int get pendingTaskCount => tasks.where((t) => !t.isDone).length;

  /// Whether the current time is inside the schedule window.
  bool get isInsideScheduleWindow {
    if (!scheduleEnabled ||
        scheduleStartHour == null ||
        scheduleEndHour == null) return false;
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin =
        scheduleStartHour! * 60 + (scheduleStartMinute ?? 0);
    final endMin = scheduleEndHour! * 60 + (scheduleEndMinute ?? 0);
    if (startMin <= endMin) {
      return nowMin >= startMin && nowMin < endMin;
    }
    // Overnight window (e.g. 22:00–06:00).
    return nowMin >= startMin || nowMin < endMin;
  }

  /// Whether ALL enabled rule requirements are currently satisfied,
  /// meaning the user should be able to use their apps.
  ///
  /// • Schedule → current time must be **outside** the window.
  /// • Task mode → all tasks must be done.
  /// • Usage limit → assumed met (actual enforcement is OS-level).
  /// • Manual (no rules) → never met while active.
  bool get areRequirementsMet {
    if (!isActive) return true;
    if (isManualOnly) return false;

    if (scheduleEnabled && isInsideScheduleWindow) return false;
    if (taskModeEnabled && !allTasksDone) return false;
    // Usage limit is enforced at the OS level; we can't check it here
    // so we optimistically treat it as met.
    return true;
  }

  /// Short human-readable explanation of the current lock/unlock state.
  String get requirementReason {
    if (!isActive) return '';
    if (isManualOnly) return S.current.reasonManualMode;

    final reasons = <String>[];
    if (scheduleEnabled && isInsideScheduleWindow) {
      reasons.add(S.current.reasonInsideSchedule);
    }
    if (taskModeEnabled && !allTasksDone) {
      reasons.add(S.current.reasonTasksRemaining(pendingTaskCount));
    }
    if (reasons.isEmpty) return S.current.reasonAllMet;
    return reasons.join(' · ');
  }

  /// Human-readable subtitle shown on the profile card.
  String get subtitle {
    if (!hasAppsSelected) return S.current.noAppsSelected;
    final parts = <String>[S.current.subtitleApps(appCount)];

    if (scheduleEnabled &&
        scheduleStartHour != null &&
        scheduleEndHour != null) {
      final s =
          '${scheduleStartHour!.toString().padLeft(2, '0')}:${(scheduleStartMinute ?? 0).toString().padLeft(2, '0')}';
      final e =
          '${scheduleEndHour!.toString().padLeft(2, '0')}:${(scheduleEndMinute ?? 0).toString().padLeft(2, '0')}';
      parts.add(S.current.subtitleScheduleRange(s, e));
    }

    if (usageLimitEnabled && usageLimitMinutes != null) {
      parts.add(S.current.subtitleUsageLimit(usageLimitMinutes!));
    }

    if (taskModeEnabled) {
      final done = tasks.where((t) => t.isDone).length;
      parts.add(S.current.subtitleTasks(done, tasks.length));
    }

    if (isManualOnly) parts.add(S.current.subtitleManual);

    return parts.join(' · ');
  }

  BlockerProfile copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? iconLabel,
    bool? isActive,
    bool? scheduleEnabled,
    int? scheduleStartHour,
    int? scheduleStartMinute,
    int? scheduleEndHour,
    int? scheduleEndMinute,
    bool? usageLimitEnabled,
    int? usageLimitMinutes,
    bool? taskModeEnabled,
    List<BlockerTask>? tasks,
    bool? hasAppsSelected,
    int? appCount,
    String? tasksLastResetDate,
    String? shieldActivatedAt,
    int? totalSavedMinutes,
  }) {
    return BlockerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconLabel: iconLabel ?? this.iconLabel,
      isActive: isActive ?? this.isActive,
      scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
      scheduleStartHour: scheduleStartHour ?? this.scheduleStartHour,
      scheduleStartMinute: scheduleStartMinute ?? this.scheduleStartMinute,
      scheduleEndHour: scheduleEndHour ?? this.scheduleEndHour,
      scheduleEndMinute: scheduleEndMinute ?? this.scheduleEndMinute,
      usageLimitEnabled: usageLimitEnabled ?? this.usageLimitEnabled,
      usageLimitMinutes: usageLimitMinutes ?? this.usageLimitMinutes,
      taskModeEnabled: taskModeEnabled ?? this.taskModeEnabled,
      tasks: tasks ?? this.tasks,
      hasAppsSelected: hasAppsSelected ?? this.hasAppsSelected,
      appCount: appCount ?? this.appCount,
      tasksLastResetDate: tasksLastResetDate ?? this.tasksLastResetDate,
      shieldActivatedAt: shieldActivatedAt ?? this.shieldActivatedAt,
      totalSavedMinutes: totalSavedMinutes ?? this.totalSavedMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'iconLabel': iconLabel,
        'isActive': isActive,
        'scheduleEnabled': scheduleEnabled,
        'scheduleStartHour': scheduleStartHour,
        'scheduleStartMinute': scheduleStartMinute,
        'scheduleEndHour': scheduleEndHour,
        'scheduleEndMinute': scheduleEndMinute,
        'usageLimitEnabled': usageLimitEnabled,
        'usageLimitMinutes': usageLimitMinutes,
        'taskModeEnabled': taskModeEnabled,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'hasAppsSelected': hasAppsSelected,
        'appCount': appCount,
        'tasksLastResetDate': tasksLastResetDate,
        'shieldActivatedAt': shieldActivatedAt,
        'totalSavedMinutes': totalSavedMinutes,
      };

  factory BlockerProfile.fromJson(Map<String, dynamic> j) => BlockerProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Untitled',
        colorValue: j['colorValue'] as int? ?? 0xFFE53935,
        iconLabel: j['iconLabel'] as String? ?? 'Custom',
        isActive: j['isActive'] as bool? ?? false,
        scheduleEnabled: j['scheduleEnabled'] as bool? ?? false,
        scheduleStartHour: j['scheduleStartHour'] as int?,
        scheduleStartMinute: j['scheduleStartMinute'] as int?,
        scheduleEndHour: j['scheduleEndHour'] as int?,
        scheduleEndMinute: j['scheduleEndMinute'] as int?,
        usageLimitEnabled: j['usageLimitEnabled'] as bool? ?? false,
        usageLimitMinutes: j['usageLimitMinutes'] as int?,
        taskModeEnabled: j['taskModeEnabled'] as bool? ?? false,
        tasks: (j['tasks'] as List<dynamic>?)
                ?.map((e) => BlockerTask.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        hasAppsSelected: j['hasAppsSelected'] as bool? ?? false,
        appCount: j['appCount'] as int? ?? 0,
        tasksLastResetDate: j['tasksLastResetDate'] as String?,
        shieldActivatedAt: j['shieldActivatedAt'] as String?,
        totalSavedMinutes: j['totalSavedMinutes'] as int? ?? 0,
      );
}
