import 'package:flutter/material.dart';
import 'package:origami/app/theme.dart';

/// Màn hình Contribution placeholder
class ContributionScreen extends StatelessWidget {
  const ContributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Studio')),
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text('Contribution - Coming Soon'),
      ),
    );
  }
}
