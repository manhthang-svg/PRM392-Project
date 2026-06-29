import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/library/library_api.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key, this.gateway, this.active = true});

  final LibraryGateway? gateway;
  final bool active;

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final _searchController = TextEditingController();
  String? _difficulty;
  String? _category;
  String? _duration;
  LibraryGateway? _gateway;
  List<LibraryTutorial> _allTutorials = const [];
  bool _loading = true;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized || !widget.active) return;
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LibraryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active && !_initialized) {
      _initialize();
    }
  }

  void _initialize() {
    _initialized = true;
    _gateway =
        widget.gateway ??
        LibraryApi(AuthScope.of(context, listen: false).apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tutorials = await _gateway!.findTutorials();
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).replaceLibraryTutorials(tutorials);
      setState(() => _allTutorials = tutorials);
    } on LibraryFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final tutorials = _allTutorials.where((tutorial) {
      final matchesQuery =
          query.isEmpty ||
          tutorial.title.toLowerCase().contains(query) ||
          tutorial.category.toLowerCase().contains(query);
      final matchesDifficulty =
          _difficulty == null || tutorial.difficulty == _difficulty;
      final matchesCategory =
          _category == null || tutorial.category == _category;
      final matchesDuration =
          _duration == null ||
          _matchesDuration(tutorial.estimatedMinutes, _duration!);
      return matchesQuery &&
          matchesDifficulty &&
          matchesCategory &&
          matchesDuration;
    }).toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('library'),
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 166,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppPageTitle('Library', size: 25),
                const SizedBox(height: 15),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search tutorials...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _FilterLeadChip(
                      activeCount: [
                        _category,
                        _difficulty,
                        _duration,
                      ].whereType<String>().length,
                      onTap: _showFilterSheet,
                    ),
                  ),
                ),
              ],
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Loading tutorials...',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _LibraryError(message: _error!, onRetry: _load),
            )
          else if (tutorials.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No approved tutorials match these filters.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid.builder(
                itemCount: tutorials.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: .68,
                ),
                itemBuilder: (_, index) =>
                    _TutorialCard(tutorial: tutorials[index]),
              ),
            ),
        ],
      ),
    );
  }

  bool _matchesDuration(int minutes, String duration) {
    return switch (duration) {
      'Under 15 min' => minutes < 15,
      '15-30 min' => minutes >= 15 && minutes < 30,
      '30-60 min' => minutes >= 30 && minutes <= 60,
      'Over 60 min' => minutes > 60,
      _ => true,
    };
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<_LibraryFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LibraryFilterSheet(
        category: _category,
        difficulty: _difficulty,
        duration: _duration,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _category = result.category;
      _difficulty = result.difficulty;
      _duration = result.duration;
    });
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterLeadChip extends StatelessWidget {
  const _FilterLeadChip({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;

    return Material(
      color: isActive ? AppColors.primaryDark : Colors.white,
      elevation: isActive ? 2 : 0,
      shadowColor: AppColors.primaryDark.withValues(alpha: .22),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(8, 6, 13, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? AppColors.primaryDark : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: .16)
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: isActive ? Colors.white : AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Filters',
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.mutedText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryFilterResult {
  const _LibraryFilterResult({this.category, this.difficulty, this.duration});

  final String? category;
  final String? difficulty;
  final String? duration;
}

class _LibraryFilterSheet extends StatefulWidget {
  const _LibraryFilterSheet({this.category, this.difficulty, this.duration});

  final String? category;
  final String? difficulty;
  final String? duration;

  @override
  State<_LibraryFilterSheet> createState() => _LibraryFilterSheetState();
}

class _LibraryFilterSheetState extends State<_LibraryFilterSheet> {
  late String? _category;
  late String? _difficulty;
  late String? _duration;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _difficulty = widget.difficulty;
    _duration = widget.duration;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 10, 4),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close filters',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_outlined, size: 19),
                          SizedBox(width: 7),
                          Text(
                            'Filters',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    _FilterSection(
                      title: 'Category',
                      values: const [
                        'Animals',
                        'Box',
                        'Flowers',
                        'Geometric',
                        'Traditional',
                        'Birds',
                        'Modular',
                      ],
                      selected: _category,
                      onSelected: (value) => setState(
                        () => _category = _category == value ? null : value,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _FilterSection(
                      title: 'Difficulty',
                      values: const ['Easy', 'Medium', 'Hard'],
                      selected: _difficulty,
                      onSelected: (value) => setState(
                        () => _difficulty = _difficulty == value ? null : value,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _FilterSection(
                      title: 'Duration',
                      values: const [
                        'Under 15 min',
                        '15-30 min',
                        '30-60 min',
                        'Over 60 min',
                      ],
                      selected: _duration,
                      onSelected: (value) => setState(
                        () => _duration = _duration == value ? null : value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlineAppButton(
                      label: 'Reset',
                      onPressed: () => setState(() {
                        _category = null;
                        _difficulty = null;
                        _duration = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Apply Filters',
                      onPressed: () => Navigator.pop(
                        context,
                        _LibraryFilterResult(
                          category: _category,
                          difficulty: _difficulty,
                          duration: _duration,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 9,
          children: values.map((value) {
            final isSelected = selected == value;
            return ChoiceChip(
              label: Text(value),
              selected: isSelected,
              onSelected: (_) => onSelected(value),
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: AppColors.accent,
              side: BorderSide(
                color: isSelected ? AppColors.primaryDark : AppColors.border,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryDark : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({required this.tutorial});

  final LibraryTutorial tutorial;

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeText) = switch (tutorial.difficulty) {
      'Easy' => (const Color(0xFFDFF4E8), const Color(0xFF2C7A50)),
      'Medium' => (const Color(0xFFFFF1C7), const Color(0xFF956600)),
      _ => (const Color(0xFFFDE0E0), const Color(0xFFB64A4A)),
    };

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
          AppRoutes.tutorialDetail,
          arguments: tutorial.id,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppNetworkImage(
                url: tutorial.thumbnailUrl,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tutorial.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 5),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          child: Text(
                            tutorial.difficulty,
                            style: TextStyle(color: badgeText, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFF4C94E),
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${tutorial.rating}',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.schedule,
                        color: AppColors.mutedText,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          tutorial.duration,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
