import 'package:flutter/material.dart';
import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/admin/admin_api.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/core/widgets/common.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: serifTitle(23)),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () async {
              await AuthScope.of(context, listen: false).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            const Text(
              'Choose an area to manage.',
              style: TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 16),
            _AdminFeatureCard(
              icon: Icons.people_alt_outlined,
              title: 'Quản lý user',
              subtitle: 'Xem và quản lý tài khoản người dùng',
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsers),
            ),
            const SizedBox(height: 12),
            _AdminFeatureCard(
              icon: Icons.dynamic_feed_outlined,
              title: 'Quản lý post',
              subtitle: 'Duyệt, từ chối hoặc xuất bản bài post',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.adminPostReview),
            ),
            const SizedBox(height: 12),
            _AdminFeatureCard(
              icon: Icons.menu_book_outlined,
              title: 'Quản lý tutorials',
              subtitle: 'Duyệt các tutorial được gửi lên',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.adminTutorials),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminUsersBody(
      api: AdminApi(AuthScope.of(context, listen: false).apiClient),
    );
  }
}

class AdminTutorialsScreen extends StatelessWidget {
  const AdminTutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminTutorialsBody(
      api: AdminApi(AuthScope.of(context, listen: false).apiClient),
    );
  }
}

class _AdminUsersBody extends StatefulWidget {
  const _AdminUsersBody({required this.api});

  final AdminApi api;

  @override
  State<_AdminUsersBody> createState() => _AdminUsersBodyState();
}

