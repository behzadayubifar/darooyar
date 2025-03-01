# دارویار - برنامه تحلیل نسخه

# Darooyar - Prescription Analysis App

<div dir="rtl">

## توضیحات

دارویار یک اپلیکیشن موبایل است که به کاربران امکان می‌دهد نسخه‌های پزشکی خود را با استفاده از هوش مصنوعی تحلیل کنند. کاربران می‌توانند نسخه‌ها را به صورت متن یا تصویر ارسال کرده و نتایج تحلیل را در یک رابط کاربری شبیه به چت مشاهده کنند.

## ویژگی‌ها

- ارسال نسخه به صورت متن یا تصویر
- مشاهده نتایج تحلیل در رابط کاربری شبیه به چت
- ویرایش یا حذف پیام‌ها
- مشاهده تاریخچه نسخه‌ها
- ذخیره محلی مکالمات

## تکنولوژی‌های استفاده شده

- **Flutter**: فریم‌ورک توسعه چند پلتفرمی
- **Riverpod**: مدیریت وضعیت
- **Hooks**: مدیریت چرخه حیات ویجت‌ها
- **Dio**: درخواست‌های شبکه
- **Isar**: پایگاه داده محلی
- **Image Picker**: انتخاب تصویر از دوربین یا گالری

## پیش‌نیازها

- Flutter SDK نسخه 3.24.0 یا بالاتر
- Dart SDK نسخه 3.5.0 یا بالاتر
- Android Studio یا VS Code با افزونه Flutter

## نصب و راه‌اندازی

1. مخزن را کلون کنید:
   ```
   git clone https://github.com/yourusername/darooyar.git
   ```
2. به دایرکتوری پروژه بروید:
   ```
   cd darooyar
   ```
3. وابستگی‌ها را نصب کنید:
   ```
   flutter pub get
   ```
4. مدل‌های Isar را تولید کنید:
   ```
   dart run build_runner build --delete-conflicting-outputs
   ```
5. برنامه را اجرا کنید:
   ```
   flutter run
   ```

## ساختار پروژه

پروژه از معماری تمیز با لایه‌های زیر استفاده می‌کند:

- **core**: ابزارها و کلاس‌های مشترک
  - **constants**: ثابت‌های برنامه
  - **theme**: تم و استایل‌های برنامه
  - **utils**: ابزارهای کمکی مانند سرویس پایگاه داده
- **features**: ماژول‌های برنامه
  - **prescription**: ماژول اصلی برای مدیریت نسخه‌ها
    - **data**: لایه داده شامل مدل‌ها و مخازن
    - **domain**: لایه دامنه شامل موجودیت‌ها
    - **presentation**: لایه ارائه شامل صفحات، ویجت‌ها و ارائه‌دهنده‌ها

## پیکربندی API

برای استفاده از API تحلیل نسخه، آدرس API را در فایل `lib/core/constants/app_constants.dart` به‌روزرسانی کنید.

## مجوز

این پروژه تحت مجوز MIT منتشر شده است.

</div>

## Description

Darooyar is a mobile application that allows users to analyze medical prescriptions using AI. Users can submit prescriptions as text or images and view analysis results in a chat-like interface.

## Features

- Submit prescriptions as text or images
- View analysis results in a chat-like interface
- Edit or delete messages
- View prescription history
- Local conversation storage

## Technologies Used

- **Flutter**: Cross-platform development framework
- **Riverpod**: State management
- **Hooks**: Widget lifecycle management
- **Dio**: Network requests
- **Isar**: Local database
- **Image Picker**: Select images from camera or gallery

## Prerequisites

- Flutter SDK version 3.24.0 or higher
- Dart SDK version 3.5.0 or higher
- Android Studio or VS Code with Flutter extension

## Installation and Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/darooyar.git
   ```
2. Navigate to the project directory:
   ```
   cd darooyar
   ```
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Generate Isar models:
   ```
   dart run build_runner build --delete-conflicting-outputs
   ```
5. Run the app:
   ```
   flutter run
   ```

## Project Structure

The project follows clean architecture with the following layers:

- **core**: Shared utilities and classes
  - **constants**: App constants
  - **theme**: App theme and styles
  - **utils**: Helper utilities like database service
- **features**: App modules
  - **prescription**: Main module for prescription management
    - **data**: Data layer including models and repositories
    - **domain**: Domain layer including entities
    - **presentation**: Presentation layer including screens, widgets, and providers

## API Configuration

To use the prescription analysis API, update the API endpoint in `lib/core/constants/app_constants.dart`.

## License

This project is licensed under the MIT License.
