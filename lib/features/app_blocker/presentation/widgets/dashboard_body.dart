import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unspend/core/constants/strings.dart';
import 'package:unspend/core/theme/design_tokens.dart';
import 'package:unspend/shared/providers/locale_provider.dart';
import 'package:unspend/shared/providers/theme_mode_provider.dart';
import '../../domain/entities/blocker_profile.dart';
import '../providers/profiles_provider.dart';
import 'profile_card.dart';
import 'summary_card.dart';
import 'pin_setup_dialog.dart';
import 'timer_pin_dialog.dart';

class DashboardBody extends ConsumerWidget {
  final List<BlockerProfile> profiles;
  const DashboardBody({super.key, required this.profiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    ref.watch(themeModeProvider);
    final activeCount = profiles.where((p) => p.isActive).length;

    return CustomScrollView(
      slivers: [
        // ── Header ─────────────────────────────────────────────────────────
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
                      icon: Icon(
                        Icons.settings_rounded,
                        color: kTextSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Summary card ──────────────────────────────────────────
                SummaryCard(
                  totalProfiles: profiles.length,
                  activeCount: activeCount,
                ),
                const SizedBox(height: 20),

                // ── Section title ─────────────────────────────────────────
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
                      style: TextStyle(color: kTextSecondary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── Empty state ────────────────────────────────────────────────────
        if (profiles.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: kBorder,
                    size: 64,
                  ),
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

        // ── Profile cards ──────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: profiles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return ProfileCard(
                profile: profile,
                onTap: () => context.push('/profile/${profile.id}'),
                onToggle: () async {
                  HapticFeedback.mediumImpact();
                  final notifier = ref.read(profilesProvider.notifier);
                  if (profile.isActive) {
                    _showDeactivateDialog(context, ref, profile.id);
                  } else if (!profile.hasAppsSelected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          S.current.noAppsWarning,
                          style: TextStyle(color: kTextPrimary),
                        ),
                        backgroundColor: kSurface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else if (profile.taskModeEnabled && profile.tasks.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          S.current.noTasksWarning,
                          style: TextStyle(color: kTextPrimary),
                        ),
                        backgroundColor: kSurface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    try {
                      await notifier.activateProfile(profile.id);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              S.current.errorGeneric('Activation failed'),
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
    BuildContext context,
    WidgetRef ref,
    String profileId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TimerPinDialog(
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
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
              Text(
                S.current.settings,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.lock_rounded, color: kTextSecondary),
                title: Text(
                  S.current.changePin,
                  style: TextStyle(color: kTextPrimary),
                ),
                subtitle: Text(
                  S.current.changePinSubtitle,
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: kBg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showPinSetupDialog(context, ref);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.brightness_6_rounded,
                  color: kTextSecondary,
                ),
                title: Text(
                  S.current.themeLabel,
                  style: TextStyle(color: kTextPrimary),
                ),
                subtitle: Text(
                  _currentThemeModeName(ref),
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: kTextSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: kBg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showThemePicker(context, ref);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.language_rounded, color: kTextSecondary),
                title: Text(
                  S.current.languageLabel,
                  style: TextStyle(color: kTextPrimary),
                ),
                subtitle: Text(
                  _currentLanguageName(),
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: kTextSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: kBg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showLanguagePicker(context, ref);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.privacy_tip_outlined,
                  color: kTextSecondary,
                ),
                title: Text(
                  S.current.privacyPolicyTitle,
                  style: TextStyle(color: kTextPrimary),
                ),
                subtitle: Text(
                  S.current.privacyPolicySubtitle,
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: kTextSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: kBg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showPrivacyPolicy(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: kAccent,
                ),
                title: Text(
                  S.current.deleteAllData,
                  style: const TextStyle(color: kAccent),
                ),
                subtitle: Text(
                  S.current.deleteAllDataSubtitle,
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: kBg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteAllDataDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
                S.current.privacyPolicyTitle,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    S.current.privacyPolicyBody,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 14,
                      height: 1.6,
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

  void _showDeleteAllDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: BorderSide(color: kBorder),
        ),
        title: Text(
          S.current.deleteAllData,
          style: const TextStyle(color: kAccent),
        ),
        content: Text(
          S.current.deleteAllDataWarning,
          style: TextStyle(color: kTextSecondary, fontSize: 13),
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
              await ref.read(profilesProvider.notifier).deleteAllData();
            },
            child: Text(
              S.current.deleteAllDataConfirm,
              style: const TextStyle(
                color: kAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPinSetupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinSetupDialog(
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
              Text(
                S.current.languageLabel,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._languageEntries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _languageOption(
                    ctx,
                    ref,
                    code: e.code,
                    label: e.nativeName,
                    selected: currentCode == e.code,
                  ),
                ),
              ),
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
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
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

  static String _currentThemeModeName(WidgetRef ref) {
    final mode = ref.read(themeModeProvider);
    return switch (mode) {
      ThemeMode.system => S.current.themeSystem,
      ThemeMode.light => S.current.themeLight,
      ThemeMode.dark => S.current.themeDark,
    };
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
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
              Text(
                S.current.themeLabel,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._themeEntries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _themeOption(
                    ctx,
                    ref,
                    mode: e.mode,
                    label: e.label(),
                    icon: e.icon,
                    selected: current == e.mode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _themeEntries = [
    (
      mode: ThemeMode.system,
      label: () => S.current.themeSystem,
      icon: Icons.brightness_auto_rounded,
    ),
    (
      mode: ThemeMode.light,
      label: () => S.current.themeLight,
      icon: Icons.light_mode_rounded,
    ),
    (
      mode: ThemeMode.dark,
      label: () => S.current.themeDark,
      icon: Icons.dark_mode_rounded,
    ),
  ];

  Widget _themeOption(
    BuildContext ctx,
    WidgetRef ref, {
    required ThemeMode mode,
    required String label,
    required IconData icon,
    required bool selected,
  }) {
    return ListTile(
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: selected ? kAccent : kTextSecondary,
      ),
      title: Row(
        children: [
          Icon(icon, color: selected ? kAccent : kTextSecondary, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: kTextPrimary)),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: kBg,
      onTap: () {
        Navigator.pop(ctx);
        ref.read(themeModeProvider.notifier).setMode(mode);
      },
    );
  }
}
