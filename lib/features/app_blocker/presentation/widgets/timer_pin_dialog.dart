import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unspend/core/constants/strings.dart';
import 'package:unspend/core/theme/design_tokens.dart';

class TimerPinDialog extends StatefulWidget {
  final Future<void> Function() onConfirm;
  final Future<bool> Function(String pin) onVerifyPin;
  final Future<bool> Function() hasPinSet;
  const TimerPinDialog({
    super.key,
    required this.onConfirm,
    required this.onVerifyPin,
    required this.hasPinSet,
  });

  @override
  State<TimerPinDialog> createState() => _TimerPinDialogState();
}

enum _DeactivateStep { waiting, enterPin }

class _TimerPinDialogState extends State<TimerPinDialog> {
  static const _waitSeconds = 300; // 5 minutes

  _DeactivateStep _step = _DeactivateStep.waiting;
  int _remaining = _waitSeconds;
  Timer? _timer;

  bool _pinRequired = true;

  final _pinController = TextEditingController();
  String? _pinError;
  bool _obscure = true;

  // Brute-force protection
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _onTimerDone();
      }
    });
  }

  Future<void> _onTimerDone() async {
    final hasPin = await widget.hasPinSet();
    if (!mounted) return;
    setState(() {
      _pinRequired = hasPin;
      _step = _DeactivateStep.enterPin;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: BorderSide(color: kBorder),
      ),
      title: Text(
        _step == _DeactivateStep.waiting
            ? S.current.deactivateAction
            : _pinRequired
            ? S.current.enterPinToDeactivate
            : S.current.confirmDeactivation,
        style: TextStyle(color: kTextPrimary, fontSize: 18),
      ),
      content: _step == _DeactivateStep.waiting
          ? _buildCountdown()
          : _pinRequired
          ? _buildPinEntry()
          : Text(
              S.current.areYouSureDeactivate,
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            S.current.cancel,
            style: TextStyle(color: kTextSecondary),
          ),
        ),
        if (_step == _DeactivateStep.enterPin)
          TextButton(
            onPressed: _pinRequired
                ? _verifyAndDeactivate
                : () async {
                    Navigator.pop(context);
                    try {
                      await widget.onConfirm();
                    } catch (_) {}
                  },
            child: Text(
              S.current.deactivateAction,
              style:
                  const TextStyle(color: kAccent, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildCountdown() {
    final min = _remaining ~/ 60;
    final sec = _remaining % 60;
    final timeStr =
        '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          timeStr,
          style: const TextStyle(
            color: kAccent,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          S.current.cooldownDescription,
          textAlign: TextAlign.center,
          style: TextStyle(color: kTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 1 - (_remaining / _waitSeconds),
            backgroundColor: kBg,
            valueColor: const AlwaysStoppedAnimation(kAccent),
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
          style: TextStyle(color: kTextPrimary, fontSize: 16),
          decoration: InputDecoration(
            labelText: S.current.pinLabel,
            labelStyle: TextStyle(color: kTextSecondary, fontSize: 13),
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
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final secs = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      setState(() => _pinError = S.current.pinLockedOut(secs));
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _pinError = S.current.enterYourPin);
      return;
    }
    final valid = await widget.onVerifyPin(pin);
    if (valid) {
      _failedAttempts = 0;
      if (mounted) Navigator.pop(context);
      try {
        await widget.onConfirm();
      } catch (_) {}
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        final lockoutSecs = 30 * (_failedAttempts ~/ 5);
        _lockoutUntil = DateTime.now().add(Duration(seconds: lockoutSecs));
        setState(() => _pinError = S.current.pinLockedOut(lockoutSecs));
      } else {
        setState(() => _pinError = S.current.incorrectPin);
      }
    }
  }
}
