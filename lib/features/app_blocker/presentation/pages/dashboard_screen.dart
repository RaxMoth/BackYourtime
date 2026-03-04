import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profiles_provider.dart';
import '../../domain/entities/blocker_profile.dart';

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
              Center(child: Text('Error: $e', style: const TextStyle(color: kAccent))),
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
            const Text(
              'New Profile',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a group of apps with its own blocking rules.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: kTextPrimary, fontSize: 16),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Social Media, Games…',
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
                final id = await ref
                    .read(profilesProvider.notifier)
                    .createProfile(name: name);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  // Navigate to the profile detail
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _ProfileDetailRoute(profileId: id),
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
              child: const Text('Create',
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
                    const Text(
                      'FocusLock',
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
                const SizedBox(height: 20),

                // ── Section title ──────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      'Profiles',
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
                  const Text(
                    'No profiles yet',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap + to create your first blocking profile.',
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
                  final notifier = ref.read(profilesProvider.notifier);
                  if (profile.isActive) {
                    // Deactivation requires PIN + timer
                    _showDeactivateDialog(context, ref, profile.id);
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
              const Text('Settings',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.lock_rounded, color: kTextSecondary),
                title: const Text('Change PIN',
                    style: TextStyle(color: kTextPrimary)),
                subtitle: const Text('Trusted-person deactivation PIN',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: kBg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showPinSetupDialog(context, ref);
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
                          ? 'All Shields Active'
                          : '$activeCount of $totalProfiles Active'
                      : totalProfiles == 0
                          ? 'No Profiles'
                          : 'Shields Inactive',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  anyActive
                      ? 'Blocking distracting apps'
                      : totalProfiles == 0
                          ? 'Create a profile to get started'
                          : 'No profiles are active',
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

// ── Profile Card ───────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final BlockerProfile profile;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _ProfileCard({
    required this.profile,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Row(
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
                    style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Toggle ───────────────────────────────────────────────
            GestureDetector(
              onTap: onToggle,
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
          ],
        ),
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
        body: Center(child: Text('Error: $e')),
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
          ? 'Untitled'
          : _nameController.text.trim(),
      colorValue: _selectedColorValue,
      iconLabel: _selectedIconLabel,
      scheduleEnabled: _scheduleEnabled,
      usageLimitEnabled: _usageLimitEnabled,
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
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Profile Name',
                        hintStyle: TextStyle(color: kTextSecondary),
                      ),
                      onChanged: (_) => _save(),
                    ),
                    const SizedBox(height: 8),

                    // ── Color picker ────────────────────────────────────
                    _SectionLabel('Color'),
                    const SizedBox(height: 8),
                    Wrap(
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
                    const SizedBox(height: 20),

                    // ── Icon picker ─────────────────────────────────────
                    _SectionLabel('Icon'),
                    const SizedBox(height: 8),
                    Wrap(
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
                    const SizedBox(height: 24),

                    // ── Select Apps ─────────────────────────────────────
                    _SectionLabel('Apps'),
                    const SizedBox(height: 8),
                    _SectionCard(
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
                                    ? '${p.appCount} apps selected'
                                    : 'Select Apps to Block',
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
                    const SizedBox(height: 24),

                    // ── Block Rules (combinable) ────────────────────────
                    _SectionLabel('Block Rules'),
                    const SizedBox(height: 4),
                    const Text(
                      'Enable one or both. With neither, use Block Now for manual control.',
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    // ── Schedule toggle + config ────────────────────────
                    _RuleToggleCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Schedule',
                      description: 'Hard-block during a daily time window',
                      enabled: _scheduleEnabled,
                      accent: accent,
                      onToggle: (v) {
                        setState(() => _scheduleEnabled = v);
                        _save();
                      },
                    ),
                    if (_scheduleEnabled) ...[
                      _SectionCard(
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
                                  const Text('Schedule',
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
                                      label: 'Start',
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
                                      label: 'End',
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
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),

                    // ── Usage Limit toggle + config ─────────────────────
                    _RuleToggleCard(
                      icon: Icons.timer_rounded,
                      title: 'Usage Limit',
                      description: 'Soft-block after a daily screen-time budget',
                      enabled: _usageLimitEnabled,
                      accent: accent,
                      onToggle: (v) {
                        setState(() => _usageLimitEnabled = v);
                        _save();
                      },
                    ),
                    if (_usageLimitEnabled) ...[
                      _SectionCard(
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
                                  const Text('Daily Limit',
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
                                  children: const [
                                    Text('5 min',
                                        style: TextStyle(
                                            color: kTextSecondary,
                                            fontSize: 11)),
                                    Text('3 hrs',
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
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 8),

                    // ── Activate / Deactivate ───────────────────────────
                    if (p.isActive)
                      _FullWidthButton(
                        label: 'Deactivate Shield',
                        icon: Icons.shield_outlined,
                        color: kTextSecondary,
                        bgColor: kSurface,
                        borderColor: kBorder,
                        onPressed: () {
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
                        label: 'Activate Shield',
                        icon: Icons.shield_rounded,
                        color: kTextPrimary,
                        bgColor: accent,
                        onPressed: p.hasAppsSelected
                            ? () => ref
                                .read(profilesProvider.notifier)
                                .activateProfile(p.id)
                            : null,
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
        title: const Text('Delete Profile',
            style: TextStyle(color: kTextPrimary)),
        content: Text(
          'Delete "${widget.profile.name}"? This cannot be undone.',
          style: const TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: kTextSecondary)),
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
                const Text('Delete', style: TextStyle(color: kAccent)),
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
  final ValueChanged<bool> onToggle;

  const _RuleToggleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.accent,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? kTextPrimary : kTextSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
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
            onTap: () => onToggle(!enabled),
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
      title: const Text('Set Deactivation PIN',
          style: TextStyle(color: kTextPrimary, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hand your phone to a trusted person.\nThey set a PIN that is required to deactivate any shield.',
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildField(_pinController, 'Enter PIN', _obscurePin,
              () => setState(() => _obscurePin = !_obscurePin)),
          const SizedBox(height: 12),
          _buildField(_confirmController, 'Confirm PIN', _obscureConfirm,
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
              setState(() => _error = 'PIN must be at least 4 characters');
              return;
            }
            if (pin != confirm) {
              setState(() => _error = 'PINs do not match');
              return;
            }
            await widget.onSave(pin);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save PIN',
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
            ? 'Cooling Down…'
            : _pinRequired
                ? 'Enter PIN to Deactivate'
                : 'Confirm Deactivation',
        style: const TextStyle(color: kTextPrimary, fontSize: 18),
      ),
      content: _step == _DeactivateStep.waiting
          ? _buildWaiting()
          : _pinRequired
              ? _buildPinEntry()
              : const Text(
                  'Are you sure you want to deactivate?',
                  style: TextStyle(color: kTextSecondary, fontSize: 14),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
        ),
        if (_step == _DeactivateStep.enterPin)
          TextButton(
            onPressed: _pinRequired ? _verifyAndDeactivate : () {
              Navigator.pop(context);
              widget.onConfirm();
            },
            child: const Text('Deactivate',
                style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildWaiting() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Take a moment to reconsider.\nThe shield will be deactivatable after the timer.',
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
        const Text(
          'Enter the PIN set by your trusted person.',
          style: TextStyle(color: kTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          obscureText: _obscure,
          keyboardType: TextInputType.visiblePassword,
          style: const TextStyle(color: kTextPrimary, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'PIN',
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
      setState(() => _pinError = 'Enter your PIN');
      return;
    }
    final valid = await widget.onVerifyPin(pin);
    if (valid) {
      if (mounted) Navigator.pop(context);
      widget.onConfirm();
    } else {
      setState(() => _pinError = 'Incorrect PIN');
    }
  }
}
