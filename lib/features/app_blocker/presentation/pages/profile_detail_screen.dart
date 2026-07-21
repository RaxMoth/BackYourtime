import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unspend/core/constants/strings.dart';
import 'package:unspend/core/theme/design_tokens.dart';
import '../../domain/entities/blocker_profile.dart';
import '../providers/profiles_provider.dart';
import '../widgets/section_widgets.dart';
import '../widgets/rule_toggle_card.dart';
import '../widgets/task_list_section.dart';
import '../widgets/pin_setup_dialog.dart';
import '../widgets/timer_pin_dialog.dart';

// ── Profile Detail Page Shell ───────────────────────────────────────────────
// Watches provider and passes the live profile to ProfileDetailScreen.
class ProfileDetailPageShell extends ConsumerWidget {
  final String profileId;
  const ProfileDetailPageShell({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow the watch to just this profile: unchanged profiles keep their
    // identity across state updates (see ProfilesNotifier), so selecting the
    // matching one means editing *other* profiles no longer rebuilds this shell.
    final profileAsync = ref.watch(
      profilesProvider.select(
        (async) => async.whenData(
          (profiles) => profiles.where((p) => p.id == profileId).firstOrNull,
        ),
      ),
    );
    return profileAsync.when(
      loading: () => Scaffold(
        backgroundColor: kBg,
        body: const Center(child: CircularProgressIndicator(color: kAccent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: kBg,
        body: Center(child: Text(S.current.errorGeneric(e))),
      ),
      data: (profile) {
        if (profile == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return Scaffold(backgroundColor: kBg);
        }
        return ProfileDetailScreen(profile: profile);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Profile Detail Screen ──────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final BlockerProfile profile;
  const ProfileDetailScreen({super.key, required this.profile});

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  late TextEditingController _nameController;
  late bool _scheduleEnabled;
  late bool _usageLimitEnabled;
  late bool _taskModeEnabled;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _usageLimitMinutes;
  late int _selectedColorValue;
  late String _selectedIconLabel;
  Timer? _debounce;
  bool _isActivating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _syncFromProfile(widget.profile);
  }

  @override
  void didUpdateWidget(covariant ProfileDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id) {
      _syncFromProfile(widget.profile);
    }
  }

  void _syncFromProfile(BlockerProfile p) {
    if (_nameController.text != p.name) {
      _nameController.text = p.name;
    }
    _scheduleEnabled = p.scheduleEnabled;
    _usageLimitEnabled = p.usageLimitEnabled;
    _taskModeEnabled = p.taskModeEnabled;
    _startTime = TimeOfDay(
      hour: p.scheduleStartHour ?? 9,
      minute: p.scheduleStartMinute ?? 0,
    );
    _endTime = TimeOfDay(
      hour: p.scheduleEndHour ?? 17,
      minute: p.scheduleEndMinute ?? 0,
    );
    _usageLimitMinutes = p.usageLimitMinutes ?? 30;
    _selectedColorValue = p.colorValue;
    _selectedIconLabel = p.iconLabel;
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Format a duration in minutes as "Nm", "Nh", or "Nh Mm".
  String _formatDuration(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Show a duration picker for the daily usage limit (1 min – 23 h 59 m).
  /// Offers a segmented switch between an iOS-style wheel and a direct
  /// numeric keypad — users have strong preferences either way.
  Future<void> _pickUsageLimit(Color accent) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _UsageLimitPickerSheet(
        initialMinutes: _usageLimitMinutes,
        accent: accent,
      ),
    );

    if (!mounted) return;
    if (result != null && result != _usageLimitMinutes) {
      HapticFeedback.lightImpact();
      setState(() => _usageLimitMinutes = result);
      _save();
    }
  }

  void _debouncedSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  /// Launch the system FamilyActivityPicker for this profile. Prompts the
  /// user to set a PIN afterwards if none is set yet.
  Future<void> _onSelectAppsTapped(
    BuildContext context,
    WidgetRef ref,
    BlockerProfile profile,
  ) async {
    HapticFeedback.selectionClick();
    final notifier = ref.read(profilesProvider.notifier);
    try {
      await notifier.pickAppsForProfile(profile.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.current.errorGeneric(e.toString()),
            style: TextStyle(color: kTextPrimary),
          ),
          backgroundColor: kSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    final hasPin = await notifier.hasPinSet();
    if (!context.mounted) return;
    if (!hasPin) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PinSetupDialog(onSave: (pin) => notifier.savePin(pin)),
      );
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(profilesProvider.notifier);
    await notifier.updateProfile(
      widget.profile.copyWith(
        name: _nameController.text.trim().isEmpty
            ? S.current.untitled
            : _nameController.text.trim(),
        colorValue: _selectedColorValue,
        iconLabel: _selectedIconLabel,
        scheduleEnabled: _scheduleEnabled,
        usageLimitEnabled: _usageLimitEnabled,
        taskModeEnabled: _taskModeEnabled,
        scheduleStartHour: _startTime.hour,
        scheduleStartMinute: _startTime.minute,
        scheduleEndHour: _endTime.hour,
        scheduleEndMinute: _endTime.minute,
        usageLimitMinutes: _usageLimitMinutes,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final accent = Color(_selectedColorValue);
    final locked = p.isActive;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: kTextPrimary),
                    onPressed: () {
                      _save();
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  if (!p.isActive)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: kTextSecondary,
                      ),
                      onPressed: () => _confirmDelete(context),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Profile icon + name ────────────────────────────────
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          ProfileIcon.fromLabel(_selectedIconLabel).icon,
                          size: 40,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      readOnly: locked,
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: S.current.profileNamePlaceholder,
                        hintStyle: TextStyle(color: kTextSecondary),
                      ),
                      onChanged: (_) => _debouncedSave(),
                    ),
                    const SizedBox(height: 8),

                    // ── Color picker ───────────────────────────────────────
                    SectionLabel(S.current.sectionColor),
                    const SizedBox(height: 8),
                    IgnorePointer(
                      ignoring: locked,
                      child: Opacity(
                        opacity: locked ? 0.5 : 1.0,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: ProfileColor.palette.map((pc) {
                            final isSelected =
                                pc.color.toARGB32() == _selectedColorValue;
                            final shape = CircleBorder(
                              side: isSelected
                                  ? BorderSide(color: kTextPrimary, width: 2.5)
                                  : BorderSide.none,
                            );
                            return Semantics(
                              button: true,
                              selected: isSelected,
                              label: pc.name,
                              child: Material(
                                color: pc.color,
                                shape: shape,
                                child: InkWell(
                                  customBorder: shape,
                                  onTap: () {
                                    setState(
                                      () => _selectedColorValue = pc.color
                                          .toARGB32(),
                                    );
                                    _save();
                                  },
                                  child: SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: kTextPrimary,
                                            size: 18,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Icon picker ────────────────────────────────────────
                    SectionLabel(S.current.sectionIcon),
                    const SizedBox(height: 8),
                    IgnorePointer(
                      ignoring: locked,
                      child: Opacity(
                        opacity: locked ? 0.5 : 1.0,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: ProfileIcon.options.map((pi) {
                            final isSelected = pi.label == _selectedIconLabel;
                            final shape = RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? accent : kBorder,
                              ),
                            );
                            return Semantics(
                              button: true,
                              selected: isSelected,
                              label: pi.label,
                              child: Material(
                                color: isSelected
                                    ? accent.withValues(alpha: 0.2)
                                    : kSurface,
                                shape: shape,
                                child: InkWell(
                                  customBorder: shape,
                                  onTap: () {
                                    setState(
                                      () => _selectedIconLabel = pi.label,
                                    );
                                    _save();
                                  },
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Icon(
                                      pi.icon,
                                      size: 22,
                                      color: isSelected
                                          ? accent
                                          : kTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Select Apps ────────────────────────────────────────
                    SectionLabel(S.current.sectionApps),
                    const SizedBox(height: 8),
                    IgnorePointer(
                      ignoring: locked,
                      child: Opacity(
                        opacity: locked ? 0.5 : 1.0,
                        child: _AppSelectionCard(
                          profile: p,
                          accent: accent,
                          onTap: () => _onSelectAppsTapped(context, ref, p),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Block Rules ────────────────────────────────────────
                    SectionLabel(S.current.sectionBlockRules),
                    const SizedBox(height: 4),
                    Text(
                      locked
                          ? S.current.settingsLockedWhileActive
                          : S.current.blockRulesDescription,
                      style: TextStyle(
                        color: locked
                            ? kAccent.withValues(alpha: 0.8)
                            : kTextSecondary,
                        fontSize: 12,
                        fontStyle: locked ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Schedule toggle + config ───────────────────────────
                    RuleToggleCard(
                      icon: Icons.calendar_today_rounded,
                      title: S.current.scheduleTitle,
                      description: S.current.scheduleDescription,
                      enabled: _scheduleEnabled,
                      accent: accent,
                      locked: locked,
                      onToggle: (v) {
                        setState(() => _scheduleEnabled = v);
                        _save();
                      },
                    ),
                    if (_scheduleEnabled) ...[
                      IgnorePointer(
                        ignoring: locked,
                        child: Opacity(
                          opacity: locked ? 0.5 : 1.0,
                          child: SectionCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        color: accent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        S.current.scheduleTitle,
                                        style: TextStyle(
                                          color: kTextPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TimeTile(
                                          label: S.current.scheduleStart,
                                          formatted: _fmt(_startTime),
                                          onTap: () async {
                                            final t = await showTimePicker(
                                              context: context,
                                              initialTime: _startTime,
                                              builder: (ctx, child) => Theme(
                                                data: ThemeData.dark().copyWith(
                                                  colorScheme: ColorScheme.dark(
                                                    primary: accent,
                                                    surface: kSurface,
                                                  ),
                                                ),
                                                child: child!,
                                              ),
                                            );
                                            if (!mounted) return;
                                            if (t != null) {
                                              setState(() => _startTime = t);
                                              _save();
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TimeTile(
                                          label: S.current.scheduleEnd,
                                          formatted: _fmt(_endTime),
                                          onTap: () async {
                                            final t = await showTimePicker(
                                              context: context,
                                              initialTime: _endTime,
                                              builder: (ctx, child) => Theme(
                                                data: ThemeData.dark().copyWith(
                                                  colorScheme: ColorScheme.dark(
                                                    primary: accent,
                                                    surface: kSurface,
                                                  ),
                                                ),
                                                child: child!,
                                              ),
                                            );
                                            if (!mounted) return;
                                            if (t != null) {
                                              setState(() => _endTime = t);
                                              _save();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),

                    // ── Usage Limit toggle + config ────────────────────────
                    RuleToggleCard(
                      icon: Icons.timer_rounded,
                      title: S.current.usageLimitTitle,
                      description: S.current.usageLimitDescription,
                      enabled: _usageLimitEnabled,
                      accent: accent,
                      locked: locked,
                      onToggle: (v) {
                        setState(() => _usageLimitEnabled = v);
                        _save();
                      },
                    ),
                    if (_usageLimitEnabled) ...[
                      IgnorePointer(
                        ignoring: locked,
                        child: Opacity(
                          opacity: locked ? 0.5 : 1.0,
                          child: SectionCard(
                            child: InkWell(
                              onTap: () => _pickUsageLimit(accent),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      color: accent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      S.current.dailyLimit,
                                      style: TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _formatDuration(_usageLimitMinutes),
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: kTextSecondary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 8),

                    // ── Task Mode toggle + task list ───────────────────────
                    RuleToggleCard(
                      icon: Icons.checklist_rounded,
                      title: S.current.taskModeTitle,
                      description: S.current.taskModeDescription,
                      enabled: _taskModeEnabled,
                      accent: accent,
                      locked: locked,
                      onToggle: (v) {
                        setState(() => _taskModeEnabled = v);
                        _save();
                      },
                    ),
                    if (_taskModeEnabled) ...[
                      TaskListSection(profile: p, accent: accent),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 8),

                    // ── Activate / Deactivate ─────────────────────────────
                    if (p.isActive)
                      FullWidthButton(
                        label: S.current.deactivateShield,
                        icon: Icons.shield_outlined,
                        color: kTextSecondary,
                        bgColor: kSurface,
                        borderColor: kBorder,
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => TimerPinDialog(
                              onConfirm: () => ref
                                  .read(profilesProvider.notifier)
                                  .deactivateProfile(p.id),
                              onVerifyPin: (pin) => ref
                                  .read(profilesProvider.notifier)
                                  .verifyPin(pin),
                              hasPinSet: () => ref
                                  .read(profilesProvider.notifier)
                                  .hasPinSet(),
                            ),
                          );
                        },
                      )
                    else
                      Builder(
                        builder: (_) {
                          final canActivate =
                              p.hasAppsSelected &&
                              !(_taskModeEnabled && p.tasks.isEmpty) &&
                              !_isActivating;
                          final String buttonLabel;
                          final IconData buttonIcon;
                          final String? warningMsg;

                          if (_isActivating) {
                            buttonLabel = S.current.activateShield;
                            buttonIcon = Icons.shield_rounded;
                            warningMsg = null;
                          } else if (!p.hasAppsSelected) {
                            buttonLabel = S.current.selectAppsToActivate;
                            buttonIcon = Icons.apps_rounded;
                            warningMsg = S.current.noAppsWarning;
                          } else if (_taskModeEnabled && p.tasks.isEmpty) {
                            buttonLabel = S.current.activateShield;
                            buttonIcon = Icons.shield_rounded;
                            warningMsg = S.current.noTasksWarning;
                          } else {
                            buttonLabel = S.current.activateShield;
                            buttonIcon = Icons.shield_rounded;
                            warningMsg = null;
                          }

                          return FullWidthButton(
                            label: _isActivating ? '…' : buttonLabel,
                            icon: buttonIcon,
                            color: canActivate ? kTextPrimary : kTextSecondary,
                            bgColor: canActivate ? accent : kSurface,
                            borderColor: canActivate ? null : kBorder,
                            onPressed: canActivate
                                ? () async {
                                    HapticFeedback.heavyImpact();
                                    setState(() => _isActivating = true);
                                    try {
                                      await ref
                                          .read(profilesProvider.notifier)
                                          .activateProfile(p.id);
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              S.current.errorGeneric(
                                                S.current.activationFailed,
                                              ),
                                              style: TextStyle(
                                                color: kTextPrimary,
                                              ),
                                            ),
                                            backgroundColor: kSurface,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isActivating = false);
                                      }
                                    }
                                  }
                                : warningMsg != null
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          warningMsg!,
                                          style: TextStyle(color: kTextPrimary),
                                        ),
                                        backgroundColor: kSurface,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          );
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: BorderSide(color: kBorder),
        ),
        title: Text(
          S.current.deleteProfile,
          style: TextStyle(color: kTextPrimary),
        ),
        content: Text(
          S.current.deleteProfileConfirm(widget.profile.name),
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              S.current.cancel,
              style: TextStyle(color: kTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(profilesProvider.notifier)
                    .deleteProfile(widget.profile.id);
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        S.current.errorGeneric(e.toString()),
                        style: TextStyle(color: kTextPrimary),
                      ),
                      backgroundColor: kSurface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              S.current.delete,
              style: const TextStyle(color: kAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Usage Limit Picker Sheet ────────────────────────────────────────────────
/// Two-mode duration picker.
///
/// • **Wheel mode** uses `CupertinoTimerPicker` — fast scrubbing, familiar
///   to anyone who's used Apple's Clock app.
/// • **Keypad mode** lets users type hours/minutes directly — needed when
///   the wheel feels imprecise (e.g. setting "13 minutes" exactly).
///
/// We default to whichever the user picked last (cached in
/// `_lastUsedMode`). Range is 1 min – 23 h 59 m.
class _UsageLimitPickerSheet extends StatefulWidget {
  final int initialMinutes;
  final Color accent;

  const _UsageLimitPickerSheet({
    required this.initialMinutes,
    required this.accent,
  });

  @override
  State<_UsageLimitPickerSheet> createState() => _UsageLimitPickerSheetState();
}

class _UsageLimitPickerSheetState extends State<_UsageLimitPickerSheet> {
  static _PickerMode _lastUsedMode = _PickerMode.wheel;

  late _PickerMode _mode;
  late int _currentMinutes;
  late final TextEditingController _hCtrl;
  late final TextEditingController _mCtrl;

  @override
  void initState() {
    super.initState();
    _mode = _lastUsedMode;
    _currentMinutes = widget.initialMinutes.clamp(1, 1439);
    _hCtrl = TextEditingController(text: (_currentMinutes ~/ 60).toString());
    _mCtrl = TextEditingController(text: (_currentMinutes % 60).toString());
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _mCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_mode == _PickerMode.keypad) {
      final h = int.tryParse(_hCtrl.text.trim()) ?? 0;
      final m = int.tryParse(_mCtrl.text.trim()) ?? 0;
      _currentMinutes = (h * 60 + m).clamp(1, 1439);
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(_currentMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),

            // ── Header (Cancel / title / Save) ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      S.current.cancel,
                      style: TextStyle(color: kTextSecondary),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    S.current.dailyLimit,
                    style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _onSave,
                    child: Text(
                      S.current.save,
                      style: TextStyle(
                        color: widget.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Mode switch (wheel ↔ keypad) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CupertinoSlidingSegmentedControl<_PickerMode>(
                groupValue: _mode,
                backgroundColor: kBorder,
                thumbColor: widget.accent,
                onValueChanged: (m) {
                  if (m == null) return;
                  HapticFeedback.selectionClick();
                  setState(() {
                    _mode = m;
                    _lastUsedMode = m;
                  });
                },
                children: {
                  _PickerMode.wheel: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      S.current.pickerModeWheel,
                      style: TextStyle(
                        color: _mode == _PickerMode.wheel
                            ? Colors.white
                            : kTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _PickerMode.keypad: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      S.current.pickerModeKeypad,
                      style: TextStyle(
                        color: _mode == _PickerMode.keypad
                            ? Colors.white
                            : kTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Body (wheel or keypad) ────────────────────────────────────
            if (_mode == _PickerMode.wheel)
              SizedBox(
                height: 220,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(context).brightness,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: kTextPrimary,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: Duration(minutes: _currentMinutes),
                    minuteInterval: 1,
                    onTimerDurationChanged: (d) {
                      _currentMinutes = d.inMinutes.clamp(1, 1439);
                    },
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NumericInput(
                      controller: _hCtrl,
                      label: S.current.hoursShort,
                      max: 23,
                      accent: widget.accent,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ':',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _NumericInput(
                      controller: _mCtrl,
                      label: S.current.minutesShort,
                      max: 59,
                      accent: widget.accent,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _PickerMode { wheel, keypad }

class _NumericInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int max;
  final Color accent;

  const _NumericInput({
    required this.controller,
    required this.label,
    required this.max,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 2,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              // Clamp on input — paste of "99" snaps to 23 or 59.
              _MaxIntFormatter(max),
            ],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// TextInputFormatter that caps numeric input at [max].
class _MaxIntFormatter extends TextInputFormatter {
  final int max;
  _MaxIntFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null) return oldValue;
    if (n > max) {
      final clamped = max.toString();
      return TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
    }
    return newValue;
  }
}

// ── App Selection Card ──────────────────────────────────────────────────────
/// Highly visible card showing how many apps are picked for THIS profile.
///
/// Apple keeps app names opaque (FamilyActivityToken is unreadable outside
/// the picker / shield UI), so we can't list "Safari, Mail" by name. We
/// can however make the count + edit hint loud enough that users always
/// understand what's in this profile without spelunking.
class _AppSelectionCard extends StatelessWidget {
  final BlockerProfile profile;
  final Color accent;
  final VoidCallback onTap;

  const _AppSelectionCard({
    required this.profile,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final empty = !profile.hasAppsSelected;
    final emphasis = empty ? accent : accent;
    final bg = empty
        ? accent.withValues(alpha: 0.06)
        : accent.withValues(alpha: 0.10);
    final border = empty
        ? accent.withValues(alpha: 0.45)
        : accent.withValues(alpha: 0.30);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: border, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Leading icon disc with the profile's accent.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: emphasis.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  empty ? Icons.add_rounded : Icons.apps_rounded,
                  color: emphasis,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Headline + helper text.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      empty
                          ? S.current.selectAppsToBlock
                          : S.current.appsSelected(profile.appCount),
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      empty
                          ? S.current.tapToChooseApps
                          : S.current.tapToEditSelection,
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                empty ? Icons.add_circle_rounded : Icons.edit_rounded,
                color: emphasis,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
