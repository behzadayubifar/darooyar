import 'package:flutter/material.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final bool hasTimeLimit;
  final int timeLimitDays;
  final bool keepsPreviousVersions;
  final int dataRetentionDays;
  final int prescriptionCount;
  final double price;
  final List<String> features;
  final String imagePath;
  final IconData? fallbackIcon;
  final Color? iconColor;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.hasTimeLimit,
    required this.timeLimitDays,
    required this.keepsPreviousVersions,
    required this.dataRetentionDays,
    required this.prescriptionCount,
    required this.price,
    required this.features,
    required this.imagePath,
    this.fallbackIcon,
    this.iconColor,
  });

  // Lista de planes predefinidos
  static List<SubscriptionPlan> allPlans = [
    SubscriptionPlan(
      id: 'cephalexin',
      name: 'سفالکسین',
      description: 'پلن اقتصادی برای استفاده کوتاه مدت',
      hasTimeLimit: true,
      timeLimitDays: 7,
      keepsPreviousVersions: false,
      dataRetentionDays: 0,
      prescriptionCount: 3,
      price: 45.0,
      features: [
        'دسترسی به تمام امکانات پایه',
        'محدودیت زمانی ۱ هفته',
        'بدون حفظ نسخه‌های قبلی',
        'ثبت ۳ نسخه',
      ],
      imagePath: 'assets/images/plans/basic_plan.svg',
      fallbackIcon: Icons.medication_outlined,
      iconColor: Colors.orange,
    ),
    SubscriptionPlan(
      id: 'cefuroxime',
      name: 'سفوروکسیم',
      description: 'پلن متوسط با امکانات کاربردی',
      hasTimeLimit: false,
      timeLimitDays: 0,
      keepsPreviousVersions: true,
      dataRetentionDays: 30,
      prescriptionCount: 10,
      price: 135.0,
      features: [
        'دسترسی به تمام امکانات پایه',
        'بدون محدودیت زمانی',
        'حفظ نسخه‌های قبلی تا ۱ ماه',
        'ثبت ۱۰ نسخه',
      ],
      imagePath: 'assets/images/plans/standard_plan.svg',
      fallbackIcon: Icons.medical_services_outlined,
      iconColor: Colors.blue,
    ),
    SubscriptionPlan(
      id: 'cefixime',
      name: 'سفکسیم',
      description: 'پلن پیشرفته با امکانات کامل',
      hasTimeLimit: false,
      timeLimitDays: 0,
      keepsPreviousVersions: true,
      dataRetentionDays: 365,
      prescriptionCount: 30,
      price: 375.0,
      features: [
        'دسترسی به تمام امکانات پیشرفته',
        'بدون محدودیت زمانی',
        'حفظ نسخه‌های قبلی تا ۱ سال',
        'ثبت ۳۰ نسخه',
        'پشتیبانی اختصاصی',
      ],
      imagePath: 'assets/images/plans/premium_plan.svg',
      fallbackIcon: Icons.health_and_safety_outlined,
      iconColor: Colors.indigo,
    ),
  ];

  // Método para obtener detalles formatados del plan
  String getTimeInfo() {
    if (hasTimeLimit) {
      return 'محدودیت زمانی $timeLimitDays روز';
    } else {
      return 'بدون محدودیت زمانی';
    }
  }

  String getRetentionInfo() {
    if (keepsPreviousVersions) {
      if (dataRetentionDays == 30) {
        return 'حفظ اطلاعات تا ۱ ماه';
      } else if (dataRetentionDays == 365) {
        return 'حفظ اطلاعات تا ۱ سال';
      } else {
        return 'حفظ اطلاعات تا $dataRetentionDays روز';
      }
    } else {
      return 'بدون حفظ اطلاعات قبلی';
    }
  }

  String getPrescriptionInfo() {
    return '$prescriptionCount نسخه';
  }

  String getPriceInfo() {
    return '$price تومان';
  }
}
