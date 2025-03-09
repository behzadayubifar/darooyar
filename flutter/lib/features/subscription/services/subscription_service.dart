import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../models/subscription_plan.dart';
import '../models/plan.dart';

class SubscriptionService {
  static const String baseUrl = AppConstants.baseUrl;

  // Get all available plans
  Future<List<Plan>> getPlans(String token) async {
    try {
      AppLogger.i('Fetching available plans');
      final response = await http.get(
        Uri.parse('$baseUrl/plans'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.network(
        'GET',
        '$baseUrl/plans',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );

        if (data.containsKey('plans') && data['plans'] is List) {
          final List<dynamic> plansList = data['plans'];
          return plansList.map((planJson) => Plan.fromJson(planJson)).toList();
        }
        return [];
      } else {
        AppLogger.e('Error fetching plans: ${response.statusCode}');
        throw Exception('Failed to fetch plans');
      }
    } catch (e) {
      AppLogger.e('Exception fetching plans: $e');
      throw Exception('Failed to fetch plans: $e');
    }
  }

  // Get plan by ID
  Future<Plan> getPlanById(String token, String planId) async {
    try {
      AppLogger.i('Fetching plan with ID: $planId');
      final response = await http.get(
        Uri.parse('$baseUrl/plans/$planId'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.network(
        'GET',
        '$baseUrl/plans/$planId',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> planJson = jsonDecode(
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );
        return Plan.fromJson(planJson);
      } else {
        AppLogger.e('Error fetching plan: ${response.statusCode}');
        throw Exception('Failed to fetch plan');
      }
    } catch (e) {
      AppLogger.e('Exception fetching plan: $e');
      throw Exception('Failed to fetch plan: $e');
    }
  }

  // Purchase a subscription plan
  Future<UserSubscription> purchasePlan(String token, String planId) async {
    try {
      AppLogger.i('Purchasing plan with ID: $planId');

      // Convert planId from string to integer
      final int? planIdInt = int.tryParse(planId);
      if (planIdInt == null) {
        throw Exception('Invalid plan ID format');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/purchase'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: utf8.encode(jsonEncode({
          'plan_id': planIdInt, // Send as integer instead of string
        })),
      );

      AppLogger.network(
        'POST',
        '$baseUrl/subscriptions/purchase',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );

        if (data.containsKey('subscription')) {
          return UserSubscription.fromJson(data['subscription']);
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 402) {
        throw Exception('Insufficient credit');
      } else {
        AppLogger.e('Error purchasing plan: ${response.statusCode}');
        throw Exception('Failed to purchase plan');
      }
    } catch (e) {
      AppLogger.e('Exception purchasing plan: $e');
      throw Exception('Failed to purchase plan: $e');
    }
  }

