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
      return _result.getMessage();
    } catch (e) {
      return 'Error: $e';
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

  // Purchase a product
  static Future<Map<String, dynamic>?> purchaseProduct(String sku) async {
    if (!await initialize()) {
      return {
        'success': false,
        'message': 'خطا در اتصال به مایکت',
      };
    }

    try {
      AppLogger.i('Starting purchase flow for SKU: $sku');

      // Launch the Myket payment flow
      final purchaseResult =
          await MyketIAP.launchPurchaseFlow(sku: sku, payload: "");

      final result = purchaseResult[MyketIAP.RESULT];
      final purchase = purchaseResult[MyketIAP.PURCHASE];

      if (result != null && result.isSuccess() && purchase != null) {
        AppLogger.i('Purchase successful: ${purchase.getSku()}');

        // Get purchase details
        final purchaseData = {
          'sku': purchase.getSku(),
          'orderId': purchase
              .getSku(), // Using SKU as order ID since getOrderId() is not available
          'purchaseTime': DateTime.now()
              .millisecondsSinceEpoch, // Current time as purchase time
          'purchaseToken': purchase
              .getSku(), // Using SKU as token since getToken() is not available
        };

        return {
          'success': true,
          'purchase': purchaseData,
        };
      } else {
        final message = result != null ? 'Unknown error' : 'Purchase failed';
        AppLogger.e(message);
        return {
          'success': false,
          'message': 'خطا در فرآیند خرید',
        };
      }
    } catch (e) {
      AppLogger.e('Error during purchase: $e');
      return {
        'success': false,
        'message': 'خطا در فرآیند خرید: $e',
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
            result != null ? 'Unknown error' : 'Failed to consume purchase';
        AppLogger.e(message);
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
