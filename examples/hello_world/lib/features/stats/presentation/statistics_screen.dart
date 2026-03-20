import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import 'widgets/insight_card.dart';
import 'widgets/stat_mini_card.dart';
import 'widgets/weekly_overview_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({
    this.data = _sampleStatistics,
    super.key,
  });

  final StatisticsDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Statistik', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Din træningsfremgang i ét overblik',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              InsightCard(
                title: data.momentum.title,
                message: data.momentum.message,
                icon: data.momentum.icon,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Overblik', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(data.overviewSubtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              WeeklyOverviewCard(
                completedSessions: data.weekly.completedSessions,
                targetSessions: data.weekly.targetSessions,
                progressLabel: data.weekly.progressLabel,
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.miniStats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: 164,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final MiniStatData stat = data.miniStats[index];
                  return StatMiniCard(
                    icon: stat.icon,
                    title: stat.title,
                    value: stat.value,
                    supportingText: stat.supportingText,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatisticsDashboardData {
  const StatisticsDashboardData({
    required this.momentum,
    required this.overviewSubtitle,
    required this.weekly,
    required this.miniStats,
  });

  final MomentumData momentum;
  final String overviewSubtitle;
  final WeeklyOverviewData weekly;
  final List<MiniStatData> miniStats;
}

class MomentumData {
  const MomentumData({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;
}

class WeeklyOverviewData {
  const WeeklyOverviewData({
    required this.completedSessions,
    required this.targetSessions,
    required this.progressLabel,
  });

  final int completedSessions;
  final int targetSessions;
  final String progressLabel;
}

class MiniStatData {
  const MiniStatData({
    required this.icon,
    required this.title,
    required this.value,
    required this.supportingText,
  });

  final IconData icon;
  final String title;
  final String value;
  final String supportingText;
}

const StatisticsDashboardData _sampleStatistics = StatisticsDashboardData(
  momentum: MomentumData(
    title: 'Momentum',
    message: 'Du er på rette spor. Fortsæt 2 pas mere for at ramme ugemålet.',
    icon: Icons.trending_up,
  ),
  overviewSubtitle: 'Her er din udvikling for den aktuelle uge',
  weekly: WeeklyOverviewData(
    completedSessions: 0,
    targetSessions: 3,
    progressLabel: 'Ugefremdrift: 0% af planen',
  ),
  miniStats: <MiniStatData>[
    MiniStatData(
      icon: Icons.local_fire_department,
      title: 'Streak',
      value: '5 dage',
      supportingText: 'Fortsæt for ny rekord',
    ),
    MiniStatData(
      icon: Icons.emoji_events,
      title: 'Seneste PR',
      value: '120 kg',
      supportingText: 'Deadlift • i går',
    ),
    MiniStatData(
      icon: Icons.check_circle,
      title: 'Konsistens',
      value: '82%',
      supportingText: 'Sidste 30 dage',
    ),
    MiniStatData(
      icon: Icons.stacked_bar_chart,
      title: 'Total Volumen',
      value: '12.4t',
      supportingText: 'Denne måned',
    ),
  ],
);
