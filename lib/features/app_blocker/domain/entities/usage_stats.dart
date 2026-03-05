import 'dart:math';

// ── Per-app usage entry ────────────────────────────────────────────────────

class AppUsage {
  final String appName;
  final String bundleId;
  final int todayMinutes;
  final int weekAvgMinutes;

  const AppUsage({
    required this.appName,
    required this.bundleId,
    required this.todayMinutes,
    required this.weekAvgMinutes,
  });
}

// ── Daily usage snapshot ───────────────────────────────────────────────────

class DailyUsage {
  final DateTime date;
  final int totalMinutes;

  const DailyUsage({required this.date, required this.totalMinutes});
}

// ── Profile usage stats ────────────────────────────────────────────────────

class ProfileUsageStats {
  final String profileId;
  final int todayTotalMinutes;
  final int weekAvgMinutes;
  final List<AppUsage> appUsages;
  final List<DailyUsage> weekHistory; // last 7 days

  const ProfileUsageStats({
    required this.profileId,
    required this.todayTotalMinutes,
    required this.weekAvgMinutes,
    required this.appUsages,
    required this.weekHistory,
  });
}

// ── Mock data generator ────────────────────────────────────────────────────

class MockUsageGenerator {
  // Per-call RNG seeded from profile ID for stable-per-profile but
  // non-flickering results across rebuilds.
  static Random _rngFor(String profileId) => Random(profileId.hashCode);

  static const _mockApps = [
    ('Instagram', 'com.instagram.ios'),
    ('TikTok', 'com.tiktok.ios'),
    ('X (Twitter)', 'com.twitter.ios'),
    ('YouTube', 'com.google.youtube'),
    ('Reddit', 'com.reddit.ios'),
    ('Snapchat', 'com.snapchat.ios'),
    ('Facebook', 'com.facebook.ios'),
    ('Netflix', 'com.netflix.ios'),
    ('Discord', 'com.discord.ios'),
    ('Twitch', 'com.twitch.ios'),
  ];

  /// Generate mock usage stats for a profile based on its app count.
  static ProfileUsageStats generate({
    required String profileId,
    required int appCount,
    required bool isActive,
    String? shieldActivatedAt,
  }) {
    final rng = _rngFor(profileId);
    final count = appCount.clamp(1, _mockApps.length);
    final selectedApps = List.of(_mockApps)
      ..shuffle(rng)
      ..length = count;

    // If shield is active, reduce today's usage proportionally to how long
    // it's been active.
    double reductionFactor = 1.0;
    if (isActive && shieldActivatedAt != null) {
      final activated = DateTime.tryParse(shieldActivatedAt);
      if (activated != null) {
        final hoursActive =
            DateTime.now().difference(activated).inMinutes / 60.0;
        // Each hour of shield reduces usage by ~15% (capped at 80% reduction)
        reductionFactor = (1.0 - (hoursActive * 0.15)).clamp(0.2, 1.0);
      }
    }

    final appUsages = selectedApps.map((app) {
      final weekAvg = 15 + rng.nextInt(60); // 15-75 min avg
      final today = ((10 + rng.nextInt(80)) * reductionFactor).round();
      return AppUsage(
        appName: app.$1,
        bundleId: app.$2,
        todayMinutes: today,
        weekAvgMinutes: weekAvg,
      );
    }).toList()
      ..sort((a, b) => b.todayMinutes.compareTo(a.todayMinutes));

    final todayTotal =
        appUsages.fold<int>(0, (sum, a) => sum + a.todayMinutes);
    final weekAvgTotal =
        appUsages.fold<int>(0, (sum, a) => sum + a.weekAvgMinutes);

    // Generate 7-day history
    final now = DateTime.now();
    final weekHistory = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final base = weekAvgTotal;
      final variance = rng.nextInt((base * 0.4).round()) - (base * 0.2).round();
      final mins = i == 6
          ? todayTotal // today = actual today
          : (base + variance).clamp(0, base * 2);
      return DailyUsage(date: date, totalMinutes: mins);
    });

    return ProfileUsageStats(
      profileId: profileId,
      todayTotalMinutes: todayTotal,
      weekAvgMinutes: weekAvgTotal,
      appUsages: appUsages,
      weekHistory: weekHistory,
    );
  }
}
