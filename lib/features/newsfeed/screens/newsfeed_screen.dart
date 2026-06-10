import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class NewsfeedHomeTab extends StatelessWidget {
  const NewsfeedHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return SafeArea(
      bottom: false,
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
          SliverList.separated(
            itemCount: state.posts.length,
            itemBuilder: (_, index) => _FeedPostCard(post: state.posts[index]),
            separatorBuilder: (_, _) => const Divider(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
        ],
      ),
    );
  }
}

class _FeedPostCard extends StatefulWidget {
  const _FeedPostCard({required this.post});

  final FeedPostData post;

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  bool _liked = false;
  bool _bookmarked = false;
  int _page = 0;

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostCommentsSheet(postId: widget.post.id),
    );
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
                child: const UserAvatar(size: 42, icon: Icons.palette_outlined),
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
            AspectRatio(
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
                        url:
                            post.networkImages[index - post.localImages.length],
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
            const SizedBox(height: 7),
          ],
          Row(
            children: [
              _FeedAction(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? AppColors.primaryDark : AppColors.ink,
                label: '${post.likes + (_liked ? 1 : 0)}',
                onTap: () => setState(() => _liked = !_liked),
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
          Text.rich(
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
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.tutorialDetail),
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
        ],
      ),
    );
  }
}

class _PostCommentsSheet extends StatefulWidget {
  const _PostCommentsSheet({required this.postId});

  final String postId;

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment(AppState state) {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;
    state.addPostComment(widget.postId, comment);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final post = state.posts.firstWhere((item) => item.id == widget.postId);

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
                  child: post.commentItems.isEmpty
                      ? const Center(
                          child: Text(
                            'No comments yet. Start the conversation.',
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          itemCount: post.commentItems.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, index) {
                            final comment = post.commentItems[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const UserAvatar(size: 38),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              comment.authorName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            comment.createdLabel,
                                            style: const TextStyle(
                                              color: AppColors.mutedText,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment.message),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const UserAvatar(size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: const Key('postCommentField'),
                          controller: _commentController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendComment(state),
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        key: Key('sendPostComment-${post.id}'),
                        onPressed: () => _sendComment(state),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send),
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
