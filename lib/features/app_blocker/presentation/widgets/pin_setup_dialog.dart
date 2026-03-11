import 'package:flutter/material.dart';
import 'package:unspend/core/constants/strings.dart';
import 'package:unspend/core/theme/design_tokens.dart';

class PinSetupDialog extends StatefulWidget {
  final Future<void> Function(String pin) onSave;
  const PinSetupDialog({super.key, required this.onSave});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
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
        side: BorderSide(color: kBorder),
      ),
      title: Text(
        S.current.setPinTitle,
        style: TextStyle(color: kTextPrimary, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.current.setPinDescription,
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildField(
            _pinController,
            S.current.enterPin,
            _obscurePin,
            () => setState(() => _obscurePin = !_obscurePin),
          ),
          const SizedBox(height: 12),
          _buildField(
            _confirmController,
            S.current.confirmPin,
            _obscureConfirm,
            () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: kAccent, fontSize: 12),
            ),
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
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(
            S.current.savePin,
            style: const TextStyle(color: kAccent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    bool obscure,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.visiblePassword,
      style: TextStyle(color: kTextPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
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
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: kTextSecondary,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
