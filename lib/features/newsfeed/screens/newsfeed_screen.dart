import 'package:flutter/material.dart';
import 'package:origami/app/theme.dart';

/// Màn hình Newsfeed placeholder
class NewsfeedScreen extends StatelessWidget {
  const NewsfeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Origami Feed')),
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text('Newsfeed - Coming Soon'),
      ),
    );
  }
}
