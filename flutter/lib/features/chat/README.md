# راهنمای استفاده از ویجت‌های جدید در صفحه چت

برای اضافه کردن قابلیت کپی و اشتراک‌گذاری پیام‌ها در صفحه چت، دو ویجت جدید ایجاد شده است:

1. `MessageActions`: این ویجت دکمه‌های کپی و اشتراک‌گذاری را نمایش می‌دهد.
2. `MessageBubble`: این ویجت حباب پیام را با دکمه‌های عملیات نمایش می‌دهد.

## نحوه استفاده

برای استفاده از این ویجت‌ها در فایل `chat_screen.dart`، باید تغییرات زیر را اعمال کنید:

1. ابتدا import‌های مورد نیاز را اضافه کنید:

```dart
import '../widgets/message_bubble.dart';
import '../widgets/message_actions.dart';
```

2. سپس در بخش نمایش پیام‌ها، به جای کد فعلی، از ویجت `MessageBubble` استفاده کنید:

```dart
MessageBubble(
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
)
```

با این تغییرات، کاربران می‌توانند پیام‌های دریافتی را کپی یا اشتراک‌گذاری کنند.

## نکات مهم

- دکمه‌های کپی و اشتراک‌گذاری فقط برای پیام‌های دریافتی (پیام‌های هوش مصنوعی) نمایش داده می‌شوند.
- دکمه تلاش مجدد فقط برای پیام‌های خطا نمایش داده می‌شود.
- محتوای پیام قبل از کپی یا اشتراک‌گذاری از تگ‌ها و علامت‌های اضافی پاک می‌شود.
