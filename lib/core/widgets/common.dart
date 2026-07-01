import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:origami/app/theme.dart';

class AppPageTitle extends StatelessWidget {
  const AppPageTitle(this.text, {super.key, this.size = 28});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(text, style: serifTitle(size));
}

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget constrain(Widget child) {
      if (width == null && height == null) return child;
      return SizedBox(width: width, height: height, child: child);
    }

    final image = Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return constrain(
          const ColoredBox(
            color: AppColors.accent,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryDark,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => constrain(
        const ColoredBox(
          color: AppColors.accent,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              color: AppColors.primaryDark,
              size: 42,
            ),
          ),
        ),
      ),
    );

    final constrainedImage = constrain(image);
    if (borderRadius == null) return constrainedImage;
    return ClipRRect(borderRadius: borderRadius!, child: constrainedImage);
  }
}

class PickedImageView extends StatefulWidget {
  const PickedImageView({
    required this.file,
    super.key,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final XFile file;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  State<PickedImageView> createState() => _PickedImageViewState();
}

class _PickedImageViewState extends State<PickedImageView> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.file.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant PickedImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _bytes = widget.file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
          );
        }
        if (snapshot.hasError) {
          return const ColoredBox(
            color: AppColors.accent,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          );
        }
        return const ColoredBox(
          color: AppColors.accent,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryDark,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );

    if (widget.borderRadius == null) return image;
    return ClipRRect(borderRadius: widget.borderRadius!, child: image);
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.size = 44,
    this.icon = Icons.person_outline,
    this.backgroundColor = AppColors.accent,
  });

  final double size;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primaryDark, size: size * .52),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
      label: Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class OutlineAppButton extends StatelessWidget {
  const OutlineAppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}

class OrigamiMark extends StatelessWidget {
  const OrigamiMark({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _OrigamiMarkPainter()),
    );
  }
}

class _OrigamiMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120;
    final points = <List<Offset>>[
      [
        const Offset(60, 10),
        const Offset(90, 35),
        const Offset(85, 70),
        const Offset(60, 90),
        const Offset(35, 70),
        const Offset(30, 35),
      ],
      [
        const Offset(60, 20),
        const Offset(80, 40),
        const Offset(75, 65),
        const Offset(60, 80),
        const Offset(45, 65),
        const Offset(40, 40),
      ],
      [
        const Offset(60, 30),
        const Offset(70, 45),
        const Offset(67, 60),
        const Offset(60, 70),
        const Offset(53, 60),
        const Offset(50, 45),
      ],
    ];
    final opacities = [.3, .55, 1.0];

    for (var index = 0; index < points.length; index++) {
      final path = Path()
        ..moveTo(
          points[index].first.dx * scale,
          points[index].first.dy * scale,
        );
      for (final point in points[index].skip(1)) {
        path.lineTo(point.dx * scale, point.dy * scale);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = AppColors.primary.withValues(alpha: opacities[index]),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
