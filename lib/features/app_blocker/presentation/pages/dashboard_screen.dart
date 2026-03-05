import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profiles_provider.dart';
import '../../domain/entities/blocker_profile.dart';
import '../../domain/entities/usage_stats.dart';
import '../../../../core/constants/strings.dart';
import '../../../../shared/providers/locale_provider.dart';

// ── Design tokens (shared across all blocker screens) ──────────────────────
const kBg = Color(0xFF0D0D0D);
const kSurface = Color(0xFF1A1A1A);
const kSurfaceHigh = Color(0xFF222222);
const kBorder = Color(0xFF2A2A2A);
const kAccent = Color(0xFFE53935);
const kAccentDark = Color(0xFF8B1A1A);
const kTextPrimary = Color(0xFFFFFFFF);
const kTextSecondary = Color(0xFF9E9E9E);
const kRadius = 16.0;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccent,
        foregroundColor: kTextPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showCreateProfileSheet(context, ref),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: profilesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: kAccent)),
          error: (e, _) =>
              Center(child: Text(S.current.errorGeneric(e), style: const TextStyle(color: kAccent))),
          data: (profiles) => _DashboardBody(profiles: profiles),
        ),
      ),
    );
  }

  void _showCreateProfileSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              S.current.newProfile,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.current.createProfileDescription,
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: kTextPrimary, fontSize: 16),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: S.current.profileNameHint,
                hintStyle: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.5), fontSize: 15),
                filled: true,
                fillColor: kBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kAccent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                HapticFeedback.lightImpact();
                final id = await ref
                    .read(profilesProvider.notifier)
                    .createProfile(name: name);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  // Navigate to the profile detail
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _ProfileDetailPageShell(profileId: id),
                  ));
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: kTextPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(S.current.create,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper: routes to profile detail ───────────────────────────────────────
class _ProfileDetailRoute extends ConsumerWidget {
  final String profileId;
  const _ProfileDetailRoute({required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lazy-import to avoid circular deps — the actual screen is in its own file
    // We use a simple inline widget that delegates.
    return _InlineProfileDetail(profileId: profileId);
  }
}

// It's cleaner to keep the detail in its own file, but we need a tiny stub
// here so the bottom-sheet -> navigate flow works.
// The real detail screen will replace this via the router.
class _InlineProfileDetail extends ConsumerStatefulWidget {
  final String profileId;
  const _InlineProfileDetail({required this.profileId});

  @override
  ConsumerState<_InlineProfileDetail> createState() =>
      _InlineProfileDetailState();
}

class _InlineProfileDetailState
    extends ConsumerState<_InlineProfileDetail> {
  @override
  Widget build(BuildContext context) {
    // Forward to the real profile detail page
    return const SizedBox.shrink(); // replaced at router level
  }
}

// ── Dashboard Body ─────────────────────────────────────────────────────────
class _DashboardBody extends ConsumerWidget {
  final List<BlockerProfile> profiles;
  const _DashboardBody({required this.profiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale so the dashboard rebuilds when language changes.
    ref.watch(localeProvider);
    final activeCount = profiles.where((p) => p.isActive).length;

    return CustomScrollView(
      slivers: [
        // ── Header ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: kAccent, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      S.current.appName,
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showSettingsSheet(context, ref),
                      icon: const Icon(Icons.settings_rounded,
                          color: kTextSecondary, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Summary card ───────────────────────────────────────
                _SummaryCard(
                  totalProfiles: profiles.length,
                  activeCount: activeCount,
                ),
                const SizedBox(height: 14),

                // ── Stats row ──────────────────────────────────────────
                _StatsRow(profiles: profiles),
                const SizedBox(height: 20),

                // ── Section title ──────────────────────────────────────
                Row(
                  children: [
                    Text(
                      S.current.profilesSectionTitle,
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${profiles.length}',
                      style: const TextStyle(color: kTextSecondary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── Empty state ────────────────────────────────────────────────
        if (profiles.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      color: kBorder, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    S.current.noProfilesYet,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    S.current.noProfilesTapPlus,
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // ── Profile cards ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: profiles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return _ProfileCard(
                profile: profile,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _ProfileDetailPageShell(
                      profileId: profile.id,
                    ),
                  ));
                },
                onToggle: () async {
                  HapticFeedback.mediumImpact();
                  final notifier = ref.read(profilesProvider.notifier);
                  if (profile.isActive) {
                    // Deactivation requires PIN + timer
                    _showDeactivateDialog(context, ref, profile.id);
                  } else if (!profile.hasAppsSelected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          S.current.noAppsWarning,
                          style: const TextStyle(color: kTextPrimary),
                        ),
                        backgroundColor: kSurface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    await notifier.activateProfile(profile.id);
                  }
                },
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showDeactivateDialog(
      BuildContext context, WidgetRef ref, String profileId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TimerThenPinDialog(
        onConfirm: () =>
            ref.read(profilesProvider.notifier).deactivateProfile(profileId),
        onVerifyPin: (pin) =>
            ref.read(profilesProvider.notifier).verifyPin(pin),
        hasPinSet: () => ref.read(profilesProvider.notifier).hasPinSet(),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(S.current.settings,
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.lock_rounded, color: kTextSecondary),
                title: Text(S.current.changePin,
                    style: TextStyle(color: kTextPrimary)),
                subtitle: Text(S.current.changePinSubtitle,
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: kBg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showPinSetupDialog(context, ref);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading:
                    const Icon(Icons.language_rounded, color: kTextSecondary),
                title: Text(S.current.languageLabel,
                    style: TextStyle(color: kTextPrimary)),
                subtitle: Text(
                    _currentLanguageName(),
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                trailing:
                    const Icon(Icons.chevron_right_rounded, color: kTextSecondary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: kBg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showLanguagePicker(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPinSetupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PinSetupDialog(
        onSave: (pin) => ref.read(profilesProvider.notifier).savePin(pin),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentCode = S.langCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(S.current.languageLabel,
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._languageEntries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _languageOption(ctx, ref,
                        code: e.code,
                        label: e.nativeName,
                        selected: currentCode == e.code),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  static String _currentLanguageName() => switch (S.langCode) {
        'de' => 'Deutsch',
        'es' => 'Español',
        'fr' => 'Français',
        'hr' => 'Hrvatski',
        _ => 'English',
      };

  static final _languageEntries = [
    (code: 'en', nativeName: 'English'),
    (code: 'de', nativeName: 'Deutsch'),
    (code: 'es', nativeName: 'Español'),
    (code: 'fr', nativeName: 'Français'),
    (code: 'hr', nativeName: 'Hrvatski'),
  ];

  Widget _languageOption(
    BuildContext ctx,
    WidgetRef ref, {
    required String code,
    required String label,
    required bool selected,
  }) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: selected ? kAccent : kTextSecondary,
      ),
      title: Text(label, style: TextStyle(color: kTextPrimary)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: kBg,
      onTap: () async {
        Navigator.pop(ctx);
        await switchLocale(ref, code);
      },
    );
  }
}

// ── Summary Card ───────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int totalProfiles;
  final int activeCount;
  const _SummaryCard({required this.totalProfiles, required this.activeCount});

  @override
  Widget build(BuildContext context) {
    final allActive = totalProfiles > 0 && activeCount == totalProfiles;
    final anyActive = activeCount > 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadius),
        gradient: anyActive
            ? const LinearGradient(
                colors: [Color(0xFF2B0D0D), Color(0xFF1A0808)],
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
                  anyActive
                      ? allActive
                          ? S.current.allShieldsActive
                          : S.current.someShieldsActive(activeCount, totalProfiles)
                      : totalProfiles == 0
                          ? S.current.noProfiles
                          : S.current.shieldsInactive,
                  style: const TextStyle(
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
                  style: const TextStyle(color: kTextSecondary, fontSize: 13),
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
    );
  }
}

// ── Stats Row (dashboard) ──────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<BlockerProfile> profiles;
  const _StatsRow({required this.profiles});

  String _fmtDuration(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    // Total saved minutes across all profiles (persisted + current session).
    int totalSaved = 0;
    int todayUsage = 0;
    int weekAvg = 0;

    for (final p in profiles) {
      totalSaved += p.totalSavedMinutes;
      // Add live session time for currently active profiles.
      if (p.isActive && p.shieldActivatedAt != null) {
        final activated = DateTime.tryParse(p.shieldActivatedAt!);
        if (activated != null) {
          totalSaved += DateTime.now().difference(activated).inMinutes;
        }
      }
      // Mock usage stats.
      if (p.hasAppsSelected) {
        final stats = MockUsageGenerator.generate(
          profileId: p.id,
          appCount: p.appCount,
          isActive: p.isActive,
          shieldActivatedAt: p.shieldActivatedAt,
        );
        todayUsage += stats.todayTotalMinutes;
        weekAvg += stats.weekAvgMinutes;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.timer_off_rounded,
            label: S.current.timeSaved,
            value: _fmtDuration(totalSaved),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.phone_android_rounded,
            label: S.current.today,
            value: _fmtDuration(todayUsage),
            color: kAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.show_chart_rounded,
            label: S.current.dailyAvg,
            value: _fmtDuration(weekAvg),
            color: const Color(0xFF1E88E5),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: kTextSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card ───────────────────────────────────────────────────────────
class _ProfileCard extends ConsumerStatefulWidget {
  final BlockerProfile profile;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _ProfileCard({
    required this.profile,
    required this.onTap,
    required this.onToggle,
  });

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTickerIfActive();
  }

  @override
  void didUpdateWidget(_ProfileCard old) {
    super.didUpdateWidget(old);
    _startTickerIfActive();
  }

  void _startTickerIfActive() {
    _ticker?.cancel();
    if (widget.profile.isActive && !widget.profile.isManualOnly) {
      _ticker = Timer.periodic(
        const Duration(seconds: 30),
        (_) { if (mounted) setState(() {}); },
      );
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
      label: '${profile.name}, ${profile.subtitle}, ${profile.isActive ? S.current.activateShield : S.current.shieldsInactive}',
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
                // ── Icon ─────────────────────────────────────────────────
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
                    color:
                        profile.isActive ? profile.color : kTextSecondary,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Name + subtitle ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
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
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Lock / Unlock indicator ────────────────────────────
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

                // ── Toggle ───────────────────────────────────────────────
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
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(
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

            // ── Mode chips ─────────────────────────────────────────────
            if (profile.scheduleEnabled ||
                profile.usageLimitEnabled ||
                profile.taskModeEnabled) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (profile.scheduleEnabled)
                    _ModeChip(
                      icon: Icons.schedule_rounded,
                      label: S.current.scheduleTitle,
                      color: profile.color,
                      isActive: profile.isActive,
                    ),
                  if (profile.usageLimitEnabled)
                    _ModeChip(
                      icon: Icons.timer_rounded,
                      label: S.current.usageLimitTitle,
                      color: profile.color,
                      isActive: profile.isActive,
                    ),
                  if (profile.taskModeEnabled)
                    _ModeChip(
                      icon: Icons.checklist_rounded,
                      label: S.current.taskModeTitle,
                      color: profile.color,
                      isActive: profile.isActive,
                    ),
                ],
              ),
            ],

            // ── Inline task list ───────────────────────────────────────
            if (profile.taskModeEnabled && profile.tasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(color: kBorder, height: 1),
              const SizedBox(height: 8),
              ...profile.tasks.map((task) => Semantics(
                    label: '${task.title}, ${task.isDone ? S.current.allTasksDoneNote : S.current.tasks}',
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
                  ))),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

/// Small pill showing an active mode.
class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = isActive ? color : kTextSecondary;
    return Container(
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
          Text(
            label,
            style: TextStyle(color: chipColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Profile Detail Page Shell (navigated to from dashboard) ────────────────
// This imports the real detail page. Keeps navigation simple.
class _ProfileDetailPageShell extends ConsumerWidget {
  final String profileId;
  const _ProfileDetailPageShell({required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    return profilesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kAccent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: kBg,
        body: Center(child: Text(S.current.errorGeneric(e))),
      ),
      data: (profiles) {
        final profile = profiles.where((p) => p.id == profileId).firstOrNull;
        if (profile == null) {
          // Profile was deleted, pop back
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return const Scaffold(backgroundColor: kBg);
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

  @override
  void initState() {
    super.initState();
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
    _nameController = TextEditingController(text: p.name);
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

  Future<void> _save() async {
    final notifier = ref.read(profilesProvider.notifier);
    await notifier.updateProfile(widget.profile.copyWith(
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
    ));
  }

  @override
  void dispose() {
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
            // ── App bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: kTextPrimary),
                    onPressed: () {
                      _save();
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  if (!p.isActive)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: kTextSecondary),
                      onPressed: () => _confirmDelete(context),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Profile icon + name ──────────────────────────────
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
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: S.current.profileNamePlaceholder,
                        hintStyle: TextStyle(color: kTextSecondary),
                      ),
                      onChanged: (_) => _save(),
                    ),
                    const SizedBox(height: 8),

                    // ── Color picker ────────────────────────────────────
                    _SectionLabel(S.current.sectionColor),
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
                                setState(() =>
                                    _selectedColorValue = pc.color.toARGB32());
                                _save();
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: pc.color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: kTextPrimary, width: 2.5)
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: kTextPrimary, size: 18)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Icon picker ─────────────────────────────────────
                    _SectionLabel(S.current.sectionIcon),
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
                                child: Icon(pi.icon,
                                    size: 22,
                                    color: isSelected ? accent : kTextSecondary),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Select Apps ─────────────────────────────────────
                    _SectionLabel(S.current.sectionApps),
                    const SizedBox(height: 8),
                    IgnorePointer(
                      ignoring: locked,
                      child: Opacity(
                        opacity: locked ? 0.5 : 1.0,
                        child: _SectionCard(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(kRadius),
                            onTap: () async {
                              await ref
                                  .read(profilesProvider.notifier)
                                  .pickAppsForProfile(p.id);
                              // Prompt PIN setup after first app selection
                              if (mounted) {
                                final notifier =
                                    ref.read(profilesProvider.notifier);
                                final hasPin = await notifier.hasPinSet();
                                if (!hasPin && mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => _PinSetupDialog(
                                      onSave: (pin) => notifier.savePin(pin),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.apps_rounded,
                                      color: accent, size: 22),
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
                                  Icon(Icons.chevron_right_rounded,
                                      color: kTextSecondary, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Usage Stats ─────────────────────────────────────
                    if (p.hasAppsSelected) ...[
                      _SectionLabel(S.current.sectionUsageStats),
                      const SizedBox(height: 8),
                      _ProfileUsageSection(profile: p, accent: accent),
                      const SizedBox(height: 24),
                    ],

                    // ── Block Rules (combinable) ────────────────────────
                    _SectionLabel(S.current.sectionBlockRules),
                    const SizedBox(height: 4),
                    Text(
                      locked
                          ? S.current.settingsLockedWhileActive
                          : S.current.blockRulesDescription,
                      style: TextStyle(
                        color: locked ? kAccent.withValues(alpha: 0.8) : kTextSecondary,
                        fontSize: 12,
                        fontStyle: locked ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Schedule toggle + config ────────────────────────
                    _RuleToggleCard(
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
                          child: _SectionCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.access_time_rounded,
                                          color: accent, size: 20),
                                      const SizedBox(width: 8),
                                      Text(S.current.scheduleTitle,
                                          style: TextStyle(
                                              color: kTextPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _TimeTile(
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
                                        child: _TimeTile(
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

                    // ── Usage Limit toggle + config ─────────────────────
                    _RuleToggleCard(
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
                          child: _SectionCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.timer_outlined,
                                          color: accent, size: 20),
                                      const SizedBox(width: 8),
                                      Text(S.current.dailyLimit,
                                          style: TextStyle(
                                              color: kTextPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: kBorder,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${_usageLimitMinutes}m',
                                          style: const TextStyle(
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
                                      overlayColor:
                                          accent.withValues(alpha: 0.15),
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8),
                                    ),
                                    child: Slider(
                                      value: _usageLimitMinutes.toDouble(),
                                      min: 5,
                                      max: 180,
                                      divisions: 35,
                                      onChanged: (v) {
                                        setState(() =>
                                            _usageLimitMinutes = v.toInt());
                                      },
                                      onChangeEnd: (_) => _save(),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(S.current.sliderMin,
                                            style: TextStyle(
                                                color: kTextSecondary,
                                                fontSize: 11)),
                                        Text(S.current.sliderMax,
                                            style: TextStyle(
                                                color: kTextSecondary,
                                                fontSize: 11)),
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

                    // ── Task Mode toggle + task list ────────────────────
                    _RuleToggleCard(
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
                      _TaskListSection(
                        profile: p,
                        accent: accent,
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 8),

                    // ── Activate / Deactivate ───────────────────────────
                    if (p.isActive)
                      _FullWidthButton(
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
                            builder: (_) => _TimerThenPinDialog(
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
                      _FullWidthButton(
                        label: p.hasAppsSelected
                            ? S.current.activateShield
                            : S.current.selectAppsToActivate,
                        icon: p.hasAppsSelected
                            ? Icons.shield_rounded
                            : Icons.apps_rounded,
                        color: p.hasAppsSelected ? kTextPrimary : kTextSecondary,
                        bgColor: p.hasAppsSelected ? accent : kSurface,
                        borderColor: p.hasAppsSelected ? null : kBorder,
                        onPressed: p.hasAppsSelected
                            ? () {
                                HapticFeedback.heavyImpact();
                                ref
                                    .read(profilesProvider.notifier)
                                    .activateProfile(p.id);
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      S.current.noAppsWarning,
                                      style: const TextStyle(color: kTextPrimary),
                                    ),
                                    backgroundColor: kSurface,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
          side: const BorderSide(color: kBorder),
        ),
        title: Text(S.current.deleteProfile,
            style: TextStyle(color: kTextPrimary)),
        content: Text(
          S.current.deleteProfileConfirm(widget.profile.name),
          style: const TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text(S.current.cancel, style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(profilesProvider.notifier)
                  .deleteProfile(widget.profile.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child:
                Text(S.current.delete, style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Shared Widgets ─────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: kTextSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

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

class _RuleToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final Color accent;
  final bool locked;
  final ValueChanged<bool> onToggle;

  const _RuleToggleCard({
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
    return Opacity(
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
                        Icon(Icons.lock_rounded, size: 14,
                            color: kTextSecondary.withValues(alpha: 0.6)),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
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
                    decoration: const BoxDecoration(
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
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String formatted;
  final VoidCallback onTap;
  const _TimeTile({
    required this.label,
    required this.formatted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: kTextSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              formatted,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullWidthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color? borderColor;
  final VoidCallback? onPressed;

  const _FullWidthButton({
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
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor:
              enabled ? bgColor : bgColor.withValues(alpha: 0.3),
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
            Icon(icon,
                size: 18,
                color: enabled ? color : color.withValues(alpha: 0.5)),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── PIN Setup Dialog ───────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _PinSetupDialog extends StatefulWidget {
  final Future<void> Function(String pin) onSave;
  const _PinSetupDialog({required this.onSave});

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: const BorderSide(color: kBorder),
      ),
      title: Text(S.current.setPinTitle,
          style: TextStyle(color: kTextPrimary, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.current.setPinDescription,
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildField(_pinController, S.current.enterPin, _obscurePin,
              () => setState(() => _obscurePin = !_obscurePin)),
          const SizedBox(height: 12),
          _buildField(_confirmController, S.current.confirmPin, _obscureConfirm,
              () => setState(() => _obscureConfirm = !_obscureConfirm)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: kAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final pin = _pinController.text.trim();
            final confirm = _confirmController.text.trim();
            if (pin.length < 4) {
              setState(() => _error = S.current.pinTooShort);
              return;
            }
            if (pin != confirm) {
              setState(() => _error = S.current.pinsMismatch);
              return;
            }
            await widget.onSave(pin);
            if (mounted) Navigator.pop(context);
          },
          child: Text(S.current.savePin,
              style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.visiblePassword,
      style: const TextStyle(color: kTextPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccent),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: kTextSecondary, size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Timer + PIN Deactivation Dialog ────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _TimerThenPinDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final Future<bool> Function(String pin) onVerifyPin;
  final Future<bool> Function() hasPinSet;
  const _TimerThenPinDialog({
    required this.onConfirm,
    required this.onVerifyPin,
    required this.hasPinSet,
  });

  @override
  State<_TimerThenPinDialog> createState() => _TimerThenPinDialogState();
}

enum _DeactivateStep { waiting, enterPin }

class _TimerThenPinDialogState extends State<_TimerThenPinDialog> {
  static const _waitSeconds = 5 * 60;
  int _secondsRemaining = _waitSeconds;
  late final StreamSubscription<int> _timer;
  _DeactivateStep _step = _DeactivateStep.waiting;
  bool _pinRequired = true;

  final _pinController = TextEditingController();
  String? _pinError;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _checkPin();
    _timer = Stream.periodic(
      const Duration(seconds: 1),
      (i) => _waitSeconds - 1 - i,
    ).take(_waitSeconds).listen((remaining) {
      if (mounted) {
        setState(() => _secondsRemaining = remaining);
        if (remaining <= 0) {
          setState(() => _step = _DeactivateStep.enterPin);
        }
      }
    });
  }

  Future<void> _checkPin() async {
    final hasPin = await widget.hasPinSet();
    if (mounted) setState(() => _pinRequired = hasPin);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pinController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: const BorderSide(color: kBorder),
      ),
      title: Text(
        _step == _DeactivateStep.waiting
            ? S.current.coolingDown
            : _pinRequired
                ? S.current.enterPinToDeactivate
                : S.current.confirmDeactivation,
        style: const TextStyle(color: kTextPrimary, fontSize: 18),
      ),
      content: _step == _DeactivateStep.waiting
          ? _buildWaiting()
          : _pinRequired
              ? _buildPinEntry()
              : Text(
                  S.current.areYouSureDeactivate,
                  style: TextStyle(color: kTextSecondary, fontSize: 14),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.current.cancel, style: TextStyle(color: kTextSecondary)),
        ),
        if (_step == _DeactivateStep.enterPin)
          TextButton(
            onPressed: _pinRequired ? _verifyAndDeactivate : () {
              Navigator.pop(context);
              widget.onConfirm();
            },
            child: Text(S.current.deactivateAction,
                style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildWaiting() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.current.cooldownDescription,
          style: TextStyle(color: kTextSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          _formattedTime,
          style: const TextStyle(
            color: kAccent,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 1 - (_secondsRemaining / _waitSeconds),
            backgroundColor: kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildPinEntry() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.current.enterTrustedPersonPin,
          style: TextStyle(color: kTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          obscureText: _obscure,
          keyboardType: TextInputType.visiblePassword,
          style: const TextStyle(color: kTextPrimary, fontSize: 16),
          decoration: InputDecoration(
            labelText: S.current.pinLabel,
            labelStyle:
                const TextStyle(color: kTextSecondary, fontSize: 13),
            filled: true,
            fillColor: kBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kAccent),
            ),
            errorText: _pinError,
            errorStyle: const TextStyle(color: kAccent),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: kTextSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _verifyAndDeactivate() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _pinError = S.current.enterYourPin);
      return;
    }
    final valid = await widget.onVerifyPin(pin);
    if (valid) {
      if (mounted) Navigator.pop(context);
      widget.onConfirm();
    } else {
      setState(() => _pinError = S.current.incorrectPin);
    }
  }
}

// ── Task List Section ──────────────────────────────────────────────────────
class _TaskListSection extends ConsumerStatefulWidget {
  final BlockerProfile profile;
  final Color accent;
  const _TaskListSection({required this.profile, required this.accent});

  @override
  ConsumerState<_TaskListSection> createState() => _TaskListSectionState();
}

class _TaskListSectionState extends ConsumerState<_TaskListSection> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;
    ref
        .read(profilesProvider.notifier)
        .addTask(widget.profile.id, title);
    _taskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.profile.tasks;
    final doneCount = tasks.where((t) => t.isDone).length;
    final isActive = widget.profile.isActive;

    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.checklist_rounded,
                  color: widget.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S.current.tasks,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (tasks.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: doneCount == tasks.length
                        ? Colors.green.withValues(alpha: 0.15)
                        : widget.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$doneCount / ${tasks.length}',
                    style: TextStyle(
                      color: doneCount == tasks.length
                          ? Colors.green
                          : widget.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: tasks.isEmpty ? 0 : doneCount / tasks.length,
                backgroundColor: kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(
                  doneCount == tasks.length ? Colors.green : widget.accent,
                ),
                minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Task items
          ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(profilesProvider.notifier)
                            .toggleTask(widget.profile.id, task.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: task.isDone
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: task.isDone ? Colors.green : kBorder,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: task.isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.green, size: 16)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: task.isDone ? kTextSecondary : kTextPrimary,
                          fontSize: 14,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: kTextSecondary,
                        ),
                      ),
                    ),
                    // Delete button (only when shield is NOT active)
                    if (!isActive)
                      GestureDetector(
                        onTap: () => ref
                            .read(profilesProvider.notifier)
                            .removeTask(widget.profile.id, task.id),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded,
                              color: kTextSecondary, size: 18),
                        ),
                      ),
                  ],
                ),
              )),

          // Add-task row (only when shield is NOT active)
          if (!isActive) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    style: const TextStyle(
                        color: kTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: S.current.addTaskHint,
                      hintStyle: const TextStyle(
                          color: kTextSecondary, fontSize: 14),
                      isDense: true,
                      filled: true,
                      fillColor: kBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: widget.accent),
                      ),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTask,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_rounded,
                        color: widget.accent, size: 20),
                  ),
                ),
              ],
            ),
          ],

          // Info note when active
          if (isActive && tasks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: kTextSecondary, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    doneCount == tasks.length
                        ? S.current.allTasksDoneNote
                        : S.current.tasksRemainingNote(tasks.length - doneCount),
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                S.current.emptyTasksHint,
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Profile Usage Stats Section ────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _ProfileUsageSection extends StatelessWidget {
  final BlockerProfile profile;
  final Color accent;
  const _ProfileUsageSection({required this.profile, required this.accent});

  String _fmtMin(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final r = m % 60;
    return r > 0 ? '${h}h ${r}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final stats = MockUsageGenerator.generate(
      profileId: profile.id,
      appCount: profile.appCount,
      isActive: profile.isActive,
      shieldActivatedAt: profile.shieldActivatedAt,
    );

    // Time saved for this profile.
    int savedMinutes = profile.totalSavedMinutes;
    if (profile.isActive && profile.shieldActivatedAt != null) {
      final activated = DateTime.tryParse(profile.shieldActivatedAt!);
      if (activated != null) {
        savedMinutes += DateTime.now().difference(activated).inMinutes;
      }
    }

    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary stat tiles ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.phone_android_rounded,
                    label: S.current.today,
                    value: _fmtMin(stats.todayTotalMinutes),
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.show_chart_rounded,
                    label: S.current.dailyAvg,
                    value: _fmtMin(stats.weekAvgMinutes),
                    color: const Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.timer_off_rounded,
                    label: S.current.saved,
                    value: _fmtMin(savedMinutes),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Weekly bar chart ────────────────────────────────────────
            Text(
              S.current.last7Days,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: _WeekChart(
                history: stats.weekHistory,
                accent: accent,
              ),
            ),
            const SizedBox(height: 16),

            // ── Per-app breakdown ───────────────────────────────────────
            Row(
              children: [
                Text(
                  S.current.appBreakdown,
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  S.current.today,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...stats.appUsages.take(5).map((app) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AppUsageRow(
                    app: app,
                    maxMinutes: stats.appUsages.first.todayMinutes,
                    accent: accent,
                  ),
                )),
            if (stats.appUsages.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  S.current.moreApps(stats.appUsages.length - 5),
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Mini stat tile (inside profile detail) ─────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: kTextSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Week bar chart ─────────────────────────────────────────────────────────
class _WeekChart extends StatelessWidget {
  final List<DailyUsage> history;
  final Color accent;
  const _WeekChart({required this.history, required this.accent});

  static final _dayLabels = S.current.dayLabels;

  @override
  Widget build(BuildContext context) {
    final maxVal = history
        .fold<int>(1, (m, d) => d.totalMinutes > m ? d.totalMinutes : m);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: history.map((day) {
        final fraction = day.totalMinutes / maxVal;
        final isToday = day.date.day == DateTime.now().day &&
            day.date.month == DateTime.now().month;
        final dayLabel = _dayLabels[day.date.weekday - 1];

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: (fraction * 50).clamp(4.0, 50.0),
                  decoration: BoxDecoration(
                    color: isToday
                        ? accent
                        : accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                // Day label
                Text(
                  dayLabel,
                  style: TextStyle(
                    color: isToday ? kTextPrimary : kTextSecondary,
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Per-app usage row ──────────────────────────────────────────────────────
class _AppUsageRow extends StatelessWidget {
  final AppUsage app;
  final int maxMinutes;
  final Color accent;
  const _AppUsageRow({
    required this.app,
    required this.maxMinutes,
    required this.accent,
  });

  String _fmtMin(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final r = m % 60;
    return r > 0 ? '${h}h ${r}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final fraction = maxMinutes > 0 ? app.todayMinutes / maxMinutes : 0.0;

    return Row(
      children: [
        // App name
        SizedBox(
          width: 90,
          child: Text(
            app.appName,
            style: const TextStyle(color: kTextPrimary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: kBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                accent.withValues(alpha: 0.6),
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Duration
        SizedBox(
          width: 50,
          child: Text(
            _fmtMin(app.todayMinutes),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
