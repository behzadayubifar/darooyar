import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/number_formatter.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../utils/myket_utils.dart';
import '../../../services/myket_rating_service.dart';
import '../widgets/myket_rating_section.dart';
import '../../subscription/screens/credit_payment_screen.dart';
import '../../auth/services/auth_service.dart';

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      AppLogger.e('Error loading theme mode: $e');
    }
  }

  Future<void> toggleThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newMode =
          state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      await prefs.setBool('isDarkMode', newMode == ThemeMode.dark);
      state = newMode;
    } catch (e) {
      AppLogger.e('Error toggling theme mode: $e');
    }
  }
}

// Font size provider
final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, double>(
  (ref) => FontSizeNotifier(),
);

class FontSizeNotifier extends StateNotifier<double> {
  FontSizeNotifier() : super(1.0) {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fontSize = prefs.getDouble('fontSize') ?? 1.0;
      state = fontSize;
    } catch (e) {
      AppLogger.e('Error loading font size: $e');
    }
  }

  Future<void> setFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontSize', size);
      state = size;
    } catch (e) {
      AppLogger.e('Error setting font size: $e');
    }
  }
}

// Notifications provider
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsNotifier, bool>(
  (ref) => NotificationsNotifier(),
);

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notificationsEnabled') ?? true;
      state = enabled;
    } catch (e) {
      AppLogger.e('Error loading notification setting: $e');
    }
  }

  Future<void> toggleNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', !state);
      state = !state;
    } catch (e) {
      AppLogger.e('Error toggling notifications: $e');
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  final User user;

  const SettingsScreen({Key? key, required this.user}) : super(key: key);

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    // متغیرهای خطا برای هر فیلد
    String? currentPasswordError;
    String? newPasswordError;
    String? confirmPasswordError;

    // Create focus nodes for each field
    final currentPasswordFocus = FocusNode();
    final newPasswordFocus = FocusNode();
    final confirmPasswordFocus = FocusNode();

    // اعتبارسنجی رمز عبور فعلی
    bool validateCurrentPassword() {
      if (currentPasswordController.text.isEmpty) {
        currentPasswordError = 'لطفا رمز عبور فعلی را وارد کنید';
        return false;
      }
      currentPasswordError = null;
      return true;
    }

    // اعتبارسنجی رمز عبور جدید
    bool validateNewPassword() {
      final password = newPasswordController.text;
      if (password.isEmpty) {
        newPasswordError = 'لطفا رمز عبور جدید را وارد کنید';
        return false;
      }
      if (password.length < 8) {
        newPasswordError = 'رمز عبور باید حداقل ۸ کاراکتر باشد';
        return false;
      }
      if (!password.contains(RegExp(r'[A-Z]'))) {
        newPasswordError = 'رمز عبور باید حداقل یک حرف بزرگ داشته باشد';
        return false;
      }
      if (!password.contains(RegExp(r'[a-z]'))) {
        newPasswordError = 'رمز عبور باید حداقل یک حرف کوچک داشته باشد';
        return false;
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        newPasswordError = 'رمز عبور باید حداقل یک عدد داشته باشد';
        return false;
      }
      newPasswordError = null;
      return true;
    }

    // اعتبارسنجی تکرار رمز عبور
    bool validateConfirmPassword() {
      if (confirmPasswordController.text.isEmpty) {
        confirmPasswordError = 'لطفا تکرار رمز عبور را وارد کنید';
        return false;
      }
      if (confirmPasswordController.text != newPasswordController.text) {
        confirmPasswordError = 'تکرار رمز عبور با رمز عبور جدید مطابقت ندارد';
        return false;
      }
      confirmPasswordError = null;
      return true;
    }

    // اعتبارسنجی کل فرم
    bool validateForm() {
      final isCurrentPasswordValid = validateCurrentPassword();
      final isNewPasswordValid = validateNewPassword();
      final isConfirmPasswordValid = validateConfirmPassword();
      return isCurrentPasswordValid &&
          isNewPasswordValid &&
          isConfirmPasswordValid;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تغییر رمز عبور'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  focusNode: currentPasswordFocus,
                  decoration: InputDecoration(
                    labelText: 'رمز عبور فعلی',
                    border: const OutlineInputBorder(),
                    errorText: currentPasswordError,
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    // پاک کردن خطا هنگام تایپ
                    if (currentPasswordError != null) {
                      setState(() {
                        currentPasswordError = null;
                      });
                    }
                  },
                  onSubmitted: (_) {
                    // Move to next field when Enter/Next is pressed
                    FocusScope.of(context).requestFocus(newPasswordFocus);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  focusNode: newPasswordFocus,
                  decoration: InputDecoration(
                    labelText: 'رمز عبور جدید',
                    border: const OutlineInputBorder(),
                    errorText: newPasswordError,
                    helperText: 'حداقل ۸ کاراکتر، شامل حروف بزرگ، کوچک و اعداد',
                    helperMaxLines: 2,
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    // پاک کردن خطا هنگام تایپ
                    if (newPasswordError != null) {
                      setState(() {
                        newPasswordError = null;
                      });
                    }
                  },
                  onSubmitted: (_) {
                    // Move to next field when Enter/Next is pressed
                    FocusScope.of(context).requestFocus(confirmPasswordFocus);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  focusNode: confirmPasswordFocus,
                  decoration: InputDecoration(
                    labelText: 'تکرار رمز عبور جدید',
                    border: const OutlineInputBorder(),
                    errorText: confirmPasswordError,
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    // پاک کردن خطا هنگام تایپ
                    if (confirmPasswordError != null) {
                      setState(() {
                        confirmPasswordError = null;
                      });
                    }
                  },
                  onSubmitted: (_) {
                    // Close keyboard and submit form when Enter/Done is pressed on last field
                    FocusScope.of(context).unfocus();
                    if (!isLoading) {
                      setState(() {
                        if (validateForm()) {
                          SettingsScreen._changePassword(
                            context,
                            setState,
                            currentPasswordController.text,
                            newPasswordController.text,
                            () => setState(() => isLoading = true),
                            () => setState(() => isLoading = false),
                            (error) =>
                                setState(() => currentPasswordError = error),
                            (error) => setState(() => newPasswordError = error),
                            (error) =>
                                setState(() => confirmPasswordError = error),
                          );
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    if (validateForm()) {
                      SettingsScreen._changePassword(
                        context,
                        setState,
                        currentPasswordController.text,
                        newPasswordController.text,
                        () => setState(() => isLoading = true),
                        () => setState(() => isLoading = false),
                        (error) => setState(() => currentPasswordError = error),
                        (error) => setState(() => newPasswordError = error),
                        (error) => setState(() => confirmPasswordError = error),
                      );
                    }
                  });
                },
                child: const Text('تغییر رمز عبور'),
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> _changePassword(
    BuildContext context,
    StateSetter setState,
    String currentPassword,
    String newPassword,
    Function() setLoadingTrue,
    Function() setLoadingFalse,
    Function(String?) setCurrentPasswordError,
    Function(String?) setNewPasswordError,
    Function(String?) setConfirmPasswordError,
  ) async {
    setLoadingTrue();

    try {
      final authService = AuthService();
      await authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز عبور با موفقیت تغییر یافت')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // ترجمه پیام خطا به فارسی
        String errorMessage = e.toString();

        // بررسی نوع خطا
        if (errorMessage.contains('Current password is incorrect') ||
            errorMessage.contains('رمز عبور فعلی اشتباه است')) {
          // نمایش خطای رمز عبور فعلی در فیلد مربوطه
          setCurrentPasswordError('رمز عبور فعلی اشتباه است');
        } else {
          // سایر خطاها را در اسنک‌بار نمایش می‌دهیم
          if (errorMessage.contains('Invalid request body')) {
            errorMessage = 'درخواست نامعتبر است';
          } else if (errorMessage.contains('Unauthorized')) {
            errorMessage = 'دسترسی غیرمجاز';
          } else if (errorMessage.contains('User not found')) {
            errorMessage = 'کاربر یافت نشد';
          } else if (errorMessage
              .contains('Password must be at least 8 characters long')) {
            setNewPasswordError('رمز عبور باید حداقل ۸ کاراکتر باشد');
            setLoadingFalse();
            return;
          } else if (errorMessage.contains(
              'Password must contain at least one uppercase letter')) {
            setNewPasswordError('رمز عبور باید حداقل یک حرف بزرگ داشته باشد');
            setLoadingFalse();
            return;
          } else if (errorMessage.contains(
              'Password must contain at least one lowercase letter')) {
            setNewPasswordError('رمز عبور باید حداقل یک حرف کوچک داشته باشد');
            setLoadingFalse();
            return;
          } else if (errorMessage
              .contains('Password must contain at least one digit')) {
            setNewPasswordError('رمز عبور باید حداقل یک عدد داشته باشد');
            setLoadingFalse();
            return;
          } else {
            errorMessage = 'خطا در تغییر رمز عبور: لطفا دوباره تلاش کنید';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } finally {
      setLoadingFalse();
    }
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    bool isLoading = false;

    // Create focus nodes for each field
    final firstNameFocus = FocusNode();
    final lastNameFocus = FocusNode();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('ویرایش پروفایل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    controller: firstNameController,
                    focusNode: firstNameFocus,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'نام',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      // Move to next field when Enter/Next is pressed
                      FocusScope.of(context).requestFocus(lastNameFocus);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    controller: lastNameController,
                    focusNode: lastNameFocus,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'نام خانوادگی',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      // Close keyboard and submit form when Enter/Done is pressed on last field
                      FocusScope.of(context).unfocus();
                      if (!isLoading) {
                        _updateProfile(
                          context,
                          ref,
                          setState,
                          firstNameController.text,
                          lastNameController.text,
                          () => setState(() => isLoading = true),
                          () => setState(() => isLoading = false),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () async {
                  _updateProfile(
                    context,
                    ref,
                    setState,
                    firstNameController.text,
                    lastNameController.text,
                    () => setState(() => isLoading = true),
                    () => setState(() => isLoading = false),
                  );
                },
                child: const Text('ذخیره تغییرات'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile(
    BuildContext context,
    WidgetRef ref,
    StateSetter setState,
    String firstName,
    String lastName,
    Function() setLoadingTrue,
    Function() setLoadingFalse,
  ) async {
    setLoadingTrue();

    try {
      final authService = AuthService();
      final updatedUser = await authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );

      // Update the user state with the new data
      ref.read(authStateProvider.notifier).updateUserData(updatedUser);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پروفایل با موفقیت بروزرسانی شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بروزرسانی پروفایل: $e')),
        );
      }
    } finally {
      setLoadingFalse();
    }
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('حذف حساب کاربری'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'آیا مطمئن هستید که می‌خواهید حساب کاربری خود را حذف کنید؟ این عمل غیرقابل بازگشت است.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'رمز عبور خود را برای تایید وارد کنید',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('لطفا رمز عبور خود را وارد کنید')),
                    );
                    return;
                  }

                  setState(() => isLoading = true);

                  try {
                    // TODO: Implement account deletion API call
                    await Future.delayed(
                        const Duration(seconds: 1)); // Simulate API call

                    await ref.read(authStateProvider.notifier).logout();

                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('حساب کاربری شما با موفقیت حذف شد')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطا در حذف حساب کاربری: $e')),
                      );
                    }
                  } finally {
                    if (context.mounted) {
                      setState(() => isLoading = false);
                    }
                  }
                },
                child: const Text('حذف حساب کاربری'),
              ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, WidgetRef ref) {
    final currentFontSize = ref.read(fontSizeProvider);
    double newFontSize = currentFontSize;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اندازه متن'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اندازه فعلی: ${(newFontSize * 100).toInt()}%'),
            Slider(
              value: newFontSize,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              label: '${(newFontSize * 100).toInt()}%',
              onChanged: (value) {
                newFontSize = value;
                (context as Element).markNeedsBuild();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('کوچک', style: TextStyle(fontSize: 12)),
                  Text('بزرگ', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(fontSizeProvider.notifier).setFontSize(newFontSize);
              Navigator.pop(context);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Lottie.asset(
                    'assets/animations/profile.json',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  // Use Directionality to ensure proper RTL text direction for Persian
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Credit display
                  InkWell(
                    onTap: () {
                      // Navigate to credit payment screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreditPaymentScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'اعتبار: ${NumberFormatter.formatPriceInThousands(user.credit.toStringAsFixed(0))}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontFamily: 'Vazirmatn',
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Myket Rating Section
          const MyketRatingSection(),

          const SizedBox(height: 24),

          // Credit Management Section (if needed)
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.account_balance_wallet),
                  title: Text('مدیریت اعتبار'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('تاریخچه تراکنش‌ها'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to transaction history screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('این قابلیت به زودی اضافه خواهد شد')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_card),
                  title: const Text('افزایش اعتبار'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to credit payment screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreditPaymentScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: const Text('خرید اشتراک'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/subscription');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('اعلان‌ها'),
                  trailing: Switch(
                    value: notificationsEnabled,
                    onChanged: (value) {
                      ref
                          .read(notificationsEnabledProvider.notifier)
                          .toggleNotifications();
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('زبان'),
                  trailing: const Text('فارسی'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'در حال حاضر فقط زبان فارسی پشتیبانی می‌شود')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('حالت تاریک'),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).toggleThemeMode();
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: const Text('اندازه متن'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showFontSizeDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('ویرایش پروفایل'),
                  onTap: () => _showEditProfileDialog(context, ref),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('تغییر رمز عبور'),
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'حذف حساب کاربری',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _showDeleteAccountDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('خروج از حساب کاربری'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
