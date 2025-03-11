import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/message.dart';
import 'message_bubble.dart';
import '../../../core/utils/message_formatter.dart';

/// Widget for displaying a list of messages in a chat
class MessageList extends StatelessWidget {
  final List<Message> messages;
  final String chatId;
  final ScrollController scrollController;

  const MessageList({
    Key? key,
    required this.messages,
    required this.chatId,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.role == 'user';
        final isError = message.isError;
        final isLoading = message.isLoading;
        final isThinking = message.isThinking;
        final isImage = message.isImage;

        return MessageBubble(
          message: message,
          isUser: isUser,
          isError: isError,
          isLoading: isLoading,
          isThinking: isThinking,
          isImage: isImage,
          messageContent: Text(message.content),
        );
      },
    );
  }
}
