import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/core/newsfeed/newsfeed_api.dart';
import 'package:origami/core/profile/profile_api.dart';
import 'package:origami/core/profile/user_search_api.dart';

const artworkOne =
    'https://images.unsplash.com/photo-1616680214084-22670a2a9e34?w=900&h=900&fit=crop';
const artworkTwo =
    'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=900&h=900&fit=crop';
const artworkThree =
    'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=900&h=900&fit=crop';
const artworkFour =
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=900&h=900&fit=crop';
const artworkFive =
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=900&h=900&fit=crop';
const artworkSix =
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=900&h=900&fit=crop';

enum SubmissionStatus { draft, processing, approved, rejected }

extension SubmissionStatusLabel on SubmissionStatus {
  String get label => switch (this) {
    SubmissionStatus.draft => 'Draft',
    SubmissionStatus.processing => 'Processing',
    SubmissionStatus.approved => 'Approved',
    SubmissionStatus.rejected => 'Rejected',
  };
}

SubmissionStatus _submissionStatusFromServer(String status) {
  return switch (status.toUpperCase()) {
    'DRAFT' => SubmissionStatus.draft,
    'APPROVED' => SubmissionStatus.approved,
    'REJECTED' => SubmissionStatus.rejected,
    _ => SubmissionStatus.processing,
  };
}

class UserProfileData {
  const UserProfileData({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.followers,
    required this.following,
    this.avatarUrl = '',
    this.isFollowing = false,
    bool? isFollower,
    this.online = false,
    this.works = const [],
  }) : _isFollower = isFollower;

  final String id;
  final String name;
  final String handle;
  final String bio;
  final int followers;
  final int following;
  final String avatarUrl;
  final bool isFollowing;
  final bool? _isFollower;
  final bool online;
  final List<String> works;

  // Nullable backing storage keeps existing web objects valid after hot reload
  // when this field did not exist yet.
  bool get isFollower => _isFollower ?? false;

  UserProfileData copyWith({
    String? id,
    String? name,
    String? handle,
    String? bio,
    int? followers,
    int? following,
    String? avatarUrl,
    bool? isFollowing,
    bool? isFollower,
    bool? online,
    List<String>? works,
  }) {
    return UserProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollower: isFollower ?? this.isFollower,
      online: online ?? this.online,
      works: works ?? this.works,
    );
  }
}

class FeedPostData {
  FeedPostData({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.caption,
    String? createdLabel,
    this.networkImages = const [],
    this.localImages = const [],
    this.tutorial,
    this.tutorialId,
    this.status = 'PUBLISHED',
    this.rejectionReason = '',
    this.authorAvatarUrl = '',
    this.likedByMe = false,
    this.likes = 0,
    this.comments = 0,
    this.createdAt,
    List<FeedCommentData> commentItems = const [],
  }) : _createdLabel = createdLabel,
       _commentItems = List.of(commentItems);

  final String id;
  final String authorId;
  String authorName;
  final String caption;
  final String? _createdLabel;
  final List<String> networkImages;
  final List<XFile> localImages;
  final String? tutorial;
  final String? tutorialId;
  final String status;
  final String rejectionReason;
  final String authorAvatarUrl;
  bool likedByMe;
  int likes;
  int comments;
  List<FeedCommentData>? _commentItems;

  String get createdLabel => createdAt == null
      ? (_createdLabel ?? 'Just now')
      : _relativeLabel(createdAt);

  final DateTime? createdAt;

  // Existing objects created before this field was added receive null on hot
  // reload, so initialize them lazily when comments are first opened.
  List<FeedCommentData> get commentItems =>
      _commentItems ??= <FeedCommentData>[];
}

class FeedCommentData {
  const FeedCommentData({
    this.id = '',
    this.postId = '',
    this.parentId,
    this.replyToUserId,
    required this.authorId,
    required this.authorName,
    required this.message,
    String? createdLabel,
    this.authorAvatarUrl = '',
    this.likeCount = 0,
    this.likedByCurrentUser = false,
    this.replyCount = 0,
    this.deleted = false,
    this.edited = false,
    this.canEdit = false,
    this.canDelete = false,
    this.createdAt,
    this.updatedAt,
  }) : _createdLabel = createdLabel;

