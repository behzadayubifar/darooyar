import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myket_iap/myket_iap.dart';
import 'package:myket_iap/util/iab_result.dart';
import 'package:myket_iap/util/purchase.dart';
import '../core/utils/logger.dart';

// Wrapper class for IabResult
class IabResult {
  final dynamic _result;

  IabResult(this._result);

  bool isSuccess() {
    if (_result == null) return false;
    try {
      return _result.isSuccess();
    } catch (e) {
      return false;
    }
  }

  String getMessage() {
    if (_result == null) return 'Unknown error';
    try {
      // First try the getMessage method
      if (_result.runtimeType.toString().contains('IabResult')) {
        // Check if the method exists using reflection
        try {
          // Try to access message property directly if getMessage() doesn't exist
          final message = _result.message;
          if (message != null && message is String) {
            return message;
          }
        } catch (e) {
          // If property access fails, try toString()
          return _result.toString();
        }
      }

      // If all else fails, try the original method
      return _result.getMessage();
    } catch (e) {
      // Return a generic error message
      return 'Error code: ${getResponseCode()}';
    }
  }

  int getResponseCode() {
    if (_result == null) return -1;
    try {
      return _result.getResponse();
    } catch (e) {
      try {
        // Try to access response property directly
        final response = _result.response;
        if (response != null && response is int) {
          return response;
        }
      } catch (e2) {
        // Ignore
      }
      return -1;
    }
  }
}

// Wrapper class for Purchase
class Purchase {
  final dynamic _purchase;

  Purchase(this._purchase);

  String getSku() {
    if (_purchase == null) return '';
    try {
      return _purchase.getSku();
    } catch (e) {
      return '';
    }
  }

