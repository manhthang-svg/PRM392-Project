import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/library/library_api.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class TutorialDetailScreen extends StatefulWidget {
  const TutorialDetailScreen({super.key, this.tutorialId = '0', this.gateway});

  final String tutorialId;
  final LibraryGateway? gateway;

  @override
  State<TutorialDetailScreen> createState() => _TutorialDetailScreenState();
}

class _TutorialDetailScreenState extends State<TutorialDetailScreen> {
  Future<TutorialDetailModel>? _tutorial;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tutorial ??=
        (widget.gateway ??
                LibraryApi(AuthScope.of(context, listen: false).apiClient))
            .findTutorial(widget.tutorialId);
  }

  void _retry() {
    setState(() {
      _tutorial =
          (widget.gateway ??
                  LibraryApi(AuthScope.of(context, listen: false).apiClient))
              .findTutorial(widget.tutorialId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TutorialDetailModel>(
      future: _tutorial,
      builder: (context, snapshot) {
        if (snapshot.hasData) return _buildDetail(snapshot.data!);
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: Text('Loading tutorial...')));
      },
    );
  }

  Widget _buildDetail(TutorialDetailModel detail) {
    final tutorial = detail.summary;
    final state = AppStateScope.of(context);
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
                url: tutorial.thumbnailUrl,
                width: double.infinity,
                height: 320,
                fit: BoxFit.contain,
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
                          Text(
                            'by ${tutorial.creatorName}',
                            style: const TextStyle(
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
                      label: tutorial.rating.toStringAsFixed(1),
                      star: true,
                    ),
                    _Metadata(icon: Icons.schedule, label: tutorial.duration),
                    _Metadata(
                      icon: Icons.format_list_numbered,
                      label: '${detail.steps.length} steps',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Description', style: serifTitle(20)),
                const SizedBox(height: 8),
                Text(
                  tutorial.description.isEmpty
                      ? 'No description has been added.'
                      : tutorial.description,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile('Difficulty', tutorial.difficulty),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoTile('Category', tutorial.category)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile('Steps', '${detail.steps.length} steps'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        'Materials',
                        detail.materials.isEmpty
                            ? 'Not specified'
                            : detail.materials.join(', '),
                      ),
                    ),
                  ],
                ),
                if (detail.steps.isNotEmpty) ...[
                  const SizedBox(height: 25),
                  Text('Step preview', style: serifTitle(20)),
                  const SizedBox(height: 11),
                  for (final step in detail.steps.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Text(
                        '${step.stepNumber}. ${step.description}',
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                ],
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
            onPressed: detail.steps.isEmpty
                ? null
                : () => Navigator.pushNamed(
                    context,
                    AppRoutes.tutorialSteps,
                    arguments: detail,
                  ),
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
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
