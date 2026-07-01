import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _difficulty = 'All';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final history = state.foldHistory;
    final filtered = _filteredHistory(history);

    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements', style: serifTitle(24)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
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
                Expanded(
                  child: _StatCard(
                    icon: Icons.signal_cellular_alt,
                    value: '${_hardFoldCount(history)}',
                    label: 'Hard folds',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text('Completed History', style: serifTitle(21)),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Filter difficulty',
                  initialValue: _difficulty,
                  onSelected: (value) => setState(() => _difficulty = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'All', child: Text('All')),
                    PopupMenuItem(value: 'Easy', child: Text('Easy')),
                    PopupMenuItem(value: 'Medium', child: Text('Medium')),
                    PopupMenuItem(value: 'Hard', child: Text('Hard')),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.filter_list, size: 16),
                    label: Text(_difficulty),
                    backgroundColor: AppColors.input,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Every successful fold and the photo you saved after finishing.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const _AchievementEmptyState(
                message:
                    'You have not completed any origami yet. Finish a tutorial to unlock your first achievement.',
              )
            else if (filtered.isEmpty)
              _AchievementEmptyState(
                message: 'No $_difficulty achievements yet.',
              )
            else
              ...filtered.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _HistoryCard(item: item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<FoldHistoryData> _filteredHistory(List<FoldHistoryData> history) {
    if (_difficulty == 'All') return history;
    return history
        .where(
          (item) => item.difficulty.toLowerCase() == _difficulty.toLowerCase(),
        )
        .toList(growable: false);
  }
}

class AchievementDetailScreen extends StatelessWidget {
  const AchievementDetailScreen({required this.historyId, super.key});

  final String historyId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final item = _findHistory(state.foldHistory, historyId);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Achievement Detail', style: serifTitle(23)),
        ),
        body: const _AchievementEmptyState(
          message: 'This achievement could not be found.',
        ),
      );
    }

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
          _CompletionDateHero(item: item),
          const SizedBox(height: 18),
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
                  top: 13,
                  left: 13,
                  child: _DifficultyPill(difficulty: item.difficulty),
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
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final FoldHistoryData item;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: item.image, width: double.infinity),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _DifficultyPill(difficulty: item.difficulty),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: _CompletionDateChip(date: item.completedDate),
                  ),
                ],
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.mutedText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionDateHero extends StatelessWidget {
  const _CompletionDateHero({required this.item});

  final FoldHistoryData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 8),
              Text(
                'Completed on',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.completedDate, style: serifTitle(30)),
        ],
      ),
    );
  }
}

class _CompletionDateChip extends StatelessWidget {
  const _CompletionDateChip({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 6),
          Text(
            date,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementEmptyState extends StatelessWidget {
  const _AchievementEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 70, 16, 40),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 52,
            color: AppColors.primaryDark,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 23),
          const SizedBox(height: 7),
          Text(value, style: serifTitle(23)),
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

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: _difficultyColor(difficulty),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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

int _hardFoldCount(List<FoldHistoryData> history) {
  return history
      .where((item) => item.difficulty.toLowerCase() == 'hard')
      .length;
}

FoldHistoryData? _findHistory(List<FoldHistoryData> history, String id) {
  for (final item in history) {
    if (item.id == id) return item;
  }
  return null;
}

Color _difficultyColor(String difficulty) {
  return switch (difficulty.toLowerCase()) {
    'easy' => Colors.green.shade700,
    'medium' => Colors.orange.shade800,
    'hard' => Colors.red.shade700,
    _ => AppColors.primaryDark,
  };
}
