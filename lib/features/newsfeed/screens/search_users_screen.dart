import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _controller = TextEditingController();
  final List<String> _recentIds = ['sarah', 'yuki'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final query = _controller.text.trim().toLowerCase();
    final results = state.users.where((user) {
      return query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.handle.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users', style: serifTitle(22)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(75),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search for creators, friends...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (query.isEmpty && _recentIds.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Recent Searches',
                style: TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
            ),
            ..._recentIds.map((id) {
              final user = state.userById(id);
              return _UserTile(
                user: user,
                onTap: () => _openProfile(context, user.id),
                trailing: IconButton(
                  onPressed: () => setState(() => _recentIds.remove(id)),
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.mutedText,
                ),
              );
            }),
            const SizedBox(height: 8),
            const Divider(thickness: 8, color: AppColors.input),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              query.isEmpty ? 'Suggested for You' : 'Search Results',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
          ),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 70),
              child: Center(
                child: Text(
                  'No creators found.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ),
            )
          else
            ...results.map(
              (user) => _UserTile(
                user: user,
                onTap: () => _openProfile(context, user.id),
                trailing: _FollowButton(
                  following: user.isFollowing,
                  onPressed: () => state.toggleFollow(user.id),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context, String userId) {
    if (!_recentIds.contains(userId)) {
      setState(() => _recentIds.insert(0, userId));
    }
    Navigator.pushNamed(context, AppRoutes.publicProfile, arguments: userId);
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.trailing,
    required this.onTap,
  });

  final UserProfileData user;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: const UserAvatar(size: 50),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${user.handle} · ${_compactFollowers(user.followers)} followers',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
      ),
      trailing: trailing,
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onPressed});

  final bool following;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return following
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.border),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Following', style: TextStyle(fontSize: 12)),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.person_add_outlined, size: 15),
            label: const Text('Follow', style: TextStyle(fontSize: 12)),
          );
  }
}

String _compactFollowers(int count) {
  if (count < 1000) return '$count';
  return '${(count / 1000).toStringAsFixed(1)}K';
}
