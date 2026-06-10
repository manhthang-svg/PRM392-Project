import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class TutorialDetailScreen extends StatefulWidget {
  const TutorialDetailScreen({super.key, this.tutorialId = 'classic-crane'});

  final String tutorialId;

  @override
  State<TutorialDetailScreen> createState() => _TutorialDetailScreenState();
}

class _TutorialDetailScreenState extends State<TutorialDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final tutorial = state.tutorials.firstWhere(
      (item) => item.id == widget.tutorialId,
      orElse: () => state.tutorials.first,
    );
    final saved = state.savedTutorialIds.contains(tutorial.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleHeaderButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              _CircleHeaderButton(
                icon: saved ? Icons.bookmark : Icons.bookmark_border,
                color: saved ? AppColors.primaryDark : AppColors.ink,
                onPressed: () => state.toggleSavedTutorial(tutorial.id),
              ),
              const SizedBox(width: 8),
              _CircleHeaderButton(
                icon: Icons.ios_share_outlined,
                onPressed: () => showAppMessage(context, 'Tutorial shared'),
              ),
              const SizedBox(width: 14),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: AppNetworkImage(
                url: tutorial.image,
                width: double.infinity,
                height: 320,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            sliver: SliverList.list(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const UserAvatar(size: 48, icon: Icons.palette_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppPageTitle(tutorial.title, size: 27),
                          const SizedBox(height: 5),
                          const Text(
                            'by Sarah Chen',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 21),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    _Metadata(
                      icon: Icons.star,
                      label: '${tutorial.rating}',
                      star: true,
                    ),
                    _Metadata(icon: Icons.schedule, label: tutorial.duration),
                    const _Metadata(
                      icon: Icons.people_outline,
                      label: '12.5K completed',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Description', style: serifTitle(20)),
                const SizedBox(height: 8),
                const Text(
                  'Learn to fold a beautiful traditional crane, one of the most iconic origami designs. This elegant bird symbolizes peace and good fortune. Perfect for beginners looking to master fundamental folding techniques.',
                  style: TextStyle(color: AppColors.mutedText, height: 1.55),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile('Difficulty', tutorial.difficulty),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _InfoTile('Paper Size', '15cm x 15cm'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: _InfoTile('Steps', '12 steps')),
                    SizedBox(width: 12),
                    Expanded(child: _InfoTile('Materials', 'Square paper')),
                  ],
                ),
                const SizedBox(height: 25),
                Text("What You'll Learn", style: serifTitle(20)),
                const SizedBox(height: 11),
                for (final item in const [
                  'Basic valley and mountain folds',
                  'Inside reverse fold technique',
                  'Symmetrical folding',
                  'Creating 3D form from flat paper',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: CircleAvatar(
                            radius: 3,
                            backgroundColor: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: AppColors.mutedText),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: PrimaryButton(
            label: 'Start Folding',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.tutorialSteps),
          ),
        ),
      ),
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  const _CircleHeaderButton({
    required this.icon,
    required this.onPressed,
    this.color = AppColors.ink,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xEEFFFFFF),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 21),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label, this.star = false});

  final IconData icon;
  final String label;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: star ? const Color(0xFFF4C94E) : AppColors.mutedText,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: star ? AppColors.ink : AppColors.mutedText,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
