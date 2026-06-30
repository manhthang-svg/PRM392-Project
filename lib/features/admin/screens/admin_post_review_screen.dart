import 'package:flutter/material.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/admin/post_review_api.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/widgets/common.dart';

class AdminPostReviewScreen extends StatefulWidget {
  const AdminPostReviewScreen({super.key, this.gateway});

  final PostReviewGateway? gateway;

  @override
  State<AdminPostReviewScreen> createState() => _AdminPostReviewScreenState();
}

class _AdminPostReviewScreenState extends State<AdminPostReviewScreen> {
  PostReviewGateway? _gateway;
  List<AdminPostReviewItem> _posts = const [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gateway ??=
        widget.gateway ??
        PostReviewApi(AuthScope.of(context, listen: false).apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _gateway!.findPosts();
      if (!mounted) return;
      setState(() => _posts = posts);
    } on PostReviewFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(AdminPostReviewItem post) async {
    await _review(post, status: 'PUBLISHED');
  }

  Future<void> _reject(AdminPostReviewItem post) async {
    final note = await _askRejectReason();
    if (note == null || note.trim().isEmpty) return;
    await _review(post, status: 'REJECTED', note: note);
  }

  Future<void> _review(
    AdminPostReviewItem post, {
    required String status,
    String? note,
  }) async {
    try {
      await _gateway!.reviewPost(id: post.id, status: status, note: note);
      if (!mounted) return;
      setState(
        () => _posts = _posts.where((item) => item.id != post.id).toList(),
      );
      showAppMessage(
        context,
        status == 'PUBLISHED' ? 'Post approved' : 'Post rejected',
      );
    } on PostReviewFailure catch (error) {
      if (!mounted) return;
      showAppMessage(context, error.message);
    }
  }

  Future<String?> _askRejectReason() async {
    final controller = TextEditingController();
    try {
      return showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject post'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Reason for rejection',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post Review', style: serifTitle(23))),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AdminEmptyState(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Cannot load post review',
            message: _error!,
          ),
        ],
      );
    }
    if (_posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _AdminEmptyState(
            icon: Icons.task_alt,
            title: 'No pending posts',
            message: 'All community posts have been reviewed.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemBuilder: (context, index) => _PostReviewCard(
        post: _posts[index],
        onApprove: () => _approve(_posts[index]),
        onReject: () => _reject(_posts[index]),
      ),
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemCount: _posts.length,
    );
  }
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(icon, size: 52, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(title, style: serifTitle(22), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostReviewCard extends StatelessWidget {
  const _PostReviewCard({
    required this.post,
    required this.onApprove,
    required this.onReject,
  });

  final AdminPostReviewItem post;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const UserAvatar(size: 42, icon: Icons.person_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        post.tutorialTitle == null
                            ? 'Community post'
                            : 'Folded from ${post.tutorialTitle}',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(post.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.caption, style: const TextStyle(height: 1.35)),
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) => AppNetworkImage(
                    url: post.mediaUrls[index],
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemCount: post.mediaUrls.length,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