  // Get user subscriptions
  Future<List<UserSubscription>> getUserSubscriptions(String token) async {
    try {
      AppLogger.i('Fetching user subscriptions');
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.network(
        'GET',
        '$baseUrl/subscriptions',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );

        if (data.containsKey('subscriptions') &&
            data['subscriptions'] is List) {
          final List<dynamic> subsList = data['subscriptions'];
          return subsList
              .map((subJson) => UserSubscription.fromJson(subJson))
              .toList();
        }
        return [];
      } else {
        AppLogger.e('Error fetching subscriptions: ${response.statusCode}');
        throw Exception('Failed to fetch subscriptions');
      }
    } catch (e) {
      AppLogger.e('Exception fetching subscriptions: $e');
      throw Exception('Failed to fetch subscriptions: $e');
    }
  }

  // Get active user subscriptions
  Future<List<UserSubscription>> getActiveUserSubscriptions(
      String token) async {
    try {
      AppLogger.i('Fetching active user subscriptions');
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/active'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.network(
        'GET',
        '$baseUrl/subscriptions/active',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );

        if (data.containsKey('subscriptions') &&
            data['subscriptions'] is List) {
          final List<dynamic> subsList = data['subscriptions'];
          return subsList
              .map((subJson) => UserSubscription.fromJson(subJson))
              .toList();
        }
        return [];
      } else {
        AppLogger.e(
            'Error fetching active subscriptions: ${response.statusCode}');
        throw Exception('Failed to fetch active subscriptions');
      }
    } catch (e) {
      AppLogger.e('Exception fetching active subscriptions: $e');
      throw Exception('Failed to fetch active subscriptions: $e');
    }
  }

  // Record subscription usage
  Future<void> useSubscription(
      String token, String subscriptionId, int count) async {
    try {
      AppLogger.i(
          'Recording usage for subscription ID: $subscriptionId, count: $count');
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/use'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: utf8.encode(jsonEncode({
          'subscription_id': subscriptionId,
          'count': count,
        })),
      );

      AppLogger.network(
        'POST',
        '$baseUrl/subscriptions/use',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode != 200) {
        AppLogger.e(
            'Error recording subscription usage: ${response.statusCode}');
        throw Exception('Failed to record subscription usage');
      }
    } catch (e) {
      AppLogger.e('Exception recording subscription usage: $e');
      throw Exception('Failed to record subscription usage: $e');
    }
  }

  // Get credit transactions
  Future<List<CreditTransaction>> getCreditTransactions(
    String token, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.i('Fetching credit transactions');
      final response = await http.get(
        Uri.parse('$baseUrl/transactions?limit=$limit&offset=$offset'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.network(
        'GET',
        '$baseUrl/transactions?limit=$limit&offset=$offset',
        response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );

        if (data.containsKey('transactions') && data['transactions'] is List) {
          final List<dynamic> txnsList = data['transactions'];
          return txnsList
              .map((txnJson) => CreditTransaction.fromJson(txnJson))
              .toList();
        }
        return [];
      } else {
        AppLogger.e('Error fetching transactions: ${response.statusCode}');
        throw Exception('Failed to fetch transactions');
      }
    } catch (e) {
      AppLogger.e('Exception fetching transactions: $e');
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  // Método para obtener el plan actual del usuario
  Future<SubscriptionPlan?> getCurrentPlan(String token) async {
    try {
      AppLogger.i('Fetching current subscription plan');
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/current'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.network(
        'GET',
        '$baseUrl/subscriptions/current',
        response.statusCode,
        body: response.body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract plan ID from the nested plan object
        final planId = responseData['plan'] != null
            ? responseData['plan']['id']?.toString()
            : null;

        if (planId == null) {
          AppLogger.w('Plan ID is null in the response');
          return null;
        }

        // Buscar el plan en nuestra lista de planes predefinidos
        try {
          // Map server plan IDs to our predefined plan IDs
          // This is a temporary solution - ideally we should use the same IDs
          String mappedPlanId;
          switch (planId) {
            case "1":
              mappedPlanId = "cephalexin"; // Basic plan
              break;
            case "2":
              mappedPlanId = "cefuroxime"; // Standard plan
              break;
            case "3":
              mappedPlanId = "cefixime"; // Premium plan
              break;
            default:
              mappedPlanId = "cephalexin"; // Default to basic plan
          }

          return SubscriptionPlan.allPlans
              .firstWhere((plan) => plan.id == mappedPlanId);
        } catch (e) {
          AppLogger.w('No matching plan found for ID: $planId');
          return null;
        }
      } else if (response.statusCode == 404) {
        // El usuario no tiene un plan activo
        AppLogger.i('User has no active subscription plan');
        return null;
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? 'Unknown error';
        } catch (e) {
          errorMessage = 'Failed to fetch current plan';
        }
        AppLogger.e('Error fetching current plan: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.e('Exception fetching current plan: $e');
      return null; // Retorna null en caso de error para manejar suavemente
    }
  }

  // Método para simular una compra local (para desarrollo y demostración)
  Future<bool> simulatePurchase(String planId, double userCredit) async {
    try {
      // Buscar el plan seleccionado
      final plan =
          SubscriptionPlan.allPlans.firstWhere((plan) => plan.id == planId);

      // Verificar si el usuario tiene suficiente crédito
      if (userCredit < plan.price) {
        throw Exception('اعتبار ناکافی برای خرید این پلن');
      }

      // Simular un pequeño retraso para imitar una llamada a la red
      await Future.delayed(const Duration(milliseconds: 800));

      // La compra fue exitosa
      return true;
    } catch (e) {
      AppLogger.e('Error in simulated purchase: $e');
      throw Exception(e.toString());
    }
  }
}
