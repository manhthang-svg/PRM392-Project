import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/library/library_api.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class CreatorHubTab extends StatelessWidget {
  const CreatorHubTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final ownPosts = state.posts
        .where((post) => post.authorId == state.currentUser.id)
        .toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('create'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          const AppPageTitle('Creator Studio', size: 31),
          const SizedBox(height: 7),
          const Text(
            'Post your work or build a complete origami instruction.',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 25),
          _CreateActionCard(
            icon: Icons.dynamic_feed_outlined,
            title: 'Post to Newsfeed',
            subtitle: 'Write a caption and upload one or more photos',
            color: AppColors.primaryDark,
            onTap: () => Navigator.pushNamed(context, AppRoutes.createPost),
          ),
          const SizedBox(height: 12),
          _CreateActionCard(
            icon: Icons.menu_book_outlined,
            title: 'Create Origami Instruction',
            subtitle: 'Add resources, difficulty, duration, and step photos',
            color: AppColors.ink,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.createInstruction),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: Text('Recent Activity', style: serifTitle(22))),
              Text(
                '${ownPosts.length + state.submissions.length} items',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...ownPosts.map(
            (post) => _ActivityTile(
              icon: Icons.dynamic_feed_outlined,
              title: post.caption,
              subtitle: 'Newsfeed post · ${post.createdLabel}',
              badge: 'Posted',
              badgeColors: _statusColors('Posted'),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.postActivityDetail,
                arguments: post.id,
              ),
            ),
          ),
          ...state.submissions.map(
            (submission) => _ActivityTile(
              icon: Icons.description_outlined,
              title: submission.title,
              subtitle: submission.status == SubmissionStatus.approved
                  ? 'Instruction · ${submission.updatedLabel} · ${submission.reactions} reacts'
                  : 'Instruction · ${submission.updatedLabel}',
              badge: submission.status.label,
              badgeColors: _statusColors(submission.status.label),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.instructionSubmissionDetail,
                arguments: submission.id,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateActionCard extends StatelessWidget {
  const _CreateActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final (Color, Color) badgeColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColors.$1,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColors.$2,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

(Color, Color) _statusColors(String status) {
  return switch (status) {
    'Approved' ||
    'Posted' => (const Color(0xFFDFF4E8), const Color(0xFF2C7A50)),
    'Processing' => (const Color(0xFFFFF1C7), const Color(0xFF956600)),
    'Rejected' => (const Color(0xFFFDE0E0), const Color(0xFFB64A4A)),
    _ => (AppColors.muted, AppColors.mutedText),
  };
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  bool _picking = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      setState(() => _images.addAll(images));
    } catch (_) {
      if (mounted) showAppMessage(context, 'Could not open the photo library');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _publish() {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      showAppMessage(context, 'Please write a caption');
      return;
    }
    if (_images.isEmpty) {
      showAppMessage(context, 'Please upload at least one photo');
      return;
    }
    AppStateScope.of(
      context,
      listen: false,
    ).addPost(caption: caption, images: _images);
    showAppMessage(context, 'Your post is now on the Newsfeed');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Newsfeed Post', style: serifTitle(23)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Caption', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _captionController,
            minLines: 4,
            maxLines: 7,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Tell the community about your origami...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Photos',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${_images.length} selected',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _UploadArea(
            title: 'Upload multiple photos',
            subtitle: 'Choose one or more images from your library',
            loading: _picking,
            onTap: _pickImages,
          ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) => _RemovableImage(
                  image: _images[index],
                  onRemove: () => setState(() => _images.removeAt(index)),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: PrimaryButton(
            label: 'Publish Post',
            icon: Icons.send_outlined,
            onPressed: _publish,
          ),
        ),
      ),
    );
  }
}

class CreateInstructionScreen extends StatefulWidget {
  const CreateInstructionScreen({super.key});

  @override
  State<CreateInstructionScreen> createState() =>
      _CreateInstructionScreenState();
}

class _CreateInstructionScreenState extends State<CreateInstructionScreen> {
  final _titleController = TextEditingController();
  final _resourcesController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _stepImages = [];
  final List<TextEditingController> _stepDescriptions = [];
  String _difficulty = 'Easy';
  String _category = 'Animals';
  bool _picking = false;
  bool _saving = false;
  String? _savingLabel;

  @override
  void dispose() {
    _titleController.dispose();
    _resourcesController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    for (final controller in _stepDescriptions) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickSteps() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      setState(() {
        _stepImages.addAll(images);
        _stepDescriptions.addAll(
          List.generate(images.length, (_) => TextEditingController()),
        );
      });
    } catch (_) {
      if (mounted) showAppMessage(context, 'Could not open the photo library');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _removeStep(int index) {
    setState(() {
      _stepImages.removeAt(index);
      _stepDescriptions.removeAt(index).dispose();
    });
  }

  Future<void> _save({required bool draft}) async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppMessage(context, 'Please enter a tutorial title');
      return;
    }

    final duration = int.tryParse(_durationController.text.trim());
    if (!draft &&
        (_resourcesController.text.trim().isEmpty ||
            duration == null ||
            duration <= 0 ||
            _descriptionController.text.trim().isEmpty ||
            _stepImages.isEmpty)) {
      showAppMessage(
        context,
        'Complete resources, duration, description, and at least one step',
      );
      return;
    }

    final localSteps = <InstructionStepData>[
      for (var index = 0; index < _stepImages.length; index++)
        InstructionStepData(
          image: _stepImages[index],
          description: _stepDescriptions[index].text.trim().isEmpty
              ? 'Step ${index + 1}'
              : _stepDescriptions[index].text.trim(),
        ),
    ];

    setState(() {
      _saving = true;
      _savingLabel = _stepImages.isEmpty
          ? 'Saving tutorial...'
          : 'Uploading images...';
    });
    try {
      final api = LibraryApi(AuthScope.of(context, listen: false).apiClient);
      final uploadedUrls = <String>[];
      for (var index = 0; index < _stepImages.length; index++) {
        if (mounted) {
          setState(() {
            _savingLabel =
                'Uploading image ${index + 1}/${_stepImages.length}...';
          });
        }
        final uploaded = await api.uploadImage(_stepImages[index]);
        uploadedUrls.add(uploaded.secureUrl);
      }

      if (mounted) setState(() => _savingLabel = 'Saving tutorial...');
      final detail = await api.createTutorial(
        CreateTutorialPayload(
          title: title,
          description: _descriptionController.text.trim(),
          categorySlug: tutorialCategorySlug(_category),
          difficulty: _difficulty,
          estimatedMinutes: duration ?? 0,
          thumbnailUrl: uploadedUrls.isEmpty ? '' : uploadedUrls.first,
          draft: draft,
          materials: _resourcesController.text
              .split(RegExp(r'[,\n]'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
          steps: [
            for (var index = 0; index < uploadedUrls.length; index++)
              CreateTutorialStepPayload(
                description: _stepDescriptions[index].text.trim().isEmpty
                    ? 'Step ${index + 1}'
                    : _stepDescriptions[index].text.trim(),
                mediaUrl: uploadedUrls[index],
              ),
          ],
        ),
      );
      if (!mounted) return;
      AppStateScope.of(context, listen: false).addInstruction(
        InstructionSubmissionData(
          id: detail.summary.id,
          title: title,
          resources: _resourcesController.text.trim(),
          estimatedMinutes: duration ?? 0,
          difficulty: _difficulty,
          description: _descriptionController.text.trim(),
          steps: localSteps,
          status: draft ? SubmissionStatus.draft : SubmissionStatus.processing,
          updatedLabel: draft ? 'Saved just now' : 'Sent just now',
        ),
      );
      showAppMessage(
        context,
        draft ? 'Instruction saved as draft' : 'Instruction sent for review',
      );
      Navigator.pop(context);
    } on LibraryFailure catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _savingLabel = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Instruction', style: serifTitle(23)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _LabeledField(
            label: 'Tutorial title',
            controller: _titleController,
            hint: 'Example: Traditional Paper Crane',
          ),
          _LabeledField(
            label: 'Resources needed',
            controller: _resourcesController,
            hint: 'Paper size, tools, number of sheets...',
            maxLines: 3,
          ),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: ['Animals', 'Birds', 'Flowers', 'Geometric', 'Modular']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _category = value ?? 'Animals'),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Estimated time',
                  controller: _durationController,
                  hint: 'Minutes',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Difficulty',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      items: ['Easy', 'Medium', 'Hard']
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _difficulty = value ?? 'Easy'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LabeledField(
            label: 'Description',
            controller: _descriptionController,
            hint: 'Describe the finished model and key techniques...',
            maxLines: 5,
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Step images',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${_stepImages.length} steps',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _UploadArea(
            title: 'Upload step photos',
            subtitle: _savingLabel ?? 'Select images in chronological order',
            loading: _picking || _saving,
            onTap: _saving ? () {} : _pickSteps,
          ),
          const SizedBox(height: 14),
          ...List.generate(
            _stepImages.length,
            (index) => _StepEditor(
              index: index,
              image: _stepImages[index],
              controller: _stepDescriptions[index],
              onRemove: () => _removeStep(index),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlineAppButton(
                  label: 'Save Draft',
                  icon: Icons.save_outlined,
                  onPressed: _saving ? null : () => _save(draft: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: _saving ? 'Working...' : 'Send',
                  icon: Icons.send_outlined,
                  onPressed: _saving ? null : () => _save(draft: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

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
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  const _UploadArea({
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.input,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primaryDark,
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemovableImage extends StatelessWidget {
  const _RemovableImage({required this.image, required this.onRemove});

  final XFile image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PickedImageView(file: image, borderRadius: BorderRadius.circular(14)),
          Positioned(
            top: 5,
            right: 5,
            child: IconButton.filled(
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                minimumSize: const Size(30, 30),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.close, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepEditor extends StatelessWidget {
  const _StepEditor({
    required this.index,
    required this.image,
    required this.controller,
    required this.onRemove,
  });

  final int index;
  final XFile image;
  final TextEditingController controller;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: PickedImageView(
              file: image,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Step ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ],
                ),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe this fold...',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InstructionSubmissionDetailScreen extends StatefulWidget {
  const InstructionSubmissionDetailScreen({
    required this.submissionId,
    super.key,
  });

  final String submissionId;

  @override
  State<InstructionSubmissionDetailScreen> createState() =>
      _InstructionSubmissionDetailScreenState();
}

class _InstructionSubmissionDetailScreenState
    extends State<InstructionSubmissionDetailScreen> {
  final _commentController = TextEditingController();
  bool _reacted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment(AppState state) {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;
    state.addInstructionComment(widget.submissionId, comment);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final item = state.submissions.firstWhere(
      (submission) => submission.id == widget.submissionId,
    );
    final colors = _statusColors(item.status.label);
    final isApproved = item.status == SubmissionStatus.approved;

    return Scaffold(
      appBar: AppBar(
        title: Text('Instruction Details', style: serifTitle(23)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: Text(item.title, style: serifTitle(28))),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.$1,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    color: colors.$2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            item.updatedLabel,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
          const SizedBox(height: 22),
          _DetailInfo(
            icon: Icons.inventory_2_outlined,
            label: 'Resources',
            value: item.resources.isEmpty ? 'Not added yet' : item.resources,
          ),
          _DetailInfo(
            icon: Icons.schedule,
            label: 'Estimated time',
            value: '${item.estimatedMinutes} minutes',
          ),
          _DetailInfo(
            icon: Icons.signal_cellular_alt,
            label: 'Difficulty',
            value: item.difficulty,
          ),
          const SizedBox(height: 14),
          Text('Description', style: serifTitle(19)),
          const SizedBox(height: 7),
          Text(
            item.description.isEmpty ? 'No description yet.' : item.description,
            style: const TextStyle(color: AppColors.mutedText),
          ),
          if (item.steps.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Steps', style: serifTitle(19)),
            const SizedBox(height: 10),
            ...item.steps.asMap().entries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: PickedImageView(
                        file: entry.value.image,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step ${entry.key + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.value.description,
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
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (!isApproved)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.input,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reactions and comments will be available after this instruction is approved.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reacted
                        ? null
                        : () {
                            state.reactToInstruction(item.id);
                            setState(() => _reacted = true);
                          },
                    icon: Icon(
                      _reacted ? Icons.favorite : Icons.favorite_border,
                    ),
                    label: Text('${item.reactions} reacts'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text('${item.comments.length} comments'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Comments', style: serifTitle(19)),
            const SizedBox(height: 12),
            if (item.comments.isEmpty)
              const Text(
                'No comments yet.',
                style: TextStyle(color: AppColors.mutedText),
              )
            else
              ...item.comments.map(
                (comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UserAvatar(size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.input,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Text(comment),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    onSubmitted: (_) => _sendComment(state),
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _sendComment(state),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailInfo extends StatelessWidget {
  const _DetailInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryDark, size: 21),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostActivityDetailScreen extends StatelessWidget {
  const PostActivityDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final post = state.posts.firstWhere((item) => item.id == postId);
    final imageCount = post.localImages.length + post.networkImages.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Newsfeed Post', style: serifTitle(23)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const UserAvatar(size: 44),
              const SizedBox(width: 11),
              Expanded(
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
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(post.caption, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 15),
          SizedBox(
            height: 300,
            child: PageView.builder(
              itemCount: imageCount,
              itemBuilder: (_, index) {
                if (index < post.localImages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PickedImageView(
                      file: post.localImages[index],
                      borderRadius: BorderRadius.circular(18),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppNetworkImage(
                    url: post.networkImages[index - post.localImages.length],
                    borderRadius: BorderRadius.circular(18),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$imageCount photo${imageCount == 1 ? '' : 's'} · ${post.likes} likes · ${post.comments} comments',
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
