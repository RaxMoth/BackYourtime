import 'dart:async';
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
    final profilesAsync = ref.watch(profilesProvider);
    return profilesAsync.when(
      loading: () => Scaffold(
        backgroundColor: kBg,
        body: const Center(child: CircularProgressIndicator(color: kAccent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: kBg,
        body: Center(child: Text(S.current.errorGeneric(e))),
      ),
      data: (profiles) {
        final profile = profiles.where((p) => p.id == profileId).firstOrNull;
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

  void _debouncedSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
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
                            return GestureDetector(
                              onTap: () {
                                setState(
                                  () => _selectedColorValue =
                                      pc.color.toARGB32(),
                                );
                                _save();
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: pc.color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: kTextPrimary,
                                          width: 2.5,
                                        )
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: kTextPrimary,
                                        size: 18,
                                      )
                                    : null,
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
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedIconLabel = pi.label);
                                _save();
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accent.withValues(alpha: 0.2)
                                      : kSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? accent : kBorder,
                                  ),
                                ),
                                child: Icon(
                                  pi.icon,
                                  size: 22,
                                  color: isSelected ? accent : kTextSecondary,
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
                        child: SectionCard(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(kRadius),
                            onTap: () async {
                              try {
                                await ref
                                    .read(profilesProvider.notifier)
                                    .pickAppsForProfile(p.id);
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
                              final notifier =
                                  ref.read(profilesProvider.notifier);
                              final hasPin = await notifier.hasPinSet();
                              if (!context.mounted) return;
                              if (!hasPin) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => PinSetupDialog(
                                    onSave: (pin) => notifier.savePin(pin),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.apps_rounded,
                                    color: accent,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    p.hasAppsSelected
                                        ? S.current.appsSelected(p.appCount)
                                        : S.current.selectAppsToBlock,
                                    style: TextStyle(
                                      color: p.hasAppsSelected
                                          ? kTextPrimary
                                          : kTextSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: kTextSecondary,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kBorder,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${_usageLimitMinutes}m',
                                          style: TextStyle(
                                            color: kTextPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: accent,
                                      inactiveTrackColor: kBorder,
                                      thumbColor: kTextPrimary,
                                      overlayColor: accent.withValues(
                                        alpha: 0.15,
                                      ),
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                    ),
                                    child: Slider(
                                      value: _usageLimitMinutes.toDouble(),
                                      min: 5,
                                      max: 180,
                                      divisions: 35,
                                      onChanged: (v) {
                                        setState(
                                          () =>
                                              _usageLimitMinutes = v.toInt(),
                                        );
                                      },
                                      onChangeEnd: (_) => _save(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          S.current.sliderMin,
                                          style: TextStyle(
                                            color: kTextSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          S.current.sliderMax,
                                          style: TextStyle(
                                            color: kTextSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                                                'Activation failed',
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
            child: Text(S.current.delete, style: const TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }
}
