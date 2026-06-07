import 'package:flutter/material.dart';
import 'package:origami/app/theme.dart';

/// Màn hình Chat placeholder
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text('Chat - Coming Soon'),
      ),
    );
  }
}
