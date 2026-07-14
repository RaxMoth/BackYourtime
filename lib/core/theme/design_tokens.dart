import 'package:flutter/material.dart';

// ── Brightness-aware token resolver ────────────────────────────────────────
Brightness _brightness = Brightness.dark;

/// Called from the MaterialApp builder to keep tokens in sync with the theme.
void updateTokenBrightness(Brightness b) => _brightness = b;

bool get _isDark => _brightness == Brightness.dark;

// ── Color tokens ───────────────────────────────────────────────────────────
Color get kBg =>
    _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
Color get kSurface =>
    _isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
Color get kSurfaceHigh =>
    _isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0);
Color get kBorder =>
    _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
const kAccent = Color(0xFFE53935);
/// Success / completed state (task done, profile unlocked).
const kSuccess = Color(0xFF43A047);
Color get kAccentDark =>
    _isDark ? const Color(0xFF8B1A1A) : const Color(0xFFFFCDD2);
Color get kTextPrimary =>
    _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
Color get kTextSecondary =>
    _isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

// ── Gradient tokens ────────────────────────────────────────────────────────
List<Color> get kActiveGradient => _isDark
    ? const [Color(0xFF2B0D0D), Color(0xFF1A0808)]
    : const [Color(0xFFFFEBEE), Color(0xFFFFCDD2)];

// ── Radius tokens ──────────────────────────────────────────────────────────
const kRadius = 16.0;
