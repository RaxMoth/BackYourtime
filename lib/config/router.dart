import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterbase/features/app_blocker/presentation/pages/dashboard_screen.dart';

/// App Router Configuration
final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Route not found: ${state.fullPath}'),
    ),
  ),
);
