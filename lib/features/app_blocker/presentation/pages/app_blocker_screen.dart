import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_blocker_provider.dart';
import '../../domain/entities/blocker_config.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
const _kBg = Color(0xFF0D0D0D);
const _kSurface = Color(0xFF1A1A1A);
const _kBorder = Color(0xFF2A2A2A);
const _kAccent = Color(0xFFE53935);
const _kAccentDark = Color(0xFF8B1A1A);
const _kTextPrimary = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF9E9E9E);
const _kRadius = 16.0;

// ── Screen ─────────────────────────────────────────────────────────────────
class AppBlockerScreen extends ConsumerStatefulWidget {
  const AppBlockerScreen({super.key});

  @override
  ConsumerState<AppBlockerScreen> createState() => _AppBlockerScreenState();
}

class _AppBlockerScreenState extends ConsumerState<AppBlockerScreen> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _usageLimitMinutes = 55;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appBlockerProvider.notifier).requestAuthorization();
    });
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final blockerState = ref.watch(appBlockerProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: blockerState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _kAccent),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: _kAccent)),
          ),
          data: (config) => _buildBody(context, config),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BlockerConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.shield_outlined, color: _kAccent, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Unspend',
                style: TextStyle(
                  color: _kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Shield Status Card ───────────────────────────────────────
          _ShieldStatusCard(isActive: config.isShieldActive),
          const SizedBox(height: 16),

          // ── Select Apps ──────────────────────────────────────────────
          _SectionCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(_kRadius),
              onTap: () async {
                await ref.read(appBlockerProvider.notifier).showAppPicker();
                if (mounted) await _showPinSetupDialog(context);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apps_rounded,
                          color: _kTextSecondary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Select Apps to Block',
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (config.hasAppsSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '5 apps selected',
                          style: TextStyle(
                            color: _kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Block on Schedule ────────────────────────────────────────
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: _kTextSecondary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Block on Schedule',
                        style: TextStyle(
                          color: _kTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Start',
                          style: TextStyle(
                              color: _kTextSecondary, fontSize: 13)),
                      const SizedBox(width: 80),
                      const Text('End',
                          style: TextStyle(
                              color: _kTextSecondary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerTile(
                          time: _startTime,
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                              builder: (ctx, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: _kAccent,
                                    surface: _kSurface,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (t != null) setState(() => _startTime = t);
                          },
                          formatted: _fmt(_startTime),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimePickerTile(
                          time: _endTime,
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                              builder: (ctx, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: _kAccent,
                                    surface: _kSurface,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (t != null) setState(() => _endTime = t);
                          },
                          formatted: _fmt(_endTime),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: 'Activate Schedule',
                    onPressed: config.hasAppsSelected
                        ? () =>
                            ref.read(appBlockerProvider.notifier).setSchedule(
                                  startHour: _startTime.hour,
                                  startMinute: _startTime.minute,
                                  endHour: _endTime.hour,
                                  endMinute: _endTime.minute,
                                )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Block After Limit ────────────────────────────────────────
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          color: _kTextSecondary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Block After Limit',
                        style: TextStyle(
                          color: _kTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_usageLimitMinutes}m',
                          style: const TextStyle(
                            color: _kTextPrimary,
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
                      activeTrackColor: _kAccent,
                      inactiveTrackColor: _kBorder,
                      thumbColor: _kTextPrimary,
                      overlayColor: _kAccent.withValues(alpha: 0.15),
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _usageLimitMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      onChanged: (v) =>
                          setState(() => _usageLimitMinutes = v.toInt()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('5 min',
                            style: TextStyle(
                                color: _kTextSecondary, fontSize: 11)),
                        Text('120 min',
                            style: TextStyle(
                                color: _kTextSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ActionButton(
                    label: 'Activate Limit',
                    onPressed: config.hasAppsSelected
                        ? () => ref
                            .read(appBlockerProvider.notifier)
                            .setUsageLimit(minutes: _usageLimitMinutes)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Bottom Action Buttons ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _PrimaryButton(
                  label: 'Block Now',
                  icon: Icons.shield_outlined,
                  onPressed: config.hasAppsSelected && !config.isShieldActive
                      ? () => ref
                          .read(appBlockerProvider.notifier)
                          .activateShieldNow()
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryButton(
                  label: 'Deactivate',
                  icon: Icons.shield_outlined,
                  onPressed: config.isShieldActive
                      ? () => _showDeactivateDialog(context)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TimerThenPinDialog(
        onConfirm: () {
          ref.read(appBlockerProvider.notifier).deactivateShield();
        },
        onVerifyPin: (pin) =>
            ref.read(appBlockerProvider.notifier).verifyPin(pin),
      ),
    );
  }

  /// Shows a PIN setup dialog. Called after first app selection.
  Future<void> _showPinSetupDialog(BuildContext context) async {
    final notifier = ref.read(appBlockerProvider.notifier);
    final hasPin = await notifier.hasPinSet();
    if (hasPin || !mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PinSetupDialog(
        onSave: (pin) async {
          await notifier.savePin(pin);
        },
      ),
    );
  }
}

// ── Shield Status Card ─────────────────────────────────────────────────────
class _ShieldStatusCard extends StatelessWidget {
  final bool isActive;
  const _ShieldStatusCard({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kRadius),
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF2B0D0D), Color(0xFF1A0808)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : _kSurface,
        border: Border.all(
          color: isActive ? _kAccent.withValues(alpha: 0.4) : _kBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? _kAccentDark.withValues(alpha: 0.6)
                  : _kBorder,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 28,
              color: isActive ? _kAccent : _kTextSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Shield Active' : 'Shield Inactive',
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Blocking distracting apps'
                      : 'No apps are being blocked',
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _kAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kAccent.withValues(alpha: 0.6),
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

// ── Section Card ───────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: child,
    );
  }
}

// ── Time Picker Tile ───────────────────────────────────────────────────────
class _TimePickerTile extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;
  final String formatted;
  const _TimePickerTile({
    required this.time,
    required this.onTap,
    required this.formatted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatted,
              style: const TextStyle(
                color: _kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.access_time, color: _kTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Action Button (inside cards) ───────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _ActionButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: enabled ? _kBorder : _kBorder.withValues(alpha: 0.4),
          foregroundColor: enabled ? _kTextPrimary : _kTextSecondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Primary CTA (Block Now) ────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: enabled ? _kAccent : _kAccent.withValues(alpha: 0.3),
        foregroundColor: _kTextPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: enabled ? _kTextPrimary : _kTextSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: enabled ? _kTextPrimary : _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Secondary CTA (Deactivate) ────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _SecondaryButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: _kSurface,
        foregroundColor: enabled ? _kTextPrimary : _kTextSecondary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: enabled ? _kBorder : _kBorder.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: enabled ? _kTextSecondary : _kBorder),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: enabled ? _kTextSecondary : _kBorder,
            ),
          ),
        ],
      ),
    );
  }
}

// ── PIN Setup Dialog ───────────────────────────────────────────────────────
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
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        side: const BorderSide(color: _kBorder),
      ),
      title: const Text('Set Deactivation PIN',
          style: TextStyle(color: _kTextPrimary, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hand your phone to a trusted person.\nThey set a PIN that is required to deactivate the shield.',
            style: TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildPinField(
            controller: _pinController,
            label: 'Enter PIN',
            obscure: _obscurePin,
            onToggle: () => setState(() => _obscurePin = !_obscurePin),
          ),
          const SizedBox(height: 12),
          _buildPinField(
            controller: _confirmController,
            label: 'Confirm PIN',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: _kAccent, fontSize: 12)),
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
              style: TextStyle(color: _kAccent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.visiblePassword,
      style: const TextStyle(color: _kTextPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
        filled: true,
        fillColor: _kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kAccent),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: _kTextSecondary,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ── 5-Minute Timer + PIN Deactivation Dialog ───────────────────────────────
class _TimerThenPinDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final Future<bool> Function(String pin) onVerifyPin;
  const _TimerThenPinDialog({
    required this.onConfirm,
    required this.onVerifyPin,
  });

  @override
  State<_TimerThenPinDialog> createState() => _TimerThenPinDialogState();
}

enum _DeactivateStep { waiting, enterPin }

class _TimerThenPinDialogState extends State<_TimerThenPinDialog> {
  static const _waitSeconds = 5 * 60; // 5 minutes
  int _secondsRemaining = _waitSeconds;
  late final StreamSubscription<int> _timer;
  _DeactivateStep _step = _DeactivateStep.waiting;

  final _pinController = TextEditingController();
  String? _pinError;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
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
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        side: const BorderSide(color: _kBorder),
      ),
      title: Text(
        _step == _DeactivateStep.waiting
            ? 'Cooling Down…'
            : 'Enter PIN to Deactivate',
        style: const TextStyle(color: _kTextPrimary, fontSize: 18),
      ),
      content: _step == _DeactivateStep.waiting
          ? _buildWaitingContent()
          : _buildPinContent(),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: _kTextSecondary)),
        ),
        if (_step == _DeactivateStep.enterPin)
          TextButton(
            onPressed: _verifyAndDeactivate,
            child: const Text('Deactivate',
                style:
                    TextStyle(color: _kAccent, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildWaitingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Take a moment to reconsider.\nThe shield will be deactivatable after the timer.',
          style: TextStyle(color: _kTextSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          _formattedTime,
          style: const TextStyle(
            color: _kAccent,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1 - (_secondsRemaining / _waitSeconds),
              backgroundColor: _kBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter the PIN set by your trusted person.',
          style: TextStyle(color: _kTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          obscureText: _obscure,
          keyboardType: TextInputType.visiblePassword,
          style: const TextStyle(color: _kTextPrimary, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'PIN',
            labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
            filled: true,
            fillColor: _kBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kAccent),
            ),
            errorText: _pinError,
            errorStyle: const TextStyle(color: _kAccent),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: _kTextSecondary,
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
