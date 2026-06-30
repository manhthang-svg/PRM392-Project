import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/profile/profile_api.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class ProfileHomeTab extends StatefulWidget {
  const ProfileHomeTab({super.key});

  @override
  State<ProfileHomeTab> createState() => _ProfileHomeTabState();
}

class _ProfileHomeTabState extends State<ProfileHomeTab> {
  ProfileApi? _api;
  bool _loaded = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= ProfileApi(AuthScope.of(context, listen: false).apiClient);
    if (!_loaded) {
      _loaded = true;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _api!.me();
      if (!mounted) return;
      AppStateScope.of(context, listen: false).applyCurrentUserProfile(profile);
    } on ProfileFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final state = AppStateScope.of(context);
    final user = state.currentUser;

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('profile'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              const Expanded(child: AppPageTitle('Profile', size: 25)),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Center(child: _CurrentUserAvatar(state: state, size: 100)),
          const SizedBox(height: 14),
          Text(user.name, style: serifTitle(27), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            user.handle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 13),
          Text(user.bio, textAlign: TextAlign.center),
          const SizedBox(height: 23),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileStat(
                _compactNumber(user.followers),
                'Followers',
                onTap: () => Navigator.pushNamed(context, AppRoutes.followers),
              ),
              _ProfileStat(
                '${user.following}',
                'Following',
                onTap: () => Navigator.pushNamed(context, AppRoutes.following),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Edit Profile',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _ProfileMenuItem(
            icon: Icons.workspace_premium_outlined,
            label: 'Achievements',
            subtitle: '${state.foldHistory.length} completed origami',
            onTap: () => Navigator.pushNamed(context, AppRoutes.achievements),
          ),
          const SizedBox(height: 10),
          _ProfileMenuItem(
            icon: Icons.bookmark_outline,
            label: 'Saved Tutorials',
            subtitle: '${state.savedTutorials.length} tutorials saved',
            onTap: () => Navigator.pushNamed(context, AppRoutes.savedTutorials),
          ),
          const SizedBox(height: 10),
          if (auth.isAdmin) ...[
            _ProfileMenuItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin Post Review',
              subtitle: 'Approve or reject community posts',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.adminPostReview),
            ),
            const SizedBox(height: 10),
          ],
          _ProfileMenuItem(
            icon: Icons.logout,
            label: 'Log Out',
            subtitle: 'Sign out of your account',
            destructive: true,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar({required this.state, required this.size});

  final AppState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (state.currentAvatar == null) {
      final avatarUrl = state.currentUser.avatarUrl;
      if (avatarUrl.isEmpty) return UserAvatar(size: size);
      return AppNetworkImage(
        url: avatarUrl,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: ClipOval(child: PickedImageView(file: state.currentAvatar!)),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat(this.value, this.label, {this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              Text(value, style: serifTitle(25)),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: onTap == null
                      ? AppColors.mutedText
                      : AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: onTap == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: destructive ? Colors.red.shade700 : AppColors.primaryDark,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: destructive ? Colors.red.shade700 : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text(
        'You will need to sign in again to use your account.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );
  if (shouldLogout != true || !context.mounted) return;
  await AuthScope.maybeOf(context, listen: false)?.logout();
  if (!context.mounted) return;
  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _handleController;
  late final TextEditingController _bioController;
  late final ProfileApi _api;
  bool _initialized = false;
  bool _saving = false;
  XFile? _avatar;
  String _avatarUrl = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _api = ProfileApi(AuthScope.of(context, listen: false).apiClient);
    final state = AppStateScope.of(context, listen: false);
    _nameController = TextEditingController(text: state.currentUser.name);
    _handleController = TextEditingController(text: state.currentUser.handle);
    _bioController = TextEditingController(text: state.currentUser.bio);
    _avatar = state.currentAvatar;
    _avatarUrl = state.currentUser.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null && mounted) setState(() => _avatar = image);
    } catch (_) {
      if (mounted) showAppMessage(context, 'Could not open the photo library');
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    var handle = _handleController.text.trim();
    if (_nameController.text.trim().isEmpty || handle.isEmpty) {
      showAppMessage(context, 'Name and username are required');
      return;
    }
    if (!handle.startsWith('@')) handle = '@$handle';

    setState(() => _saving = true);
    try {
      var avatarUrl = _avatarUrl;
      if (_avatar != null) {
        final uploaded = await _api.uploadAvatar(_avatar!);
        avatarUrl = uploaded.secureUrl;
      }
      final profile = await _api.update(
        displayName: _nameController.text.trim(),
        handle: handle,
        bio: _bioController.text.trim(),
        avatarUrl: avatarUrl,
      );
      if (!mounted) return;
      AppStateScope.of(context, listen: false).applyCurrentUserProfile(profile);
      showAppMessage(context, 'Profile updated');
      Navigator.pop(context);
    } on ProfileFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: serifTitle(23)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                SizedBox.square(
                  dimension: 104,
                  child: _avatar == null
                      ? _avatarUrl.isEmpty
                            ? const UserAvatar(size: 104)
                            : AppNetworkImage(
                                url: _avatarUrl,
                                width: 104,
                                height: 104,
                                borderRadius: BorderRadius.circular(52),
                              )
                      : ClipOval(child: PickedImageView(file: _avatar!)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    onPressed: _pickAvatar,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 19),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _EditField(
            label: 'Full Name',
            controller: _nameController,
            hint: 'Your name',
          ),
          _EditField(
            label: 'Username',
            controller: _handleController,
            hint: '@username',
          ),
          _EditField(
            label: 'Bio',
            controller: _bioController,
            hint: 'Tell people about your origami journey',
            maxLines: 5,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: PrimaryButton(
            label: 'Save Changes',
            icon: _saving ? null : Icons.check,
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final user = state.userById(userId);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name, style: serifTitle(23)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Center(child: UserAvatar(size: 100)),
          const SizedBox(height: 13),
          Text(user.name, style: serifTitle(27), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            user.handle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 13),
          Text(user.bio, textAlign: TextAlign.center),
          const SizedBox(height: 21),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileStat(_compactNumber(user.followers), 'Followers'),
              _ProfileStat('${user.following}', 'Following'),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: user.isFollowing
                ? OutlineAppButton(
                    label: 'Following',
                    icon: Icons.check,
                    onPressed: () => state.toggleFollow(user.id),
                  )
                : PrimaryButton(
                    label: 'Follow',
                    icon: Icons.person_add_outlined,
                    onPressed: () => state.toggleFollow(user.id),
                  ),
          ),
          const SizedBox(height: 27),
          Text('Origami Gallery', style: serifTitle(21)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: user.works.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
            ),
            itemBuilder: (_, index) => AppNetworkImage(
              url: user.works[index],
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedTutorialsScreen extends StatelessWidget {
  const SavedTutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final tutorials = state.savedTutorials;

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Tutorials', style: serifTitle(23)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: tutorials.isEmpty
          ? const Center(
              child: Text(
                'You have not saved any tutorials yet.',
                style: TextStyle(color: AppColors.mutedText),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: tutorials.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final tutorial = tutorials[index];
                return Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.tutorialDetail,
                      arguments: tutorial.id,
                    ),
                    child: SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: AppNetworkImage(url: tutorial.image),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tutorial.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${tutorial.difficulty} · ${tutorial.duration}',
                                    style: const TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Color(0xFFF4C94E),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('${tutorial.rating}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove from saved',
                            onPressed: () =>
                                state.toggleSavedTutorial(tutorial.id),
                            icon: const Icon(
                              Icons.bookmark,
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
    );
  }
}

enum SocialConnectionMode { followers, following }

class SocialConnectionsScreen extends StatefulWidget {
  const SocialConnectionsScreen({required this.mode, super.key});

  final SocialConnectionMode mode;

  @override
  State<SocialConnectionsScreen> createState() =>
      _SocialConnectionsScreenState();
}

class _SocialConnectionsScreenState extends State<SocialConnectionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFollowers = widget.mode == SocialConnectionMode.followers;
    final source = isFollowers ? state.followerUsers : state.followingUsers;
    final query = _searchController.text.trim().toLowerCase();
    final users = source.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.handle.toLowerCase().contains(query);
    }).toList();
    final total = isFollowers
        ? state.currentUser.followers
        : state.currentUser.following;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFollowers ? 'Followers' : 'Following',
          style: serifTitle(23),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isFollowers
                    ? 'Search followers...'
                    : 'Search following...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_compactNumber(total)} ${isFollowers ? 'followers' : 'following'}',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: users.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty
                          ? isFollowers
                                ? 'No followers to show yet.'
                                : 'You are not following anyone yet.'
                          : 'No users match your search.',
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const Divider(indent: 82),
                    itemBuilder: (_, index) {
                      final user = users[index];
                      return ListTile(
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.publicProfile,
                          arguments: user.id,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        leading: const UserAvatar(size: 50),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          user.handle,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        trailing: user.isFollowing
                            ? OutlinedButton(
                                onPressed: () => state.toggleFollow(user.id),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.ink,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  'Following',
                                  style: TextStyle(fontSize: 12),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: () => state.toggleFollow(user.id),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(
                                  Icons.person_add_outlined,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Follow',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _compactNumber(int number) {
  if (number >= 1000) {
    final value = number / 1000;
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}K';
  }
  return '$number';
}
