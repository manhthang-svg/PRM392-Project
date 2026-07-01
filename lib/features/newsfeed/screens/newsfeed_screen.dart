import 'dart:async';

import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/newsfeed/newsfeed_api.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class NewsfeedHomeTab extends StatefulWidget {
  const NewsfeedHomeTab({super.key});

  @override
  State<NewsfeedHomeTab> createState() => _NewsfeedHomeTabState();
}

class _NewsfeedHomeTabState extends State<NewsfeedHomeTab> {
  NewsfeedApi? _api;
  Timer? _clock;
  bool _loaded = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= NewsfeedApi(AuthScope.of(context, listen: false).apiClient);
    if (!_loaded) {
      _loaded = true;
      _loadFeed();
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _api!.findFeed();
      if (!mounted) return;
      AppStateScope.of(context, listen: false).replaceFeedPosts(posts);
    } on NewsfeedFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadFeed,
        child: CustomScrollView(
          key: const PageStorageKey('newsfeed'),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const AppPageTitle('Newsfeed', size: 25),
              actions: [
                IconButton(
                  tooltip: 'Search users',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.searchUsers),
                  icon: const Icon(Icons.search),
                ),
                const SizedBox(width: 10),
              ],
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(),
              ),
            ),
            if (_loading && state.posts.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && state.posts.isEmpty)
              SliverFillRemaining(
                child: _NewsfeedMessage(
                  icon: Icons.cloud_off_outlined,
                  message: _error!,
                ),
              )
            else if (state.posts.isEmpty)
              const SliverFillRemaining(
                child: _NewsfeedMessage(
                  icon: Icons.dynamic_feed_outlined,
                  message: 'No published posts yet.',
                ),
              )
            else
              SliverList.separated(
                itemCount: state.posts.length,
                itemBuilder: (_, index) =>
                    _FeedPostCard(post: state.posts[index], api: _api!),
                separatorBuilder: (_, _) => const Divider(),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        ),
      ),
    );
  }
}

class _NewsfeedMessage extends StatelessWidget {
  const _NewsfeedMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryDark),
            const SizedBox(height: 10),
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

class _FeedPostCard extends StatefulWidget {
  const _FeedPostCard({required this.post, required this.api});

  final FeedPostData post;
  final NewsfeedApi api;

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  final _quickCommentController = TextEditingController();
  bool _bookmarked = false;
  bool _likeBusy = false;
  bool _commentBusy = false;
  int _page = 0;