  String getOrderId() {
    if (_purchase == null) return '';
    try {
      return _purchase.getOrderId();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  String getToken() {
    if (_purchase == null) return '';
    try {
      return _purchase.getPurchaseToken();
    } catch (e) {
      return '';
    }
  }

  int getPurchaseTime() {
    if (_purchase == null) return DateTime.now().millisecondsSinceEpoch;
    try {
      return _purchase.getPurchaseTime();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  String getOriginalJson() {
    if (_purchase == null) return '{}';
    try {
      return _purchase.getOriginalJson();
    } catch (e) {
      return '{}';
    }
  }
}

// Implementation of Myket IAP service
class MyketIAPService {
  static const String _rsaKey =
      'YOUR_RSA_KEY_HERE'; // Replace with your actual RSA key from Myket developer panel
  static bool _isInitialized = false;

  // Initialize the Myket IAP service
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result =
          await MyketIAP.init(rsaKey: _rsaKey, enableDebugLogging: true);

      if (result != null && result.isSuccess()) {
        AppLogger.i('Myket IAP initialized successfully');
        _isInitialized = true;
        return true;
      } else {
        final message =
            result != null ? 'Unknown error' : 'Failed to initialize Myket IAP';
        AppLogger.e(message);
        return false;
      }
    } catch (e) {
      AppLogger.e('Error initializing Myket IAP: $e');
      return false;
    }
  }

  // Convert Toman to Rial (multiply by 10)
  static int _tomanToRial(int tomanAmount) {
    return tomanAmount * 10;
  }

  // Generate a unique SKU for the credit amount
  static String _generateCreditSku(int tomanAmount) {
    // Convert to Rial for Myket
    final rialAmount = _tomanToRial(tomanAmount);
    return 'credit_${rialAmount}';
  }

  // Purchase a product with amount in Toman
  static Future<Map<String, dynamic>?> purchaseCredit(int tomanAmount) async {
    // Generate SKU with Rial amount
    final sku = _generateCreditSku(tomanAmount);

    AppLogger.i(
        'Purchasing credit: $tomanAmount Toman (${_tomanToRial(tomanAmount)} Rial)');

    return await purchaseProduct(sku, originalAmount: tomanAmount);
  }

  // Purchase a product
  static Future<Map<String, dynamic>?> purchaseProduct(String sku,
      {int? originalAmount}) async {
    if (!await initialize()) {
      return {
        'success': false,
        'message': 'خطا در اتصال به مایکت',
      };
    }

    try {
      AppLogger.i('Starting purchase flow for SKU: $sku');

      // Launch the Myket payment flow
      final purchaseResult = await MyketIAP.launchPurchaseFlow(
          sku: sku, payload: originalAmount?.toString() ?? "");

      final result = purchaseResult[MyketIAP.RESULT];
      final purchase = purchaseResult[MyketIAP.PURCHASE];

      if (result != null && result.isSuccess() && purchase != null) {
        AppLogger.i('Purchase successful: ${purchase.getSku()}');

        // Get purchase details
        final purchaseData = {
          'sku': purchase.getSku(),
          'orderId': purchase.getOrderId(),
          'purchaseTime': purchase.getPurchaseTime(),
          'purchaseToken': purchase.getToken(),
          'originalJson': purchase.getOriginalJson(),
          'originalAmount': originalAmount,
        };

        return {
          'success': true,
          'purchase': purchaseData,
        };
      } else {
        String userFriendlyMessage = 'خطا در فرآیند پرداخت';
        int responseCode = -1;

        // Log the technical error for debugging
        if (result != null) {
          try {
            // Try to get response code first
            responseCode = IabResult(result).getResponseCode();

            // Try to get message
            String technicalMessage;
            try {
              technicalMessage = IabResult(result).getMessage();
            } catch (messageError) {
              AppLogger.e('Error getting result message: $messageError');
              technicalMessage = 'Error code: $responseCode';
            }

            AppLogger.e(
                'Purchase failed: $technicalMessage (code: $responseCode)');

            // Map response codes to user-friendly messages
            switch (responseCode) {
              case 1: // USER_CANCELED
                userFriendlyMessage = 'پرداخت توسط کاربر لغو شد';
                break;
              case 2: // SERVICE_UNAVAILABLE
                userFriendlyMessage = 'سرویس پرداخت در دسترس نیست';
                break;
              case 3: // BILLING_UNAVAILABLE
                userFriendlyMessage = 'سرویس پرداخت مایکت در دسترس نیست';
                break;
              case 4: // ITEM_UNAVAILABLE
                userFriendlyMessage = 'این محصول در حال حاضر در دسترس نیست';
                break;
              case 5: // DEVELOPER_ERROR
                userFriendlyMessage = 'خطا در پیکربندی پرداخت';
                break;
              case 6: // ERROR
                userFriendlyMessage = 'خطا در فرآیند پرداخت';
                break;
              case 7: // ITEM_ALREADY_OWNED
                userFriendlyMessage = 'این محصول قبلاً خریداری شده است';
                break;
              case 8: // ITEM_NOT_OWNED
                userFriendlyMessage = 'این محصول متعلق به شما نیست';
                break;
              default:
                // Map technical errors to user-friendly messages based on message content
                if (technicalMessage.contains('User canceled')) {
                  userFriendlyMessage = 'پرداخت توسط کاربر لغو شد';
                } else if (technicalMessage.contains('Item unavailable')) {
                  userFriendlyMessage = 'این محصول در حال حاضر در دسترس نیست';
                } else if (technicalMessage.contains('Network')) {
                  userFriendlyMessage = 'خطا در اتصال به اینترنت';
                }
            }
          } catch (error) {
            AppLogger.e('Error processing result: $error');
          }
        } else {
          AppLogger.e('Purchase failed: Result is null');
        }

        return {
          'success': false,
          'message': userFriendlyMessage,
          'code': responseCode,
        };
      }
    } catch (e) {
      AppLogger.e('Error during purchase: $e');

      // Provide a user-friendly error message based on the exception
      String userFriendlyMessage = 'خطا در فرآیند پرداخت';

      if (e is PlatformException) {
        AppLogger.e('Platform exception: ${e.code} - ${e.message}');

        if (e.code == 'CANCELED') {
          userFriendlyMessage = 'پرداخت توسط کاربر لغو شد';
        } else if (e.code == 'NETWORK_ERROR') {
          userFriendlyMessage = 'خطا در اتصال به اینترنت';
        } else if (e.code == 'ITEM_UNAVAILABLE') {
          userFriendlyMessage = 'این محصول در حال حاضر در دسترس نیست';
        } else if (e.code == 'SERVICE_UNAVAILABLE') {
          userFriendlyMessage = 'سرویس پرداخت در دسترس نیست';
        }
      } else if (e.toString().contains('NoSuchMethodError')) {
        // Handle the specific error we're seeing in the screenshot
        userFriendlyMessage = 'خطا در ارتباط با سرویس پرداخت';
      }

      return {
        'success': false,
        'message': userFriendlyMessage,
      };
    }
  }

  // Consume a purchase to allow repurchasing
  static Future<bool> consumePurchase(dynamic purchase) async {
    if (!_isInitialized) {
      return false;
    }

    try {
      final consumeResult = await MyketIAP.consume(purchase: purchase);
      final result = consumeResult[MyketIAP.RESULT];

      if (result != null && result.isSuccess()) {
        AppLogger.i('Purchase consumed successfully');
        return true;
      } else {
        final message =
            result != null ? result.getMessage() : 'Failed to consume purchase';
        AppLogger.e('Failed to consume purchase: $message');
        return false;
      }
    } catch (e) {
      AppLogger.e('Error consuming purchase: $e');
      return false;
    }
  }

  // Dispose resources
  static Future<void> dispose() async {
    if (_isInitialized) {
      await MyketIAP.dispose();
      _isInitialized = false;
    }
  }
}
