import 'package:flutter/material.dart';
import 'package:unspend/core/theme/design_tokens.dart';

class RuleToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final Color accent;
  final bool locked;
  final ValueChanged<bool> onToggle;

  const RuleToggleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.accent,
    this.locked = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title, ${enabled ? "enabled" : "disabled"}',
      toggled: enabled,
      child: Opacity(
        opacity: locked ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? accent.withValues(alpha: 0.08) : kSurface,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(
              color: enabled ? accent.withValues(alpha: 0.4) : kBorder,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: enabled ? accent : kTextSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: enabled ? kTextPrimary : kTextSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: kTextSecondary.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      description,
                      style: TextStyle(color: kTextSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: locked ? null : () => onToggle(!enabled),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: enabled ? accent : kBorder,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment:
                        enabled ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: kTextPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
