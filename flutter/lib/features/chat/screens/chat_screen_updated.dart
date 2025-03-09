import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/message_formatter.dart';
import '../../prescription/presentation/widgets/expandable_panel.dart';
import '../models/chat.dart';
import '../providers/message_providers.dart';
import 'dart:io';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/message_migration_service.dart';
import 'image_viewer_screen.dart';
import '../widgets/chat_image_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_actions.dart';
import '../utils/message_utils.dart';

// این فایل شامل تغییرات مورد نیاز برای استفاده از ویجت‌های جدید است
// برای استفاده از این تغییرات، کد زیر را در فایل chat_screen.dart جایگزین کنید

/*
// در بخش import‌ها، موارد زیر را اضافه کنید:
import '../widgets/message_bubble.dart';
import '../widgets/message_actions.dart';
import '../utils/message_utils.dart';

// در بخش ListView.builder، کد زیر را جایگزین کنید:
return RefreshIndicator(
  onRefresh: () => ref
      .read(messageListProvider(widget.chat.id).notifier)
      .loadMessages(),
  child: ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.all(8),
    itemCount: messages.length,
    key: PageStorageKey<String>('chat_list_${widget.chat.id}'),
    itemBuilder: (context, index) {
      final message = messages[index];
      final isUser = message.role == 'user';
      final isSystem = message.role == 'system';
      final isImage = message.isImage;
      final isLoading = message.isLoading;
      final isError = message.isError;
      final isThinking = message.isThinking;

      // استفاده از ویجت MessageBubble به جای کد قبلی
      return MessageBubble(
        message: message,
        isUser: isUser,
        isError: isError,
        isLoading: isLoading,
        isThinking: isThinking,
        isImage: isImage,
        messageContent: isError
            ? _buildErrorMessageContent(message.content)
            : _buildMessageContent(message.content, isImage, isLoading, isThinking, isUser: isUser),
        onRetry: isError ? () {
          // Retry sending the failed message
          final originalContent = message.content
              .split('\n')
              .first
              .replaceFirst('خطا در ارسال پیام: ', '');
          if (originalContent.isNotEmpty) {
            ref
                .read(messageListProvider(widget.chat.id).notifier)
                .sendMessage(originalContent);
          }
        } : null,
      );
    },
  ),
);
*/ 