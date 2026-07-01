import 'dart:async';

import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/profile/profile_api.dart';
import 'package:origami/core/profile/user_search_api.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _controller = TextEditingController();
  final List<String> _recentIds = [];

  UserSearchApi? _api;
  ProfileApi? _profileApi;
  final Set<String> _busyUserIds = {};
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<String> _resultIds = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final client = AuthScope.of(context, listen: false).apiClient;
    _api ??= UserSearchApi(client);
    _profileApi ??= ProfileApi(client);
    if (_resultIds.isEmpty && !_loading) _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final api = _api;
    if (api == null) return;
    final query = _controller.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await api.search(query: query, size: 30);
      if (!mounted) return;
      AppStateScope.of(context, listen: false).upsertUsersFromSearch(results);
      setState(() {
        _resultIds = results.map((user) => user.id).toList(growable: false);
      });
    } on UserSearchFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(UserProfileData user) async {
    final api = _profileApi;
    if (api == null || _busyUserIds.contains(user.id)) return;
    setState(() => _busyUserIds.add(user.id));
    try {
      final updated = user.isFollowing
          ? await api.unfollow(user.id)
          : await api.follow(user.id);
      if (!mounted) return;
      AppStateScope.of(
        context,
        listen: false,
      ).applyFollowResult(updated, wasFollowing: user.isFollowing);
    } on ProfileFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _busyUserIds.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final query = _controller.text.trim();
    final results = _resultIds
        .map(state.userById)
        .where((user) => user.id != state.currentUser.id)
        .toList(growable: false);

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
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (_) {
                _debounce?.cancel();
                _search();
              },
              decoration: InputDecoration(
                hintText: 'Search by name, username or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          _search();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _search,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      query.isEmpty ? 'Suggested for You' : 'Search Results',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_loading)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (_error != null)
              _SearchMessage(
                icon: Icons.cloud_off_outlined,
                message: _error!,
                actionLabel: 'Try again',
                onAction: _search,
              )
            else if (!_loading && results.isEmpty)
              _SearchMessage(
                icon: Icons.person_search_outlined,
                message: query.isEmpty
                    ? 'No creators to suggest yet.'
                    : 'No creators found for "$query".',
              )
            else
              ...results.map(
                (user) => _UserTile(
                  user: user,
                  onTap: () => _openProfile(context, user.id),
                  trailing: _FollowButton(
                    following: user.isFollowing,
                    busy: _busyUserIds.contains(user.id),
                    onPressed: () => _toggleFollow(user),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
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

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
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
      leading: _SearchUserAvatar(url: user.avatarUrl),
      title: Text(
        user.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

class _SearchUserAvatar extends StatelessWidget {
  const _SearchUserAvatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const UserAvatar(size: 50);
    return AppNetworkImage(
      url: url,
      width: 50,
      height: 50,
      borderRadius: BorderRadius.circular(25),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.following,
    required this.busy,
    required this.onPressed,
  });

  final bool following;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
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
