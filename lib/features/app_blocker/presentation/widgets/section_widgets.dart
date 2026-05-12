import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unspend/core/theme/design_tokens.dart';

// ── Section Label ───────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          color: kTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Section Card ────────────────────────────────────────────────────────────
class SectionCard extends StatelessWidget {
  final Widget child;
  const SectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }
}

// ── Time Tile ───────────────────────────────────────────────────────────────
class TimeTile extends StatelessWidget {
  final String label;
  final String formatted;
  final VoidCallback onTap;
  const TimeTile({
    super.key,
    required this.label,
    required this.formatted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $formatted',
      button: true,
      child: Material(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: kTextSecondary, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  formatted,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pressable Card ──────────────────────────────────────────────────────────
/// A `SectionCard` that responds to taps with ink ripple + haptic feedback.
/// Use whenever a card-shaped surface is itself tappable.
class PressableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HapticFeedbackType haptic;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = HapticFeedbackType.selection,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                _fire(haptic);
                onTap!();
              },
        onLongPress: onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onLongPress!();
              },
        borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kBorder),
          ),
          child: child,
        ),
      ),
    );
  }

  static void _fire(HapticFeedbackType haptic) {
    switch (haptic) {
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
      case HapticFeedbackType.none:
        break;
    }
  }
}

enum HapticFeedbackType { none, selection, light, medium, heavy }

// ── Full Width Button ───────────────────────────────────────────────────────
class FullWidthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color? borderColor;
  final VoidCallback? onPressed;

  const FullWidthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.borderColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          style: TextButton.styleFrom(
            backgroundColor:
                enabled ? bgColor : bgColor.withValues(alpha: 0.3),
            // Slight overlay on press for visible state change
            overlayColor: color.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: borderColor != null
                  ? BorderSide(color: borderColor!)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled ? color : color.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : color.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
