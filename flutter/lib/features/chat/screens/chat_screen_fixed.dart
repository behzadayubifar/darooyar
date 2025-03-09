import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
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

// حذف import‌های زیر که استفاده نشده‌اند:
// import '../widgets/message_bubble.dart';
// import '../widgets/message_actions.dart';
// import '../utils/message_utils.dart';

// همچنین حذف import زیر که استفاده نشده است:
// import 'package:cached_network_image/cached_network_image.dart';

// توجه: اگر در آینده از ویجت‌های MessageBubble و MessageActions استفاده کردید،
// می‌توانید import‌های مربوطه را دوباره اضافه کنید. 