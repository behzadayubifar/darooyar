class ErrorMessages {
  static String getAuthError(String error) {
    final lowerError = error.toLowerCase();
    switch (lowerError) {
      case 'invalid credentials':
        return 'نام کاربری یا رمز عبور اشتباه است';
      case 'user not found':
        return 'کاربری با این مشخصات یافت نشد';
      case 'email already exists':
        return 'این ایمیل قبلاً ثبت شده است';
      case 'username already exists':
        return 'این نام کاربری قبلاً ثبت شده است';
      case 'invalid email format':
        return 'فرمت ایمیل نامعتبر است';
      case 'password too weak':
        return 'رمز عبور باید حداقل ۸ کاراکتر و شامل حروف و اعداد باشد';
      case 'wrong password':
      case 'incorrect password':
        return 'رمز عبور اشتباه است';
      case 'unauthorized':
      case 'not authorized':
        return 'دسترسی غیر مجاز. لطفاً دوباره وارد شوید';
      case 'server returned an invalid response':
        return 'خطا در ارتباط با سرور. لطفاً دوباره تلاش کنید';
      case 'error creating user':
        return 'خطا در ایجاد حساب کاربری. لطفاً با مدیر سیستم تماس بگیرید';
      case 'failed to register':
        return 'خطا در ثبت نام. لطفاً دوباره تلاش کنید';
      case 'network error':
      case 'failed to connect to the server':
      case 'connection refused':
        return 'خطا در اتصال به سرور. لطفاً از اتصال اینترنت خود مطمئن شوید';
      case 'invalid server response':
      case 'invalid server response format':
        return 'خطا در پاسخ سرور. لطفاً دوباره تلاش کنید';
      default:
        if (lowerError.contains('socketexception')) {
          return 'خطا در اتصال به سرور. لطفاً از اتصال اینترنت خود مطمئن شوید';
        }
        if (lowerError.contains('timeout')) {
          return 'زمان پاسخگویی سرور به پایان رسید. لطفاً دوباره تلاش کنید';
        }
        return 'خطایی رخ داد: $error';
    }
  }
}
