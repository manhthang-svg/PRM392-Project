import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final history = state.foldHistory;

    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements', style: serifTitle(24)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_outlined,
                  value: '${history.length}',
                  label: 'Completed',
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_outlined,
                  value: '7',
                  label: 'Day Streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: 27),
          Text('Completed Origami History', style: serifTitle(21)),
          const SizedBox(height: 5),
          const Text(
            'Every successful fold and the photo you saved after finishing.',
            style: TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...history.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.achievementDetail,
                    arguments: item.id,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.6,
                        child: AppNetworkImage(
                          url: item.image,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_outlined,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Completed ${item.completedDate}',
                                    style: const TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class AchievementDetailScreen extends StatelessWidget {
  const AchievementDetailScreen({required this.historyId, super.key});

  final String historyId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final item = state.foldHistory.firstWhere(
      (history) => history.id == historyId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Achievement Detail', style: serifTitle(23)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  url: item.image,
                  borderRadius: BorderRadius.circular(20),
                ),
                Positioned(
                  right: 13,
                  bottom: 13,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          item.completedDate,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(item.title, style: serifTitle(29)),
          const SizedBox(height: 7),
          const Text(
            'Successfully completed and saved to your personal folding history.',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 22),
          _HistoryInfo(
            icon: Icons.calendar_today_outlined,
            label: 'Completed',
            value: item.completedDate,
          ),
          _HistoryInfo(
            icon: Icons.signal_cellular_alt,
            label: 'Difficulty',
            value: item.difficulty,
          ),
          _HistoryInfo(
            icon: Icons.schedule,
            label: 'Time taken',
            value: item.duration,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 23),
          const SizedBox(height: 7),
          Text(value, style: serifTitle(25)),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _HistoryInfo extends StatelessWidget {
  const _HistoryInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
