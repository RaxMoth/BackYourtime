import 'package:flutter/material.dart';

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
///   • Neither – "manual" mode, user taps Block Now / Deactivate
///
/// Schedule + Usage Limit can be combined: the app is blocked during the
/// schedule window AND limited to [usageLimitMinutes] outside that window.
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

  /// Whether the user has picked apps for this profile.
  final bool hasAppsSelected;

  /// Number of apps selected (for display only).
  final int appCount;

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
    this.hasAppsSelected = false,
    this.appCount = 0,
  });

  Color get color => Color(colorValue);
  ProfileIcon get profileIcon => ProfileIcon.fromLabel(iconLabel);

  /// Whether the profile is purely manual (no automated rules).
  bool get isManualOnly => !scheduleEnabled && !usageLimitEnabled;

  /// Human-readable subtitle shown on the profile card.
  String get subtitle {
    if (!hasAppsSelected) return 'No apps selected';
    final parts = <String>['$appCount apps'];

    if (scheduleEnabled &&
        scheduleStartHour != null &&
        scheduleEndHour != null) {
      final s =
          '${scheduleStartHour!.toString().padLeft(2, '0')}:${(scheduleStartMinute ?? 0).toString().padLeft(2, '0')}';
      final e =
          '${scheduleEndHour!.toString().padLeft(2, '0')}:${(scheduleEndMinute ?? 0).toString().padLeft(2, '0')}';
      parts.add('$s–$e');
    }

    if (usageLimitEnabled && usageLimitMinutes != null) {
      parts.add('${usageLimitMinutes}min limit');
    }

    if (isManualOnly) parts.add('Manual');

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
    bool? hasAppsSelected,
    int? appCount,
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
      hasAppsSelected: hasAppsSelected ?? this.hasAppsSelected,
      appCount: appCount ?? this.appCount,
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
        'hasAppsSelected': hasAppsSelected,
        'appCount': appCount,
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
        hasAppsSelected: j['hasAppsSelected'] as bool? ?? false,
        appCount: j['appCount'] as int? ?? 0,
      );
}
