import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show File, Platform;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:image_clipboard/image_clipboard.dart';
import 'package:cross_file/cross_file.dart';
import '../../../core/theme/app_theme.dart';

/// ویجت نمایش دکمه‌های عملیات روی پیام
class MessageActions extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isError;
  final bool isLoading;
  final bool isThinking;
  final bool isImage;
  final VoidCallback? onRetry;

  const MessageActions({
    Key? key,
    required this.content,
    this.isUser = false,
    this.isError = false,
    this.isLoading = false,
    this.isThinking = false,
    this.isImage = false,
    this.onRetry,
  }) : super(key: key);

  /// تمیز کردن محتوای پیام از تگ‌ها و علامت‌های اضافی
  String _cleanMessageContent(String content) {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('***', '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('✧✧✧', '')
        .replaceAll('✧✧', '')
        .replaceAll('✧', '');
  }

  /// کپی کردن محتوای پیام در کلیپ‌بورد
  Future<void> _copyMessageContent(BuildContext context) async {
    // اگر پیام تصویر است
    if (isImage) {
      try {
        // نمایش اسنک‌بار در حال بارگذاری
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text('در حال کپی تصویر...'),
              ],
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Uint8List? imageBytes;

        // دریافت تصویر از آدرس اینترنتی
        if (content.startsWith('http')) {
          final response = await http.get(Uri.parse(content));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          } else {
            throw Exception('خطا در دریافت تصویر');
          }
        } else {
          // خواندن تصویر از فایل محلی
          final file = File(content);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
          } else {
            throw Exception('فایل تصویر یافت نشد');
          }
        }

        if (imageBytes != null) {
          // کپی تصویر در کلیپ‌بورد
          final imageClipboard = ImageClipboard();
          await imageClipboard.copyImage(imageBytes.toString());

          // نمایش پیام موفقیت
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('تصویر با موفقیت کپی شد'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // نمایش پیام خطا
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Flexible(child: Text('خطا در کپی تصویر: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // کپی متن معمولی
      String cleanContent = _cleanMessageContent(content);

      await Clipboard.setData(ClipboardData(text: cleanContent));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('متن با موفقیت کپی شد'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// اشتراک‌گذاری محتوای پیام
  Future<void> _shareMessageContent(BuildContext context) async {
    // اگر پیام تصویر است
    if (isImage) {
      try {
        // نمایش اسنک‌بار در حال بارگذاری
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text('در حال آماده‌سازی تصویر...'),
              ],
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );

        String? imagePath;

        // دریافت تصویر از آدرس اینترنتی
        if (content.startsWith('http')) {
          final response = await http.get(Uri.parse(content));
          if (response.statusCode == 200) {
            // ذخیره موقت تصویر
            final tempDir = await getTemporaryDirectory();
            final file = File(
                '${tempDir.path}/darooyar_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await file.writeAsBytes(response.bodyBytes);
            imagePath = file.path;
          } else {
            throw Exception('خطا در دریافت تصویر');
          }
        } else {
          // استفاده از مسیر فایل محلی
          imagePath = content;
        }

        if (imagePath != null) {
          // اشتراک‌گذاری تصویر
          final box = context.findRenderObject() as RenderBox?;
          await Share.shareXFiles(
            [XFile(imagePath)],
            subject: 'تصویر نسخه از دارویار',
            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
          );
        }
      } catch (e) {
        // نمایش پیام خطا
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Flexible(
                    child: Text('خطا در اشتراک‌گذاری تصویر: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // اشتراک‌گذاری متن معمولی
      String cleanContent = _cleanMessageContent(content);
      String shareText = isUser
          ? "سوال من از دارویار: $cleanContent"
          : "پاسخ دارویار: $cleanContent";

      // نمایش منوی اشتراک‌گذاری سیستم به طور مستقیم
      final box = context.findRenderObject() as RenderBox?;
      Share.share(
        shareText,
        subject: 'دارویار',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    }
  }

  /// دکمه عملیات با استایل جدید
  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // دکمه‌های کپی و اشتراک‌گذاری برای همه پیام‌ها به جز پیام‌های در حال بارگذاری، خطا و تفکر
        if (!isError && !isLoading && !isThinking) ...[
          const SizedBox(width: 8),
          _actionButton(
            context: context,
            icon: Icons.copy_rounded,
            label: 'کپی',
            onTap: () => _copyMessageContent(context),
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          _actionButton(
            context: context,
            icon: Icons.share_rounded,
            label: 'اشتراک‌گذاری',
            onTap: () => _shareMessageContent(context),
            color: AppTheme.primaryColor,
          ),
        ],

        // دکمه تلاش مجدد برای پیام‌های خطا
        if (isError && onRetry != null) ...[
          const SizedBox(width: 8),
          _actionButton(
            context: context,
            icon: Icons.refresh_rounded,
            label: 'تلاش مجدد',
            onTap: onRetry!,
            color: Colors.white,
          ),
        ],
      ],
    );
  }
}
