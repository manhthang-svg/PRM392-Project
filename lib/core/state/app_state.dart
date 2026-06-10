import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

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

class UserProfileData {
  const UserProfileData({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.followers,
    required this.following,
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
  final bool isFollowing;
  final bool? _isFollower;
  final bool online;
  final List<String> works;

  // Nullable backing storage keeps existing web objects valid after hot reload
  // when this field did not exist yet.
  bool get isFollower => _isFollower ?? false;

  UserProfileData copyWith({
    String? name,
    String? handle,
    String? bio,
    int? followers,
    int? following,
    bool? isFollowing,
    bool? isFollower,
    bool? online,
    List<String>? works,
  }) {
    return UserProfileData(
      id: id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
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
    required this.createdLabel,
    this.networkImages = const [],
    this.localImages = const [],
    this.tutorial,
    this.likes = 0,
    this.comments = 0,
    List<FeedCommentData> commentItems = const [],
  }) : _commentItems = List.of(commentItems);

  final String id;
  final String authorId;
  String authorName;
  final String caption;
  final String createdLabel;
  final List<String> networkImages;
  final List<XFile> localImages;
  final String? tutorial;
  int likes;
  int comments;
  List<FeedCommentData>? _commentItems;

  // Existing objects created before this field was added receive null on hot
  // reload, so initialize them lazily when comments are first opened.
  List<FeedCommentData> get commentItems =>
      _commentItems ??= <FeedCommentData>[];
}

class FeedCommentData {
  const FeedCommentData({
    required this.authorId,
    required this.authorName,
    required this.message,
    required this.createdLabel,
  });

  final String authorId;
  final String authorName;
  final String message;
  final String createdLabel;
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

class ChatMessageData {
  const ChatMessageData({
    required this.text,
    required this.sentByMe,
    required this.time,
  });

  final String text;
  final bool sentByMe;
  final String time;
}

class ConversationData {
  ConversationData({
    required this.userId,
    required this.lastMessage,
    required this.timestamp,
    required this.unread,
    required List<ChatMessageData> messages,
  }) : messages = List.of(messages);

  final String userId;
  String lastMessage;
  String timestamp;
  int unread;
  final List<ChatMessageData> messages;
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

  final List<TutorialData> tutorials = const [
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

  final List<FoldHistoryData> foldHistory = [
    const FoldHistoryData(
      id: 'fold-1',
      title: 'Classic Red Crane',
      image: artworkOne,
      completedDate: 'May 15, 2026',
      difficulty: 'Easy',
      duration: '18 min',
    ),
    const FoldHistoryData(
      id: 'fold-2',
      title: 'Lotus Flower',
      image: artworkTwo,
      completedDate: 'May 20, 2026',
      difficulty: 'Medium',
      duration: '31 min',
    ),
    const FoldHistoryData(
      id: 'fold-3',
      title: 'Geometric Star',
      image: artworkThree,
      completedDate: 'May 25, 2026',
      difficulty: 'Hard',
      duration: '52 min',
    ),
  ];

  final List<ConversationData> conversations = [
    ConversationData(
      userId: 'sarah',
      lastMessage: 'Thanks for the tip on the crane!',
      timestamp: '2m ago',
      unread: 2,
      messages: const [
        ChatMessageData(
          text: 'Your crane tutorial was really helpful.',
          sentByMe: true,
          time: '10:21',
        ),
        ChatMessageData(
          text: 'I am glad it helped. Try keeping the center crease loose.',
          sentByMe: false,
          time: '10:23',
        ),
        ChatMessageData(
          text: 'Thanks for the tip on the crane!',
          sentByMe: false,
          time: '10:24',
        ),
      ],
    ),
    ConversationData(
      userId: 'yuki',
      lastMessage: 'Check out my new tutorial',
      timestamp: '1h ago',
      unread: 0,
      messages: const [
        ChatMessageData(
          text: 'I just published a modular star tutorial.',
          sentByMe: false,
          time: '09:15',
        ),
        ChatMessageData(
          text: 'Check out my new tutorial',
          sentByMe: false,
          time: '09:16',
        ),
      ],
    ),
    ConversationData(
      userId: 'alex',
      lastMessage: 'Would love to collaborate!',
      timestamp: '3h ago',
      unread: 1,
      messages: const [
        ChatMessageData(
          text: 'Would love to collaborate!',
          sentByMe: false,
          time: '07:40',
        ),
      ],
    ),
    ConversationData(
      userId: 'maria',
      lastMessage: 'Your dragon design is amazing',
      timestamp: '1d ago',
      unread: 0,
      messages: const [
        ChatMessageData(
          text: 'Your dragon design is amazing',
          sentByMe: false,
          time: 'Yesterday',
        ),
      ],
    ),
    ConversationData(
      userId: 'john',
      lastMessage: 'Can you help me with step 5?',
      timestamp: '2d ago',
      unread: 0,
      messages: const [
        ChatMessageData(
          text: 'Can you help me with step 5?',
          sentByMe: false,
          time: 'Mon',
        ),
      ],
    ),
  ];

  List<TutorialData> get savedTutorials => tutorials
      .where((tutorial) => savedTutorialIds.contains(tutorial.id))
      .toList();

  List<UserProfileData> get followerUsers =>
      users.where((user) => user.isFollower).toList();

  List<UserProfileData> get followingUsers =>
      users.where((user) => user.isFollowing).toList();

  UserProfileData userById(String id) {
    if (id == currentUser.id) return currentUser;
    return users.firstWhere((user) => user.id == id);
  }

  ConversationData conversationByUserId(String id) {
    final index = conversations.indexWhere(
      (conversation) => conversation.userId == id,
    );
    if (index >= 0) return conversations[index];
    final conversation = ConversationData(
      userId: id,
      lastMessage: 'Start a conversation',
      timestamp: '',
      unread: 0,
      messages: [],
    );
    conversations.add(conversation);
    return conversation;
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

  void addInstruction(InstructionSubmissionData submission) {
    submissions.insert(0, submission);
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String handle,
    required String bio,
    XFile? avatar,
  }) {
    currentUser = currentUser.copyWith(name: name, handle: handle, bio: bio);
    if (avatar != null) currentAvatar = avatar;
    for (final post in posts.where((post) => post.authorId == currentUser.id)) {
      post.authorName = name;
    }
    notifyListeners();
  }

  void toggleFollow(String userId) {
    final index = users.indexWhere((user) => user.id == userId);
    if (index < 0) return;
    final user = users[index];
    users[index] = user.copyWith(
      isFollowing: !user.isFollowing,
      followers: user.followers + (user.isFollowing ? -1 : 1),
    );
    currentUser = currentUser.copyWith(
      following: currentUser.following + (user.isFollowing ? -1 : 1),
    );
    notifyListeners();
  }

  void toggleSavedTutorial(String tutorialId) {
    if (!savedTutorialIds.add(tutorialId)) {
      savedTutorialIds.remove(tutorialId);
    }
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
        completedDate: 'June 10, 2026',
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
        authorId: currentUser.id,
        authorName: currentUser.name,
        message: value,
        createdLabel: 'Just now',
      ),
    );
    post.comments++;
    notifyListeners();
  }

  void sendMessage(String userId, String text) {
    final conversation = conversationByUserId(userId);
    conversation.messages.add(
      ChatMessageData(text: text, sentByMe: true, time: 'Now'),
    );
    conversation
      ..lastMessage = text
      ..timestamp = 'Now'
      ..unread = 0;
    notifyListeners();
  }
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
