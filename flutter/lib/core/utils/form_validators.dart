class FormValidators {
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'لطفا نام کاربری خود را وارد کنید';
    }
    if (value.length < 3) {
      return 'نام کاربری باید حداقل ۳ کاراکتر باشد';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'نام کاربری فقط می‌تواند شامل حروف انگلیسی، اعداد و _ باشد';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'لطفا ایمیل خود را وارد کنید';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'لطفا یک ایمیل معتبر وارد کنید';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'لطفا رمز عبور خود را وارد کنید';
    }
    if (value.length < 8) {
      return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(value)) {
      return 'رمز عبور باید شامل حداقل یک حرف و یک عدد باشد';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'لطفا این فیلد را پر کنید';
    }
    if (value.length < 2) {
      return 'این فیلد باید حداقل ۲ کاراکتر باشد';
    }
    return null;
  }
}
