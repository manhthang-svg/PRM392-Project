import 'package:flutter/material.dart';
import 'package:origami/app/theme.dart';

/// Màn hình Profile placeholder
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text('Profile - Coming Soon'),
      ),
    );
  }
}