  @override
  void dispose() {
    _quickCommentController.dispose();
    super.dispose();
  }

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PostCommentsSheet(postId: widget.post.id, api: widget.api),
    );
  }

  void _openDetail() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            NewsfeedPostDetailScreen(postId: widget.post.id, api: widget.api),
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    setState(() => _likeBusy = true);
    try {
      final post = await widget.api.toggleLike(widget.post.id);
      if (!mounted) return;
      AppStateScope.of(context, listen: false).upsertPostFromServer(post);
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _sendQuickComment() async {
    final content = _quickCommentController.text.trim();
    if (content.isEmpty || _commentBusy) return;
    setState(() => _commentBusy = true);
    try {
      final created = await widget.api.addComment(
        postId: widget.post.id,
        content: content,
      );
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).addPostCommentFromServer(widget.post.id, created);
      _quickCommentController.clear();
      FocusScope.of(context).unfocus();
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _commentBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final imageCount = post.localImages.length + post.networkImages.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: post.authorId == 'me'
                    ? null
                    : () => Navigator.pushNamed(
                        context,
                        AppRoutes.publicProfile,
                        arguments: post.authorId,
                      ),
                child: _FeedAvatar(
                  url: post.authorAvatarUrl,
                  size: 42,
                  icon: Icons.palette_outlined,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: InkWell(
                  onTap: post.authorId == 'me'
                      ? null
                      : () => Navigator.pushNamed(
                          context,
                          AppRoutes.publicProfile,
                          arguments: post.authorId,
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        post.createdLabel,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (imageCount > 0) ...[
            InkWell(
              onTap: _openDetail,
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: imageCount,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemBuilder: (_, index) {
                        if (index < post.localImages.length) {
                          return PickedImageView(
                            file: post.localImages[index],
                            borderRadius: BorderRadius.circular(20),
                          );
                        }
                        return AppNetworkImage(
                          url: post
                              .networkImages[index - post.localImages.length],
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(20),
                        );
                      },
                    ),
                    if (imageCount > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_page + 1}/$imageCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
          ],
          Row(
            children: [
              _FeedAction(
                icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                color: post.likedByMe ? AppColors.primaryDark : AppColors.ink,
                label: '${post.likes}',
                onTap: _toggleLike,
              ),
              _FeedAction(
                key: Key('postComments-${post.id}'),
                icon: Icons.chat_bubble_outline,
                label: '${post.comments}',
                onTap: _openComments,
              ),

              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _bookmarked = !_bookmarked),
                icon: Icon(
                  _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _bookmarked ? AppColors.primaryDark : AppColors.ink,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _openDetail,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: AppColors.ink, height: 1.45),
                children: [
                  TextSpan(
                    text: '${post.authorName} ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: post.caption),
                ],
              ),
            ),
          ),
          if (post.comments > 0)
            TextButton(
              onPressed: _openComments,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 8),
                foregroundColor: AppColors.mutedText,
              ),
              child: Text('View all ${post.comments} comments'),
            ),
          if (post.tutorial != null) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: post.tutorialId == null
                  ? null
                  : () => Navigator.pushNamed(
                      context,
                      AppRoutes.tutorialDetail,
                      arguments: post.tutorialId,
                    ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    'Folded from: ${post.tutorial}',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const UserAvatar(size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _quickCommentController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendQuickComment(),
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _commentBusy ? null : _sendQuickComment,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NewsfeedPostDetailScreen extends StatefulWidget {
  const NewsfeedPostDetailScreen({
    required this.postId,
    required this.api,
    super.key,
  });

  final String postId;
  final NewsfeedApi api;

  @override
  State<NewsfeedPostDetailScreen> createState() =>
      _NewsfeedPostDetailScreenState();
}

class _NewsfeedPostDetailScreenState extends State<NewsfeedPostDetailScreen> {
  final _commentController = TextEditingController();
  static const _commentPageSize = 3;
  Timer? _clock;
  bool _loadingComments = true;
  bool _loadingMoreComments = false;
  bool _hasMoreComments = true;
  bool _sending = false;
  bool _likeBusy = false;
  int _commentPage = 0;
  String _commentSort = 'newest';
  String? _commentError;
  FeedCommentData? _replyingTo;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadComments();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentError = null;
      _commentPage = 0;
      _hasMoreComments = true;
    });
    try {
      final comments = await widget.api.findComments(
        widget.postId,
        page: 0,
        size: _commentPageSize,
        sort: _commentSort,
      );
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).replacePostComments(widget.postId, comments);
      setState(() {
        _commentPage = 1;
        _hasMoreComments = comments.length == _commentPageSize;
      });
    } on NewsfeedFailure catch (error) {
      if (!mounted) return;
      setState(() => _commentError = error.message);
    } finally {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (_loadingMoreComments || !_hasMoreComments) return;
    setState(() => _loadingMoreComments = true);
    try {
      final comments = await widget.api.findComments(
        widget.postId,
        page: _commentPage,
        size: _commentPageSize,
        sort: _commentSort,
      );
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).appendPostComments(widget.postId, comments);
      setState(() {
        _commentPage++;
        _hasMoreComments = comments.length == _commentPageSize;
      });
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _loadingMoreComments = false);
    }
  }

  Future<void> _loadReplies(FeedCommentData comment) async {
    try {
      final replies = await widget.api.findReplies(comment.id, size: 10);
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).appendPostComments(widget.postId, replies);
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    setState(() => _likeBusy = true);
    try {
      final post = await widget.api.toggleLike(widget.postId);
      if (!mounted) return;
      AppStateScope.of(context, listen: false).upsertPostFromServer(post);
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _sendComment(AppState state) async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final created = _replyingTo == null
          ? await widget.api.addComment(postId: widget.postId, content: content)
          : await widget.api.addReply(
              commentId: _replyingTo!.id,
              content: content,
            );
      if (!mounted) return;
      state.addPostCommentFromServer(widget.postId, created);
      _commentController.clear();
      setState(() => _replyingTo = null);
      FocusScope.of(context).unfocus();
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleCommentLike(FeedCommentData comment) async {
    try {
      final updated = await widget.api.toggleCommentLike(comment.id);
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).upsertPostCommentFromServer(widget.postId, updated);
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    }
  }

  Future<void> _editComment(FeedCommentData comment) async {
    final controller = TextEditingController(text: comment.message);
    final content = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 5,
          maxLength: 2000,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
    if (content == null || content.trim().isEmpty) return;
    try {
      final updated = await widget.api.updateComment(
        commentId: comment.id,
        content: content,
      );
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).upsertPostCommentFromServer(widget.postId, updated);
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    }
  }

  Future<void> _deleteComment(FeedCommentData comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text(
          'This comment will be replaced with a deleted notice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final updated = await widget.api.deleteComment(comment.id);
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).upsertPostCommentFromServer(widget.postId, updated);
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final post = state.posts.firstWhere((item) => item.id == widget.postId);
    final topLevelComments = post.commentItems
        .where(
          (comment) => comment.parentId == null || comment.parentId!.isEmpty,
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Post detail', style: serifTitle(23)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadComments,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Row(
              children: [
                _FeedAvatar(
                  url: post.authorAvatarUrl,
                  size: 44,
                  icon: Icons.palette_outlined,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        post.createdLabel,
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
            const SizedBox(height: 16),
            Text(post.caption, style: const TextStyle(height: 1.45)),
            if (post.localImages.isNotEmpty ||
                post.networkImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final image in post.localImages) ...[
                AspectRatio(
                  aspectRatio: 1,
                  child: PickedImageView(
                    file: image,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              for (final url in post.networkImages) ...[
                AppNetworkImage(
                  url: url,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(18),
                ),
                const SizedBox(height: 12),
              ],
            ],
            Row(
              children: [
                _FeedAction(
                  icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                  color: post.likedByMe ? AppColors.primaryDark : AppColors.ink,
                  label: '${post.likes}',
                  onTap: _toggleLike,
                ),
                _FeedAction(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.comments}',
                  onTap: () => FocusScope.of(context).requestFocus(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Comments', style: serifTitle(21))),
                DropdownButton<String>(
                  value: _commentSort,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                    DropdownMenuItem(
                      value: 'relevant',
                      child: Text('Relevant'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null || value == _commentSort) return;
                    setState(() => _commentSort = value);
                    _loadComments();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingComments)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_commentError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _commentError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              )
            else if (topLevelComments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No comments yet. Start the conversation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedText),
                ),
              )
            else
              for (final comment in topLevelComments) ...[
                _CommentThread(
                  comment: comment,
                  allComments: post.commentItems,
                  onReply: (target) => setState(() => _replyingTo = target),
                  onLike: _toggleCommentLike,
                  onEdit: _editComment,
                  onDelete: _deleteComment,
                  onViewReplies: _loadReplies,
                ),
                const SizedBox(height: 16),
              ],
            if (!_loadingComments && _hasMoreComments)
              Center(
                child: TextButton(
                  onPressed: _loadingMoreComments ? null : _loadMoreComments,
                  child: Text(
                    _loadingMoreComments
                        ? 'Loading comments...'
                        : 'View more comments',
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyingTo != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to ${_replyingTo!.authorName}',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _replyingTo = null),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  const UserAvatar(size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(state),
                      decoration: InputDecoration(
                        hintText: _replyingTo == null
                            ? 'Write a comment...'
                            : 'Write a reply...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : () => _sendComment(state),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentThread extends StatelessWidget {
  const _CommentThread({
    required this.comment,
    required this.allComments,
    required this.onReply,
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
    required this.onViewReplies,
  });

  final FeedCommentData comment;
  final List<FeedCommentData> allComments;
  final ValueChanged<FeedCommentData> onReply;
  final ValueChanged<FeedCommentData> onLike;
  final ValueChanged<FeedCommentData> onEdit;
  final ValueChanged<FeedCommentData> onDelete;
  final ValueChanged<FeedCommentData> onViewReplies;

  @override
  Widget build(BuildContext context) {
    final replies = allComments
        .where((reply) => reply.parentId == comment.id)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentTile(
          comment: comment,
          onReply: () => onReply(comment),
          onLike: () => onLike(comment),
          onEdit: () => onEdit(comment),
          onDelete: () => onDelete(comment),
        ),
        if (comment.replyCount > replies.length) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: TextButton(
              onPressed: () => onViewReplies(comment),
              child: Text('View replies (${comment.replyCount})'),
            ),
          ),
        ],
        if (replies.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Column(
              children: [
                for (final reply in replies) ...[
                  _CommentThread(
                    comment: reply,
                    allComments: allComments,
                    onReply: onReply,
                    onLike: onLike,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onViewReplies: onViewReplies,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onReply,
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
  });

  final FeedCommentData comment;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeedAvatar(url: comment.authorAvatarUrl, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.message,
                      style: TextStyle(
                        color: comment.deleted
                            ? AppColors.mutedText
                            : AppColors.ink,
                        fontStyle: comment.deleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    comment.edited
                        ? '${comment.createdLabel} · Edited'
                        : comment.createdLabel,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: comment.deleted ? null : onLike,
                    child: Text(
                      comment.likeCount == 0
                          ? 'Like'
                          : 'Like (${comment.likeCount})',
                      style: TextStyle(
                        color: comment.likedByCurrentUser
                            ? AppColors.primaryDark
                            : AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: comment.deleted ? null : onReply,
                    child: const Text(
                      'Reply',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (comment.canEdit || comment.canDelete) ...[
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Comment actions',
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        if (comment.canEdit)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (comment.canDelete)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ],
                      child: const Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostCommentsSheet extends StatefulWidget {
  const _PostCommentsSheet({required this.postId, required this.api});

  final String postId;
  final NewsfeedApi api;

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  Timer? _clock;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  FeedCommentData? _replyingTo;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadComments();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments = await widget.api.findComments(
        widget.postId,
        size: 50,
        sort: 'newest',
      );
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).replacePostComments(widget.postId, comments);
      for (final comment in comments.where((item) => item.replyCount > 0)) {
        final replies = await widget.api.findReplies(comment.id, size: 50);
        if (!mounted) return;
        AppStateScope.of(
          context,
          listen: false,
        ).appendPostComments(widget.postId, replies);
      }
    } on NewsfeedFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendComment(AppState state) async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final replyTarget = _replyingTo;
      final created = replyTarget == null
          ? await widget.api.addComment(postId: widget.postId, content: comment)
          : await widget.api.addReply(
              commentId: replyTarget.id,
              content: comment,
            );
      if (!mounted) return;
      state.addPostCommentFromServer(widget.postId, created);
      _commentController.clear();
      setState(() => _replyingTo = null);
      FocusScope.of(context).unfocus();
    } on NewsfeedFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startReply(FeedCommentData comment) {
    setState(() => _replyingTo = comment);
    _commentFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final post = state.posts.firstWhere((item) => item.id == widget.postId);
    final topLevelComments = post.commentItems
        .where(
          (comment) => comment.parentId == null || comment.parentId!.isEmpty,
        )
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: .78,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                  child: Row(
                    children: [
                      Text('${post.comments} comments', style: serifTitle(21)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close comments',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                              ),
                            ),
                          ),
                        )
                      : topLevelComments.isEmpty
                      ? const Center(
                          child: Text(
                            'No comments yet. Start the conversation.',
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          itemCount: topLevelComments.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, index) {
                            final comment = topLevelComments[index];
                            final replies = post.commentItems
                                .where((reply) => reply.parentId == comment.id)
                                .toList(growable: false);
                            return _SheetCommentThread(
                              comment: comment,
                              replies: replies,
                              onReply: _startReply,
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 14),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_replyingTo != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 46, bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Replying to ${_replyingTo!.authorName}',
                                  style: const TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: _sending
                                    ? null
                                    : () => setState(() => _replyingTo = null),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Row(
                        children: [
                          const UserAvatar(size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              key: const Key('postCommentField'),
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendComment(state),
                              decoration: InputDecoration(
                                hintText: _replyingTo == null
                                    ? 'Write a comment...'
                                    : 'Write a reply...',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            key: Key('sendPostComment-${post.id}'),
                            onPressed: _sending
                                ? null
                                : () => _sendComment(state),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetCommentThread extends StatelessWidget {
  const _SheetCommentThread({
    required this.comment,
    required this.replies,
    required this.onReply,
  });

  final FeedCommentData comment;
  final List<FeedCommentData> replies;
  final ValueChanged<FeedCommentData> onReply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetCommentTile(comment: comment, onReply: () => onReply(comment)),
        if (replies.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Column(
              children: [
                for (final reply in replies) ...[
                  _SheetCommentTile(
                    comment: reply,
                    onReply: () => onReply(reply),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SheetCommentTile extends StatelessWidget {
  const _SheetCommentTile({required this.comment, required this.onReply});

  final FeedCommentData comment;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final canReply = !comment.deleted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeedAvatar(url: comment.authorAvatarUrl, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    comment.edited
                        ? '${comment.createdLabel} · Edited'
                        : comment.createdLabel,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.message,
                style: TextStyle(
                  color: comment.deleted ? AppColors.mutedText : AppColors.ink,
                  fontStyle: comment.deleted
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${comment.likeCount} likes',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: canReply ? onReply : null,
                    child: Text(
                      'Reply',
                      style: TextStyle(
                        color: canReply
                            ? AppColors.primaryDark
                            : AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedAction extends StatelessWidget {
  const _FeedAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.color = AppColors.ink,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 23, color: color),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(label!, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedAvatar extends StatelessWidget {
  const _FeedAvatar({required this.url, required this.size, this.icon});

  final String url;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return UserAvatar(size: size, icon: icon ?? Icons.person_outline);
    }
    return AppNetworkImage(
      url: url,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}
