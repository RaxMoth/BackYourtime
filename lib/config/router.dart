import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unspend/features/app_blocker/presentation/pages/dashboard_screen.dart';
import 'package:unspend/features/app_blocker/presentation/pages/profile_detail_screen.dart';
import 'package:unspend/features/onboarding/presentation/pages/onboarding_screen.dart';

/// App Router Configuration
final goRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_onboarding') ?? false;
    if (!seen && state.fullPath != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/profile/:id',
      name: 'profileDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProfileDetailPageShell(profileId: id);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Route not found: ${state.fullPath}'),
    ),
  ),
);