class _AdminUsersBodyState extends State<_AdminUsersBody> {
  List<AdminUserItem> _users = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await widget.api.findUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } on AdminFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý user', style: serifTitle(23))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _AdminMessage(icon: Icons.error_outline, message: _error!)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: const UserAvatar(size: 42),
                      title: Text(
                        user.displayName.isEmpty
                            ? user.username
                            : user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          user.username,
                          if (user.handle.isNotEmpty) '@${user.handle}',
                          if (user.roles.isNotEmpty)
                            'Roles: ${user.roles.join(', ')}',
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AdminTutorialsBody extends StatefulWidget {
  const _AdminTutorialsBody({required this.api});

  final AdminApi api;

  @override
  State<_AdminTutorialsBody> createState() => _AdminTutorialsBodyState();
}

class _AdminTutorialsBodyState extends State<_AdminTutorialsBody> {
  List<LibraryTutorial> _tutorials = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tutorials = await widget.api.findTutorials();
      if (!mounted) return;
      setState(() => _tutorials = tutorials);
    } on AdminFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(LibraryTutorial tutorial) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminTutorialDetailScreen(
          api: widget.api,
          tutorialId: tutorial.id,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý tutorials', style: serifTitle(23))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _AdminMessage(icon: Icons.error_outline, message: _error!)
            : _tutorials.isEmpty
            ? const _AdminMessage(
                icon: Icons.task_alt,
                message: 'Không có tutorial đang chờ duyệt.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _tutorials.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tutorial = _tutorials[index];
                  return Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () => _openDetail(tutorial),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppNetworkImage(
                                  url: tutorial.thumbnailUrl,
                                  width: 72,
                                  height: 72,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tutorial.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${tutorial.creatorName} · ${tutorial.category}',
                                        style: const TextStyle(
                                          color: AppColors.mutedText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tutorial.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.chevron_right,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AdminTutorialDetailScreen extends StatefulWidget {
  const _AdminTutorialDetailScreen({
    required this.api,
    required this.tutorialId,
  });

  final AdminApi api;
  final String tutorialId;

  @override
  State<_AdminTutorialDetailScreen> createState() =>
      _AdminTutorialDetailScreenState();
}

class _AdminTutorialDetailScreenState
    extends State<_AdminTutorialDetailScreen> {
  TutorialDetailModel? _detail;
  bool _loading = true;
  bool _reviewing = false;
  String? _error;

  static const _rejectReasons = [
    'Ảnh chưa rõ hoặc bị thiếu bước',
    'Nội dung hướng dẫn chưa đủ chi tiết',
    'Tutorial không đúng chủ đề origami',
    'Thông tin vật liệu/thời gian chưa hợp lệ',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.api.findTutorial(widget.tutorialId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } on AdminFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve() => _submitReview(status: 'APPROVED');

  Future<void> _reject() async {
    final reason = await _showRejectReasonDialog();
    if (reason == null || reason.trim().isEmpty) return;
    await _submitReview(status: 'REJECTED', note: reason);
  }

  Future<void> _submitReview({required String status, String? note}) async {
    setState(() => _reviewing = true);
    try {
      await widget.api.reviewTutorial(
        id: widget.tutorialId,
        status: status,
        note: note,
      );
      if (!mounted) return;
      showAppMessage(
        context,
        status == 'APPROVED' ? 'Đã duyệt tutorial.' : 'Đã từ chối tutorial.',
      );
      Navigator.pop(context, true);
    } on AdminFailure catch (error) {
      if (!mounted) return;
      showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  Future<String?> _showRejectReasonDialog() {
    final customController = TextEditingController();
    var selectedReason = _rejectReasons.first;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final customReason = customController.text.trim();
            final reason = customReason.isNotEmpty
                ? customReason
                : selectedReason.trim();

            return AlertDialog(
              title: const Text('Lý do từ chối'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn một lý do mẫu hoặc nhập lý do riêng để gửi lại cho người tạo tutorial.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final reason in _rejectReasons)
                          ChoiceChip(
                            label: Text(reason),
                            selected: selectedReason == reason,
                            onSelected: (_) {
                              setDialogState(() => selectedReason = reason);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: customController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Lý do tự nhập',
                        hintText: 'Ví dụ: bước 4 bị thiếu ảnh minh họa...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: reason.isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, reason),
                  child: const Text('Từ chối'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(customController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final tutorial = detail?.summary;

    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết tutorial', style: serifTitle(23))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _AdminMessage(icon: Icons.error_outline, message: _error!)
          : detail == null || tutorial == null
          ? const _AdminMessage(
              icon: Icons.menu_book_outlined,
              message: 'Không tìm thấy tutorial.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                AppNetworkImage(
                  url: tutorial.thumbnailUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(18),
                ),
                const SizedBox(height: 16),
                Text(tutorial.title, style: serifTitle(26)),
                const SizedBox(height: 8),
                Text(
                  '${tutorial.creatorName} • ${tutorial.category} • ${tutorial.difficulty} • ${tutorial.duration}',
                  style: const TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: 16),
                Text(tutorial.description),
                const SizedBox(height: 18),
                _AdminDetailSection(
                  title: 'Vật liệu',
                  child: detail.materials.isEmpty
                      ? const Text(
                          'Chưa có vật liệu.',
                          style: TextStyle(color: AppColors.mutedText),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final material in detail.materials)
                              Chip(label: Text(material)),
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                _AdminDetailSection(
                  title: 'Các bước',
                  child: Column(
                    children: [
                      for (final step in detail.steps) ...[
                        _TutorialStepReviewCard(step: step),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: detail == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reviewing ? null : _reject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _reviewing ? null : _approve,
                      icon: _reviewing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AdminDetailSection extends StatelessWidget {
  const _AdminDetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _TutorialStepReviewCard extends StatelessWidget {
  const _TutorialStepReviewCard({required this.step});

  final TutorialStepModel step;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bước ${step.stepNumber}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (step.mediaUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            AppNetworkImage(
              url: step.mediaUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
          if (step.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(step.description),
          ],
        ],
      ),
    );
  }
}

class _AdminMessage extends StatelessWidget {
  const _AdminMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 54, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.mutedText),
        ),
      ],
    );
  }
}

class _AdminFeatureCard extends StatelessWidget {
  const _AdminFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
