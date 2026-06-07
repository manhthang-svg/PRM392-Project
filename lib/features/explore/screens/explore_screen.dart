import 'package:flutter/material.dart';
import 'package:origami/app/theme.dart';

/// Màn hình Explore placeholder
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text('Explore - Coming Soon'),
      ),
    );
  }
}
