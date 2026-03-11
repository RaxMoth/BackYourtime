import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unspend/core/constants/strings.dart';
import 'package:unspend/core/theme/design_tokens.dart';
import '../../domain/entities/blocker_profile.dart';
import '../providers/profiles_provider.dart';

// ── Mode Chip ───────────────────────────────────────────────────────────────
class ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;

  const ModeChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = isActive ? color : kTextSecondary;
    return Semantics(
      label: '$label mode ${isActive ? "active" : "inactive"}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: chipColor),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: chipColor, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Profile Card ────────────────────────────────────────────────────────────
class ProfileCard extends ConsumerStatefulWidget {
  final BlockerProfile profile;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
    required this.onToggle,
  });

  @override
  ConsumerState<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<ProfileCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTickerIfActive();
  }

  @override
  void didUpdateWidget(ProfileCard old) {
    super.didUpdateWidget(old);
    _startTickerIfActive();
  }

  void _startTickerIfActive() {
    _ticker?.cancel();
    if (widget.profile.isActive && !widget.profile.isManualOnly) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final unlocked = profile.isActive && profile.areRequirementsMet;
    return Semantics(
      label:
          '${profile.name}, ${profile.subtitle}, ${profile.isActive ? S.current.activateShield : S.current.shieldsInactive}',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(
              color: profile.isActive
                  ? profile.color.withValues(alpha: 0.4)
                  : kBorder,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: profile.isActive
                          ? profile.color.withValues(alpha: 0.15)
                          : kBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      profile.profileIcon.icon,
                      size: 24,
                      color: profile.isActive
                          ? profile.color
                          : kTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.subtitle,
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Lock indicator
                  if (profile.isActive)
                    Tooltip(
                      message: profile.requirementReason,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (unlocked
                                      ? const Color(0xFF43A047)
                                      : profile.color)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          unlocked
                              ? Icons.lock_open_rounded
                              : Icons.lock_rounded,
                          size: 18,
                          color: unlocked
                              ? const Color(0xFF43A047)
                              : profile.color,
                        ),
                      ),
                    ),
                  if (profile.isActive) const SizedBox(width: 8),

                  // Toggle
                  Semantics(
                    label: profile.isActive
                        ? S.current.deactivateShield
                        : S.current.activateShield,
                    button: true,
                    toggled: profile.isActive,
                    child: GestureDetector(
                      onTap: widget.onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 52,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: profile.isActive
                              ? profile.color
                              : kBorder,
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 250),
                          alignment: profile.isActive
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 24,
                            height: 24,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: kTextPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Mode chips
              if (profile.scheduleEnabled ||
                  profile.usageLimitEnabled ||
                  profile.taskModeEnabled) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (profile.scheduleEnabled)
                      ModeChip(
                        icon: Icons.schedule_rounded,
                        label: S.current.scheduleTitle,
                        color: profile.color,
                        isActive: profile.isActive,
                      ),
                    if (profile.usageLimitEnabled)
                      ModeChip(
                        icon: Icons.timer_rounded,
                        label: S.current.usageLimitTitle,
                        color: profile.color,
                        isActive: profile.isActive,
                      ),
                    if (profile.taskModeEnabled)
                      ModeChip(
                        icon: Icons.checklist_rounded,
                        label: S.current.taskModeTitle,
                        color: profile.color,
                        isActive: profile.isActive,
                      ),
                  ],
                ),
              ],

              // Inline task list
              if (profile.taskModeEnabled && profile.tasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(color: kBorder, height: 1),
                const SizedBox(height: 8),
                ...profile.tasks.map(
                  (task) => Semantics(
                    label:
                        '${task.title}, ${task.isDone ? S.current.allTasksDoneNote : S.current.tasks}',
                    checked: task.isDone,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(profilesProvider.notifier)
                            .toggleTask(profile.id, task.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              task.isDone
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: task.isDone
                                  ? profile.color
                                  : kTextSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  color: task.isDone
                                      ? kTextSecondary
                                      : kTextPrimary,
                                  fontSize: 13,
                                  decoration: task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: kTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
