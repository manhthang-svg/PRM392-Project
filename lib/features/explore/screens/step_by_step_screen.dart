import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/widgets/common.dart';

class StepByStepScreen extends StatefulWidget {
  const StepByStepScreen({super.key});

  @override
  State<StepByStepScreen> createState() => _StepByStepScreenState();
}

class _StepByStepScreenState extends State<StepByStepScreen> {
  int _step = 0;

  static const _instructions = [
    'Start with a square piece of paper, colored side down. Fold it in half diagonally to create a triangle.',
    'Fold the triangle in half again by bringing the left corner to the right corner.',
    'Open the top layer and squash fold it into a centered square shape.',
    'Turn the model over and repeat the squash fold on the other side.',
    'Fold both side edges toward the center crease, then fold the top triangle down.',
    'Unfold the last three creases and lift the bottom flap upward into a petal fold.',
    'Turn the model over and repeat the petal fold to form the bird base.',
    'Fold the lower left and right edges inward to make two narrow points.',
    'Inside-reverse fold one point upward to create the neck.',
    'Inside-reverse fold the other point upward to create the tail.',
    'Make a small reverse fold at the tip of the neck to shape the head.',
    'Gently pull the wings apart and flatten the body. Your crane is complete.',
  ];

  void _next() {
    if (_step < _instructions.length - 1) {
      setState(() => _step++);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.tutorialComplete);
    }
  }

  void _previous() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / _instructions.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'Step ${_step + 1} of ${_instructions.length}',
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppColors.accent,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 44),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: Container(
                            key: ValueKey(_step),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.all(34),
                            child: CustomPaint(
                              painter: _FoldDiagramPainter(step: _step),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .17),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step ${_step + 1}',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              _instructions[_step],
                              style: const TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _step == 0 ? null : _previous,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: _step == _instructions.length - 1
                          ? 'Complete'
                          : 'Next',
                      icon: _step == _instructions.length - 1
                          ? Icons.check
                          : Icons.chevron_right,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              OutlineAppButton(
                label: 'View Comments (23)',
                icon: Icons.chat_bubble_outline,
                onPressed: () => _showComments(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showComments(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(step: _step + 1),
    );
  }
}

class _FoldDiagramPainter extends CustomPainter {
  const _FoldDiagramPainter({required this.step});

  final int step;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final fold = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .34;

    final shape = Path();
    if (step < 2) {
      shape
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy + radius)
        ..lineTo(center.dx - radius, center.dy + radius)
        ..close();
    } else if (step < 7) {
      shape.addPolygon([
        Offset(center.dx, center.dy - radius),
        Offset(center.dx + radius, center.dy),
        Offset(center.dx, center.dy + radius),
        Offset(center.dx - radius, center.dy),
      ], true);
    } else {
      shape
        ..moveTo(center.dx - radius, center.dy + radius * .55)
        ..lineTo(center.dx - radius * .3, center.dy)
        ..lineTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius * .28, center.dy)
        ..lineTo(center.dx + radius, center.dy + radius * .55)
        ..lineTo(center.dx, center.dy + radius * .25)
        ..close();
    }
    canvas.drawPath(shape, fill);
    canvas.drawPath(shape, line);

    if (step.isEven) {
      canvas.drawLine(
        Offset(center.dx, center.dy - radius * .8),
        Offset(center.dx, center.dy + radius * .8),
        fold,
      );
      _drawArrow(
        canvas,
        Offset(center.dx - radius * .65, center.dy),
        Offset(center.dx - radius * .05, center.dy),
        fold,
      );
    } else {
      canvas.drawLine(
        Offset(center.dx - radius * .7, center.dy + radius * .45),
        Offset(center.dx + radius * .7, center.dy - radius * .45),
        fold,
      );
      _drawArrow(
        canvas,
        Offset(center.dx, center.dy + radius * .7),
        Offset(center.dx, center.dy - radius * .2),
        fold,
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 12.0;
    canvas.drawLine(
      to,
      Offset(
        to.dx - arrowSize * math.cos(angle - math.pi / 6),
        to.dy - arrowSize * math.sin(angle - math.pi / 6),
      ),
      paint,
    );
    canvas.drawLine(
      to,
      Offset(
        to.dx - arrowSize * math.cos(angle + math.pi / 6),
        to.dy - arrowSize * math.sin(angle + math.pi / 6),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FoldDiagramPainter oldDelegate) {
    return oldDelegate.step != step;
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.step});

  final int step;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _comments = <(String, String, String)>[
    ('Alex', 'Great explanation! I finally understood this fold.', '2h ago'),
    ('Maria', 'The direction arrow is very clear. Thanks!', '5h ago'),
    ('John', 'I had to loosen the previous fold before this worked.', '1d ago'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() => _comments.add(('You', value, 'now')));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 80,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Step ${widget.step} Comments',
                      style: serifTitle(20),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                itemCount: _comments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (_, index) {
                  final comment = _comments[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UserAvatar(size: 40),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  comment.$3,
                                  style: const TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              comment.$2,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask a question...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
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
    );
  }
}
