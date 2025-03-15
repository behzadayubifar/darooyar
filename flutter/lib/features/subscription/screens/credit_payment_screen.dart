import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../services/myket_iap_service.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../services/dio_provider.dart';

class CreditPaymentScreen extends ConsumerStatefulWidget {
  const CreditPaymentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreditPaymentScreen> createState() =>
      _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends ConsumerState<CreditPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  // Predefined credit amounts
  final List<int> _predefinedAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _amountController.text = '100000'; // Default amount

    // Initialize Myket IAP service when the screen loads
    _initializeMyketIAP();
  }

  Future<void> _initializeMyketIAP() async {
    try {
      final initialized = await MyketIAPService.initialize();
      if (!initialized) {
        if (mounted) {
          setState(() {
            _errorMessage = 'خطا در اتصال به سرویس پرداخت مایکت';
          });
        }
      }
    } catch (e) {
      AppLogger.e('Error initializing Myket IAP: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'خطا در اتصال به سرویس پرداخت مایکت';
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Format the input with thousands separator
  String _formatNumber(String s) {
    if (s.isEmpty) return '';

    // Remove all non-digit characters
    final digitsOnly = s.replaceAll(RegExp(r'[^\d]'), '');

    // Format with thousands separator
    return NumberFormatter.formatPriceInThousands(digitsOnly);
  }

  // Get the numeric value from the formatted text
  int _getNumericValue(String formattedText) {
    if (formattedText.isEmpty) return 0;
    return int.parse(formattedText.replaceAll(RegExp(r'[^\d]'), ''));
  }

  // Handle the payment process
  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final amount = _getNumericValue(_amountController.text);

      if (amount < 10000) {
        setState(() {
          _errorMessage = 'مبلغ باید حداقل ۱۰,۰۰۰ تومان باشد';
          _isProcessing = false;
        });
        return;
      }

      // Call the MyketIAPService to process the payment with Toman amount
      // It will automatically convert to Rial for Myket
      final result = await MyketIAPService.purchaseCredit(amount);

      if (result == null) {
        setState(() {
          _errorMessage = 'خطا در اتصال به مایکت';
          _isProcessing = false;
        });
        return;
      }

      if (result['success']) {
        // Call the server API to update the user's credit
        await _updateUserCredit(amount, result['purchase']);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'خطا در فرآیند پرداخت';
          _isProcessing = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error in payment process: $e');

      // Provide a user-friendly error message
      String userFriendlyMessage = 'خطا در فرآیند پرداخت';

      // Log the technical error but show a user-friendly message
      if (e.toString().contains('NoSuchMethodError')) {
        userFriendlyMessage = 'خطا در ارتباط با سرویس پرداخت';
      } else if (e.toString().contains('network')) {
        userFriendlyMessage = 'خطا در اتصال به اینترنت';
      }

      setState(() {
        _errorMessage = userFriendlyMessage;
        _isProcessing = false;
      });
    }
  }

  // Update user credit on the server
  Future<void> _updateUserCredit(
      int amount, Map<String, dynamic> purchaseData) async {
    try {
      final dio = ref.read(dioProvider);
      final token = await ref.read(authServiceProvider).getToken();

      if (token == null) {
        setState(() {
          _errorMessage = 'خطا در احراز هویت';
          _isProcessing = false;
        });
        return;
      }

      // Prepare transaction data for the server
      final transactionData = {
        'amount': amount,
        'transaction': {
          ...purchaseData,
          'paymentGateway': 'myket',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      };

      AppLogger.i('Sending transaction data to server: $transactionData');

      final response = await dio.post(
        '/api/user/credit/add',
        data: transactionData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Transaction successful
        AppLogger.i('Credit added successfully: ${response.data}');

        // Refresh user data
        await ref.read(authStateProvider.notifier).refreshUser();

        if (mounted) {
          // Show success message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('افزایش اعتبار با موفقیت انجام شد'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else if (response.statusCode == 409) {
        // Transaction already processed
        AppLogger.w('Transaction already processed: ${response.data}');

        // Still refresh user data
        await ref.read(authStateProvider.notifier).refreshUser();

        if (mounted) {
          // Show success message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('این تراکنش قبلاً پردازش شده است'),
              backgroundColor: Colors.amber,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Error processing transaction
        AppLogger.e(
            'Error processing transaction: ${response.statusCode} - ${response.data}');

        setState(() {
          _errorMessage =
              response.data?['message'] ?? 'خطا در ثبت تراکنش در سرور';
          _isProcessing = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error updating user credit: $e');

      // Provide a user-friendly error message
      String userFriendlyMessage = 'خطا در ارتباط با سرور';

      // Log the technical error but show a user-friendly message
      if (e.toString().contains('timeout')) {
        userFriendlyMessage = 'زمان ارتباط با سرور به پایان رسید';
      } else if (e.toString().contains('network')) {
        userFriendlyMessage = 'خطا در اتصال به اینترنت';
      }

      setState(() {
        _errorMessage = userFriendlyMessage;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('افزایش اعتبار'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current credit display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اعتبار فعلی شما',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          NumberFormatter.formatPriceInThousands(
                            (user?.credit ?? 0).toStringAsFixed(0),
                          ),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'تومان',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Payment amount input
              const Text(
                'مبلغ مورد نظر برای افزایش اعتبار',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '۱۰۰,۰۰۰',
                  suffixText: 'تومان',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final formatted = _formatNumber(newValue.text);
                    return TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 16),

              // Predefined amounts
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedAmounts.map((amount) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _amountController.text =
                            _formatNumber(amount.toString());
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${NumberFormatter.formatPriceInThousands(amount.toString())} تومان',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Payment button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'بریم برای پرداخت',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'توجه:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'پس از کلیک روی دکمه پرداخت، به درگاه پرداخت مایکت منتقل خواهید شد. پس از تکمیل فرآیند پرداخت، اعتبار شما به صورت خودکار افزایش می‌یابد.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'مبلغ وارد شده به صورت خودکار از تومان به ریال تبدیل می‌شود.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
