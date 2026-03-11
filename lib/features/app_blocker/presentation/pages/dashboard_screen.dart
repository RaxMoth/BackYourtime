import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unspend/core/constants/strings.dart';
import 'package:unspend/core/theme/design_tokens.dart';
import 'package:unspend/shared/providers/theme_mode_provider.dart';
import '../providers/profiles_provider.dart';
import '../widgets/dashboard_body.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void _showCreateProfileSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              style: TextStyle(color: kTextPrimary, fontSize: 16),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: S.current.profileNameHint,
                hintStyle: TextStyle(
                  color: kTextSecondary.withAlpha(128),
                  fontSize: 15,
                ),
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
                  borderSide: const BorderSide(color: kAccent),
                ),
              ),
              onSubmitted: (_) => _createProfile(ctx, controller),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _createProfile(ctx, controller),
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: kTextPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                S.current.create,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createProfile(
    BuildContext ctx,
    TextEditingController controller,
  ) async {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.lightImpact();
    final id = await ref
        .read(profilesProvider.notifier)
        .createProfile(name: name);
    if (ctx.mounted) {
      Navigator.pop(ctx);
      ctx.push('/profile/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    ref.watch(themeModeProvider);
    updateTokenBrightness(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccent,
        foregroundColor: kTextPrimary,
        tooltip: S.current.newProfile,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showCreateProfileSheet(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: profilesAsync.when(
        data: (profiles) =>
            SafeArea(child: DashboardBody(profiles: profiles)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    S.current.errorGeneric(e),
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
          });
          return const SafeArea(child: DashboardBody(profiles: []));
        },
      ),
    );
  }
}
