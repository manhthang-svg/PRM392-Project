import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

class MessagesHomeTab extends StatefulWidget {
  const MessagesHomeTab({super.key});

  @override
  State<MessagesHomeTab> createState() => _MessagesHomeTabState();
}

class _MessagesHomeTabState extends State<MessagesHomeTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final conversations = state.conversations.where((conversation) {
      final user = state.userById(conversation.userId);
      return user.name.toLowerCase().contains(query) ||
          conversation.lastMessage.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppPageTitle('Messages', size: 25),
                const SizedBox(height: 15),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: conversations.isEmpty
                ? const Center(
                    child: Text(
                      'No conversations found.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  )
                : ListView.separated(
                    key: const PageStorageKey('messages'),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) => const Divider(indent: 88),
                    itemBuilder: (_, index) {
                      final conversation = conversations[index];
                      final user = state.userById(conversation.userId);
                      return ListTile(
                        onTap: () async {
                          conversation.unread = 0;
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.conversationDetail,
                            arguments: user.id,
                          );
                          if (mounted) setState(() {});
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Stack(
                          children: [
                            const UserAvatar(size: 56),
                            if (user.online)
                              Positioned(
                                right: 1,
                                bottom: 1,
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF45B76B),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              conversation.timestamp,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (conversation.unread > 0)
                              Container(
                                width: 21,
                                height: 21,
                                margin: const EdgeInsets.only(left: 8),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${conversation.unread}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ConversationDetailScreen extends StatefulWidget {
  const ConversationDetailScreen({required this.userId, super.key});

  final String userId;

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(AppState state) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    state.sendMessage(widget.userId, text);
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final user = state.userById(widget.userId);
    final conversation = state.conversationByUserId(widget.userId);
    conversation.unread = 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.publicProfile,
            arguments: user.id,
          ),
          child: Row(
            children: [
              const UserAvatar(size: 38),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.online ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: user.online
                          ? const Color(0xFF45A467)
                          : AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => showAppMessage(context, 'Voice call started'),
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            onPressed: () => showAppMessage(context, 'Video call started'),
            icon: const Icon(Icons.videocam_outlined),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        itemCount: conversation.messages.length,
        itemBuilder: (_, index) {
          final message = conversation.messages[index];
          return _MessageBubble(message: message);
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => showAppMessage(
                  context,
                  'Choose a photo, tutorial, or achievement to share',
                ),
                icon: const Icon(Icons.add_circle_outline),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _send(state),
                  decoration: const InputDecoration(
                    hintText: 'Write a message...',
                    isDense: true,
                    suffixIcon: Icon(Icons.sentiment_satisfied_alt_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              IconButton.filled(
                onPressed: () => _send(state),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessageData message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.sentByMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .72,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: message.sentByMe ? AppColors.primaryDark : AppColors.input,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(message.sentByMe ? 17 : 4),
            bottomRight: Radius.circular(message.sentByMe ? 4 : 17),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.sentByMe ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                color: message.sentByMe ? Colors.white70 : AppColors.mutedText,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
