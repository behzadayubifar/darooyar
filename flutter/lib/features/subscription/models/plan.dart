import 'package:flutter/foundation.dart';

class Plan {
  final String id;
  final String title;
  final String description;
  final double price;
  final int? durationDays;
  final int? maxUses;
  final String planType;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.durationDays,
    this.maxUses,
    required this.planType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price:
          json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      durationDays: json['duration_days'],
      maxUses: json['max_uses'],
      planType: json['plan_type'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'duration_days': durationDays,
      'max_uses': maxUses,
      'plan_type': planType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Plan{id: $id, title: $title, price: $price}';
  }

  String get formattedPrice => '$price تومان';

  String get formattedDuration {
    if (durationDays == null) return 'نامحدود';
    if (durationDays! < 30) return '$durationDays روز';
    if (durationDays! % 30 == 0) {
      int months = durationDays! ~/ 30;
      return '$months ماه';
    }
    return '$durationDays روز';
  }

  String get formattedUses {
    if (maxUses == null) return 'نامحدود';
    return '$maxUses بار';
  }

  bool get isTimeBased => planType == 'time_based' || planType == 'both';
  bool get isUsageBased => planType == 'usage_based' || planType == 'both';
}

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final Plan? plan;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final String status;
  final int usesCount;
  final int? remainingUses;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.plan,
    required this.purchaseDate,
    this.expiryDate,
    required this.status,
    required this.usesCount,
    this.remainingUses,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      planId: json['plan_id'].toString(),
      plan: json['plan'] != null ? Plan.fromJson(json['plan']) : null,
      purchaseDate: DateTime.parse(json['purchase_date']),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      status: json['status'] ?? '',
      usesCount: json['uses_count'] ?? 0,
      remainingUses: json['remaining_uses'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'plan': plan?.toJson(),
      'purchase_date': purchaseDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'status': status,
      'uses_count': usesCount,
      'remaining_uses': remainingUses,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';

  String get formattedStatus {
    switch (status) {
      case 'active':
        return 'فعال';
      case 'expired':
        return 'منقضی شده';
      case 'cancelled':
        return 'لغو شده';
      default:
        return status;
    }
  }

  String get formattedRemainingTime {
    if (expiryDate == null) return 'نامحدود';
    if (isExpired) return 'منقضی شده';

    final now = DateTime.now();
    final difference = expiryDate!.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} روز باقیمانده';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعت باقیمانده';
    } else {
      return '${difference.inMinutes} دقیقه باقیمانده';
    }
  }

  String get formattedRemainingUses {
    if (remainingUses == null) return 'نامحدود';
    return '$remainingUses بار باقیمانده';
  }
}

class CreditTransaction {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final String transactionType;
  final String? relatedSubscriptionId;
  final DateTime createdAt;

  CreditTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.transactionType,
    this.relatedSubscriptionId,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      amount: json['amount'] != null
          ? double.parse(json['amount'].toString())
          : 0.0,
      description: json['description'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      relatedSubscriptionId: json['related_subscription_id']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'description': description,
      'transaction_type': transactionType,
      'related_subscription_id': relatedSubscriptionId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  String get formattedAmount {
    final sign = isCredit ? '+' : '';
    return '$sign$amount تومان';
  }

  String get formattedType {
    switch (transactionType) {
      case 'subscription':
        return 'خرید اشتراک';
      case 'usage':
        return 'استفاده از سرویس';
      case 'refund':
        return 'بازگشت وجه';
      case 'admin_adjustment':
        return 'تنظیم توسط ادمین';
      default:
        return transactionType;
    }
  }
}
