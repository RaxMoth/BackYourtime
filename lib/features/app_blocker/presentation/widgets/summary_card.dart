import 'package:flutter/material.dart';
import 'package:unspend/core/constants/strings.dart';
import 'package:unspend/core/theme/design_tokens.dart';

class SummaryCard extends StatelessWidget {
  final int totalProfiles;
  final int activeCount;
  const SummaryCard({
    super.key,
    required this.totalProfiles,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final allActive = totalProfiles > 0 && activeCount == totalProfiles;
    final anyActive = activeCount > 0;

    final statusLabel = anyActive
        ? allActive
              ? S.current.allShieldsActive
              : S.current.someShieldsActive(activeCount, totalProfiles)
        : totalProfiles == 0
        ? S.current.noProfiles
        : S.current.shieldsInactive;

    return Semantics(
      label: statusLabel,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          gradient: anyActive
              ? LinearGradient(
                  colors: kActiveGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: anyActive ? null : kSurface,
          border: Border.all(
            color: anyActive ? kAccent.withValues(alpha: 0.4) : kBorder,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: anyActive
                    ? kAccentDark.withValues(alpha: 0.6)
                    : kBorder,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 28,
                color: anyActive ? kAccent : kTextSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    anyActive
                        ? S.current.blockingDistractingApps
                        : totalProfiles == 0
                        ? S.current.createProfileToStart
                        : S.current.noProfilesAreActive,
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (anyActive)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: kAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kAccent.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
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