  final String id;
  final String postId;
  final String? parentId;
  final String? replyToUserId;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String message;
  final String? _createdLabel;
  final int likeCount;
  final bool likedByCurrentUser;
  final int replyCount;
  final bool deleted;
  final bool edited;
  final bool canEdit;
  final bool canDelete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get createdLabel => createdAt == null
      ? (_createdLabel ?? 'Just now')
      : _relativeLabel(createdAt);

  FeedCommentData copyWith({
    String? message,
    int? likeCount,
    bool? likedByCurrentUser,
    int? replyCount,
    bool? deleted,
    bool? edited,
    bool? canEdit,
    bool? canDelete,
  }) {
    return FeedCommentData(
      id: id,
      postId: postId,
      parentId: parentId,
      replyToUserId: replyToUserId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      message: message ?? this.message,
      createdLabel: createdLabel,
      likeCount: likeCount ?? this.likeCount,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      replyCount: replyCount ?? this.replyCount,
      deleted: deleted ?? this.deleted,
      edited: edited ?? this.edited,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class InstructionStepData {
  const InstructionStepData({required this.image, required this.description});

  final XFile image;
  final String description;
}

class InstructionSubmissionData {
  InstructionSubmissionData({
    required this.id,
    required this.title,
    required this.resources,
    required this.estimatedMinutes,
    required this.difficulty,
    required this.description,
    required this.steps,
    required this.status,
    required this.updatedLabel,
    this.reviewNote = '',
    this.reactions = 0,
    List<String> comments = const [],
  }) : comments = List.of(comments);

  final String id;
  final String title;
  final String resources;
  final int estimatedMinutes;
  final String difficulty;
  final String description;
  final List<InstructionStepData> steps;
  SubmissionStatus status;
  final String updatedLabel;
  final String reviewNote;
  int reactions;
  final List<String> comments;
}

class TutorialData {
  const TutorialData({
    required this.id,
    required this.title,
    required this.image,
    required this.difficulty,
    required this.duration,
    required this.rating,
  });

  final String id;
  final String title;
  final String image;
  final String difficulty;
  final String duration;
  final double rating;
}

class FoldHistoryData {
  const FoldHistoryData({
    required this.id,
    required this.title,
    required this.image,
    required this.completedDate,
    required this.difficulty,
    required this.duration,
  });

  final String id;
  final String title;
  final String image;
  final String completedDate;
  final String difficulty;
  final String duration;
}

class AppState extends ChangeNotifier {
  XFile? currentAvatar;

  UserProfileData currentUser = const UserProfileData(
    id: 'me',
    name: 'Your Name',
    handle: '@yourusername',
    bio:
        'Passionate about origami and sharing creative paper folding techniques with the world',
    followers: 1200,
    following: 342,
  );

  final List<UserProfileData> users = [
    const UserProfileData(
      id: 'sarah',
      name: 'Sarah Chen',
      handle: '@sarahorigami',
      bio:
          'Paper artist creating expressive animals and traditional Japanese models.',
      followers: 12500,
      following: 410,
      isFollowing: true,
      isFollower: true,
      online: true,
      works: [artworkOne, artworkTwo, artworkThree, artworkFour],
    ),
    const UserProfileData(
      id: 'yuki',
      name: 'Yuki Tanaka',
      handle: '@yukifolds',
      bio: 'Modular origami, geometric patterns, and patient tutorials.',
      followers: 18200,
      following: 302,
      isFollower: true,
      online: true,
      works: [artworkThree, artworkTwo, artworkSix],
    ),
    const UserProfileData(
      id: 'alex',
      name: 'Alex Park',
      handle: '@alexpaper',
      bio: 'Learning one fold at a time and documenting the process.',
      followers: 9800,
      following: 620,
      isFollowing: true,
      works: [artworkTwo, artworkOne, artworkFive],
    ),
    const UserProfileData(
      id: 'maria',
      name: 'Maria Silva',
      handle: '@mariaorigami',
      bio: 'Flowers, decorative folds, and colorful paper experiments.',
      followers: 15100,
      following: 488,
      isFollower: true,
      works: [artworkFive, artworkTwo, artworkThree],
    ),
    const UserProfileData(
      id: 'john',
      name: 'John Smith',
      handle: '@johnfolds',
      bio: 'Beginner folder sharing honest progress and useful questions.',
      followers: 7300,
      following: 711,
      isFollowing: true,
      works: [artworkFour, artworkOne],
    ),
    const UserProfileData(
      id: 'emma',
      name: 'Emma Wilson',
      handle: '@emmapaper',
      bio: 'Minimal paper art inspired by nature.',
      followers: 11200,
      following: 395,
      isFollower: true,
      works: [artworkSix, artworkThree, artworkTwo],
    ),
  ];

  final List<FeedPostData> posts = [
    FeedPostData(
      id: 'post-1',
      authorId: 'sarah',
      authorName: 'Sarah Chen',
      caption:
          'Finally completed this intricate phoenix! Took me 3 hours but worth every fold.',
      tutorial: 'Red Phoenix V3',
      networkImages: const [artworkOne],
      likes: 1234,
      comments: 89,
      commentItems: const [
        FeedCommentData(
          authorId: 'yuki',
          authorName: 'Yuki Tanaka',
          message: 'The wing details look incredible!',
          createdLabel: '1h ago',
        ),
        FeedCommentData(
          authorId: 'alex',
          authorName: 'Alex Park',
          message: 'Three hours well spent. Beautiful work!',
          createdLabel: '42m ago',
        ),
      ],
      createdLabel: '2h ago',
    ),
    FeedPostData(
      id: 'post-2',
      authorId: 'yuki',
      authorName: 'Yuki Tanaka',
      caption: 'Loving these geometric patterns! Perfect for beginners.',
      tutorial: 'Modular Star Pattern',
      networkImages: const [artworkTwo],
      likes: 892,
      comments: 45,
      commentItems: const [
        FeedCommentData(
          authorId: 'maria',
          authorName: 'Maria Silva',
          message: 'I want to try this color combination next.',
          createdLabel: '3h ago',
        ),
      ],
      createdLabel: '5h ago',
    ),
    FeedPostData(
      id: 'post-3',
      authorId: 'alex',
      authorName: 'Alex Park',
      caption: 'Cherry blossoms in paper form - celebrating spring!',
      tutorial: 'Sakura Flower',
      networkImages: const [artworkThree],
      likes: 2156,
      comments: 134,
      commentItems: const [
        FeedCommentData(
          authorId: 'sarah',
          authorName: 'Sarah Chen',
          message: 'These petals are so delicate.',
          createdLabel: '6h ago',
        ),
      ],
      createdLabel: '8h ago',
    ),
  ];

  final List<InstructionSubmissionData> submissions = [
    InstructionSubmissionData(
      id: 'instruction-1',
      title: 'Dragon Tutorial',
      resources: '20cm square paper, folding tool',
      estimatedMinutes: 45,
      difficulty: 'Hard',
      description: 'A detailed traditional dragon with shaped wings.',
      steps: const [],
      status: SubmissionStatus.approved,
      updatedLabel: 'Updated May 28',
      reactions: 128,
      comments: const [
        'The wing shaping section is very clear.',
        'Could you add a closer image for step 7?',
      ],
    ),
    InstructionSubmissionData(
      id: 'instruction-2',
      title: 'Rose Flower',
      resources: '15cm red square paper',
      estimatedMinutes: 30,
      difficulty: 'Medium',
      description: 'A layered paper rose suitable for gifts.',
      steps: const [],
      status: SubmissionStatus.processing,
      updatedLabel: 'Sent May 30',
      reactions: 24,
      comments: const ['Review is currently in progress.'],
    ),
    InstructionSubmissionData(
      id: 'instruction-3',
      title: 'Geometric Pattern',
      resources: 'Six square sheets',
      estimatedMinutes: 25,
      difficulty: 'Medium',
      description: 'A modular geometric pattern.',
      steps: const [],
      status: SubmissionStatus.rejected,
      updatedLabel: 'Reviewed June 2',
      comments: const [
        'Step images need stronger lighting before resubmission.',
      ],
    ),
  ];

  final List<TutorialData> tutorials = [
    TutorialData(
      id: 'classic-crane',
      title: 'Classic Crane',
      image: artworkOne,
      difficulty: 'Easy',
      duration: '15 min',
      rating: 4.8,
    ),
    TutorialData(
      id: 'lotus-flower',
      title: 'Lotus Flower',
      image: artworkTwo,
      difficulty: 'Medium',
      duration: '25 min',
      rating: 4.9,
    ),
    TutorialData(
      id: 'geometric-star',
      title: 'Geometric Star',
      image: artworkThree,
      difficulty: 'Easy',
      duration: '20 min',
      rating: 4.7,
    ),
    TutorialData(
      id: 'dragon',
      title: 'Dragon',
      image: artworkFour,
      difficulty: 'Hard',
      duration: '45 min',
      rating: 4.9,
    ),
    TutorialData(
      id: 'rose',
      title: 'Rose',
      image: artworkFive,
      difficulty: 'Medium',
      duration: '30 min',
      rating: 4.6,
    ),
    TutorialData(
      id: 'kusudama-ball',
      title: 'Kusudama Ball',
      image: artworkSix,
      difficulty: 'Hard',
      duration: '60 min',
      rating: 4.8,
    ),
  ];

  final Set<String> savedTutorialIds = {'classic-crane', 'lotus-flower'};
  final Set<String> followerUserIds = {};
  final Set<String> followingUserIds = {};

  final List<FoldHistoryData> foldHistory = [];

  List<TutorialData> get savedTutorials => tutorials
      .where((tutorial) => savedTutorialIds.contains(tutorial.id))
      .toList();

  List<UserProfileData> get followerUsers => followerUserIds
      .map(userById)
      .where((user) => user.id != currentUser.id)
      .toList();

  List<UserProfileData> get followingUsers => followingUserIds
      .map(userById)
      .where((user) => user.id != currentUser.id)
      .toList();

  UserProfileData userById(String id) {
    if (id == currentUser.id) return currentUser;
    return users.firstWhere((user) => user.id == id);
  }

  void upsertUsersFromSearch(List<UserSearchDto> values) {
    for (final value in values) {
      if (value.id.isEmpty || value.id == currentUser.id) continue;
      final user = UserProfileData(
        id: value.id,
        name: value.name,
        handle: value.handle.isEmpty ? value.username : value.handle,
        bio: value.bio,
        avatarUrl: value.avatarUrl,
        followers: value.followers,
        following: value.following,
        isFollowing: value.isFollowing,
      );
      final index = users.indexWhere((item) => item.id == user.id);
      if (index >= 0) {
        final existing = users[index];
        users[index] = existing.copyWith(
          name: user.name,
          handle: user.handle,
          bio: user.bio,
          avatarUrl: user.avatarUrl,
          followers: user.followers,
          following: user.following,
          isFollowing: user.isFollowing,
        );
      } else {
        users.add(user);
      }
    }
    notifyListeners();
  }

  void replaceFollowerUsers(List<UserProfileDto> values) {
    followerUserIds
      ..clear()
      ..addAll(values.map((user) => user.id).where((id) => id.isNotEmpty));
    _upsertProfileDtos(values, isFollower: true);
    currentUser = currentUser.copyWith(followers: values.length);
    notifyListeners();
  }

  void replaceFollowingUsers(List<UserProfileDto> values) {
    followingUserIds
      ..clear()
      ..addAll(values.map((user) => user.id).where((id) => id.isNotEmpty));
    _upsertProfileDtos(values, isFollowing: true);
    currentUser = currentUser.copyWith(following: values.length);
    notifyListeners();
  }

  void upsertUserFromProfile(UserProfileDto value) {
    _upsertProfileDtos([value]);
    notifyListeners();
  }

  void applyFollowResult(UserProfileDto value, {required bool wasFollowing}) {
    _upsertProfileDtos([value]);
    if (wasFollowing != value.isFollowing) {
      if (value.isFollowing) {
        followingUserIds.add(value.id);
      } else {
        followingUserIds.remove(value.id);
      }
      currentUser = currentUser.copyWith(
        following: currentUser.following + (value.isFollowing ? 1 : -1),
      );
    }
    notifyListeners();
  }

  void _upsertProfileDtos(
    List<UserProfileDto> values, {
    bool? isFollower,
    bool? isFollowing,
  }) {
    for (final value in values) {
      if (value.id.isEmpty || value.id == currentUser.id) continue;
      final index = users.indexWhere((item) => item.id == value.id);
      if (index >= 0) {
        final existing = users[index];
        users[index] = existing.copyWith(
          name: value.displayName.isEmpty ? value.username : value.displayName,
          handle: value.handle.isEmpty ? value.username : value.handle,
          bio: value.bio,
          avatarUrl: value.avatarUrl,
          followers: value.followers,
          following: value.following,
          isFollower: isFollower ?? existing.isFollower,
          isFollowing: isFollowing ?? value.isFollowing,
        );
      } else {
        users.add(
          UserProfileData(
            id: value.id,
            name: value.displayName.isEmpty
                ? value.username
                : value.displayName,
            handle: value.handle.isEmpty ? value.username : value.handle,
            bio: value.bio,
            avatarUrl: value.avatarUrl,
            followers: value.followers,
            following: value.following,
            isFollower: isFollower ?? false,
            isFollowing: isFollowing ?? value.isFollowing,
          ),
        );
      }
    }
  }

  void addPost({required String caption, required List<XFile> images}) {
    posts.insert(
      0,
      FeedPostData(
        id: 'post-${DateTime.now().microsecondsSinceEpoch}',
        authorId: currentUser.id,
        authorName: currentUser.name,
        caption: caption,
        localImages: List.unmodifiable(images),
        likes: 0,
        comments: 0,
        createdLabel: 'Just now',
      ),
    );
    notifyListeners();
  }

  void replaceFeedPosts(List<NewsfeedPostDto> values) {
    posts
      ..clear()
      ..addAll(values.map(_feedPostFromDto));
    notifyListeners();
  }

  void upsertPostFromServer(NewsfeedPostDto value) {
    final post = _feedPostFromDto(value);
    final index = posts.indexWhere((item) => item.id == post.id);
    if (index >= 0) {
      posts[index] = post;
    } else {
      posts.insert(0, post);
    }
    notifyListeners();
  }

  void replacePostComments(String postId, List<NewsfeedCommentDto> values) {
    final post = posts.firstWhere((item) => item.id == postId);
    post.commentItems
      ..clear()
      ..addAll(values.map(_feedCommentFromDto));
    post.comments = values.length;
    notifyListeners();
  }

  void appendPostComments(String postId, List<NewsfeedCommentDto> values) {
    final post = posts.firstWhere((item) => item.id == postId);
    for (final value in values) {
      final comment = _feedCommentFromDto(value);
      final index = post.commentItems.indexWhere(
        (item) => item.id == comment.id,
      );
      if (index >= 0) {
        post.commentItems[index] = comment;
      } else {
        post.commentItems.add(comment);
      }
    }
    post.comments = post.commentItems.length;
    notifyListeners();
  }

  void addPostCommentFromServer(String postId, NewsfeedCommentDto value) {
    final post = posts.firstWhere((item) => item.id == postId);
    post.commentItems.add(_feedCommentFromDto(value));
    post.comments++;
    notifyListeners();
  }

  void upsertPostCommentFromServer(String postId, NewsfeedCommentDto value) {
    final post = posts.firstWhere((item) => item.id == postId);
    final comment = _feedCommentFromDto(value);
    final index = post.commentItems.indexWhere((item) => item.id == comment.id);
    if (index >= 0) {
      post.commentItems[index] = comment;
    } else {
      post.commentItems.add(comment);
      post.comments++;
    }
    notifyListeners();
  }

  FeedPostData _feedPostFromDto(NewsfeedPostDto value) {
    return FeedPostData(
      id: value.id,
      authorId: value.authorId,
      authorName: value.authorName,
      authorAvatarUrl: value.authorAvatarUrl,
      caption: value.caption,
      status: value.status,
      rejectionReason: value.rejectionReason ?? '',
      networkImages: value.mediaUrls,
      tutorial: value.tutorialTitle,
      tutorialId: value.tutorialId,
      likes: value.likes,
      comments: value.comments,
      likedByMe: value.likedByMe,
      createdAt: value.createdAt,
    );
  }

  FeedCommentData _feedCommentFromDto(NewsfeedCommentDto value) {
    return FeedCommentData(
      id: value.id,
      postId: value.postId,
      parentId: value.parentId,
      replyToUserId: value.replyToUserId,
      authorId: value.authorId,
      authorName: value.authorName,
      authorAvatarUrl: value.authorAvatarUrl,
      message: value.content,
      likeCount: value.likeCount,
      likedByCurrentUser: value.likedByCurrentUser,
      replyCount: value.replyCount,
      deleted: value.deleted,
      edited: value.edited,
      canEdit: value.canEdit,
      canDelete: value.canDelete,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  void addInstruction(InstructionSubmissionData submission) {
    submissions.insert(0, submission);
    notifyListeners();
  }

  void replaceInstructionSubmissionsFromTutorials(
    List<TutorialDetailModel> values,
  ) {
    submissions
      ..clear()
      ..addAll(
        values.map(
          (value) => InstructionSubmissionData(
            id: value.summary.id,
            title: value.summary.title,
            resources: value.materials.join(', '),
            estimatedMinutes: value.summary.estimatedMinutes,
            difficulty: value.summary.difficulty,
            description: value.summary.description,
            steps: const [],
            status: _submissionStatusFromServer(value.status),
            updatedLabel: 'Synced from server',
            reviewNote: value.rejectionReason,
          ),
        ),
      );
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String handle,
    required String bio,
    XFile? avatar,
    String? avatarUrl,
  }) {
    currentUser = currentUser.copyWith(
      name: name,
      handle: handle,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    if (avatar != null) currentAvatar = avatar;
    if (avatarUrl != null && avatarUrl.isNotEmpty) currentAvatar = null;
    for (final post in posts.where((post) => post.authorId == currentUser.id)) {
      post.authorName = name;
    }
    notifyListeners();
  }

  void applyCurrentUserProfile(UserProfileDto profile) {
    currentUser = currentUser.copyWith(
      id: profile.id,
      name: profile.displayName.isEmpty
          ? profile.username
          : profile.displayName,
      handle: profile.handle,
      bio: profile.bio,
      avatarUrl: profile.avatarUrl,
      followers: profile.followers,
      following: profile.following,
    );
    if (profile.avatarUrl.isNotEmpty) currentAvatar = null;
    for (final post in posts.where((post) => post.authorId == currentUser.id)) {
      post.authorName = currentUser.name;
    }
    notifyListeners();
  }

  void toggleFollow(String userId) {
    final index = users.indexWhere((user) => user.id == userId);
    if (index < 0) return;
    final user = users[index];
    final nextFollowing = !user.isFollowing;
    users[index] = user.copyWith(
      isFollowing: nextFollowing,
      followers: user.followers + (nextFollowing ? 1 : -1),
    );
    if (nextFollowing) {
      followingUserIds.add(userId);
    } else {
      followingUserIds.remove(userId);
    }
    currentUser = currentUser.copyWith(
      following: currentUser.following + (nextFollowing ? 1 : -1),
    );
    notifyListeners();
  }

  void toggleSavedTutorial(String tutorialId) {
    if (!savedTutorialIds.add(tutorialId)) {
      savedTutorialIds.remove(tutorialId);
    }
    notifyListeners();
  }

  void replaceLibraryTutorials(List<LibraryTutorial> values) {
    tutorials
      ..clear()
      ..addAll(
        values.map(
          (value) => TutorialData(
            id: value.id,
            title: value.title,
            image: value.thumbnailUrl,
            difficulty: value.difficulty,
            duration: value.duration,
            rating: value.rating,
          ),
        ),
      );
    notifyListeners();
  }

  void addCompletedFold({
    required String title,
    required String image,
    required String difficulty,
    required String duration,
  }) {
    foldHistory.insert(
      0,
      FoldHistoryData(
        id: 'fold-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        image: image,
        completedDate: DateFormat('MMM d, yyyy').format(DateTime.now()),
        difficulty: difficulty,
        duration: duration,
      ),
    );
    notifyListeners();
  }

  void reactToInstruction(String id) {
    final item = submissions.firstWhere((submission) => submission.id == id);
    if (item.status != SubmissionStatus.approved) return;
    item.reactions++;
    notifyListeners();
  }

  void addInstructionComment(String id, String comment) {
    final item = submissions.firstWhere((submission) => submission.id == id);
    final value = comment.trim();
    if (item.status != SubmissionStatus.approved || value.isEmpty) return;
    item.comments.add(value);
    notifyListeners();
  }

  void addPostComment(String postId, String comment) {
    final value = comment.trim();
    if (value.isEmpty) return;
    final post = posts.firstWhere((item) => item.id == postId);
    post.commentItems.add(
      FeedCommentData(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        authorId: currentUser.id,
        authorName: currentUser.name,
        message: value,
        createdLabel: 'Just now',
      ),
    );
    post.comments++;
    notifyListeners();
  }
}

String _relativeLabel(DateTime? value) {
  if (value == null) return 'Just now';
  final diff = DateTime.now().difference(value.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${value.day}/${value.month}/${value.year}';
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    required AppState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static AppState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
      assert(scope != null, 'AppStateScope not found in widget tree');
      return scope!.notifier!;
    }

    final element = context
        .getElementForInheritedWidgetOfExactType<AppStateScope>();
    final scope = element?.widget as AppStateScope?;
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}
