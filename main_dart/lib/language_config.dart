import 'package:flutter/material.dart';

class LanguageNotifier extends ValueNotifier<bool> {
  // false = English, true = Urdu
  LanguageNotifier() : super(false);

  void toggle() {
    value = !value;
  }
}

final languageNotifier = LanguageNotifier();

class Translations {
  static const Map<String, Map<bool, String>> _texts = {
    // Welcome Screen
    'Welcome to FeePal': {
      false: 'Welcome to FeePal',
      true: 'فی پال میں خوش آمدید',
    },
    'Manage school payments effortlessly': {
      false: 'Manage school payments effortlessly',
      true: 'اسکول کی ادائیگیوں کو آسانی سے منظم کریں',
    },
    'Login': {false: 'Login', true: 'لاگ ان'},
    'Sign Up': {false: 'Sign Up', true: 'سائن اپ'},
    'Switch to Urdu | اردو': {
      false: 'Switch to Urdu | اردو',
      true: 'Switch to English | انگلش',
    },

    // Login Screen
    'Login as': {false: 'Login as', true: 'اس حیثیت سے لاگ ان کریں'},
    'Admin': {false: 'Admin', true: 'ایڈمن'},
    'Parent': {false: 'Parent', true: 'والدین'},
    'Email / Phone': {false: 'Email / Phone', true: 'ای میل / فون'},
    'Enter email or phone': {
      false: 'Enter email or phone',
      true: 'ای میل یا فون درج کریں',
    },
    'Password': {false: 'Password', true: 'پاس ورڈ'},
    'Forgot Password?': {false: 'Forgot Password?', true: 'پاس ورڈ بھول گئے؟'},
    "Don't have an account? ": {
      false: "Don't have an account? ",
      true: 'کیا آپ کا اکاؤنٹ نہیں ہے؟ ',
    },
    'Sign up': {false: 'Sign up', true: 'سائن اپ کریں'},

    // Sign Up Screen
    'School Name': {false: 'School Name', true: 'اسکول کا نام'},
    'Enter school name': {
      false: 'Enter school name',
      true: 'اسکول کا نام درج کریں',
    },
    'Admin Name': {false: 'Admin Name', true: 'ایڈمن کا نام'},
    'Enter your name': {false: 'Enter your name', true: 'اپنا نام درج کریں'},
    'Email': {false: 'Email', true: 'ای میل'},
    'Phone Number': {false: 'Phone Number', true: 'فون نمبر'},
    'Confirm Password': {
      false: 'Confirm Password',
      true: 'پاس ورڈ کی تصدیق کریں',
    },
    'School Code (Optional)': {
      false: 'School Code (Optional)',
      true: 'اسکول کوڈ (اختیاری)',
    },
    'Create Account': {false: 'Create Account', true: 'اکاؤنٹ بنائیں'},
    "Already have an account? ": {
      false: "Already have an account? ",
      true: 'پہلے سے ہی اکاؤنٹ ہے؟ ',
    },

    // OTP Screen
    'Verification': {false: 'Verification', true: 'تصدیق'},
    'OTP Verification': {false: 'OTP Verification', true: 'او ٹی پی تصدیق'},
    'We have sent a verification code to your registered email or phone number.': {
      false: 'We have sent a verification code to your registered email or phone number.',
      true: 'ہم نے آپ کے رجسٹرڈ ای میل یا فون نمبر پر ایک تصدیقی کوڈ بھیجا ہے۔',
    },
    'Verify Now': {false: 'Verify Now', true: 'اب تصدیق کریں'},
    "Didn't receive code? ": {
      false: "Didn't receive code? ",
      true: 'کوڈ موصول نہیں ہوا؟ ',
    },
    'Resend': {false: 'Resend', true: 'دوبارہ بھیجیں'},
    'Verification code resent!': {
      false: 'Verification code resent!',
      true: 'تصدیقی کوڈ دوبارہ بھیج دیا گیا!',
    },
    'Signup Successful!': {
      false: 'Signup Successful!',
      true: 'سائن اپ کامیاب!',
    },
    'Your account has been fully verified and created. You can now login as an Admin.': {
      false:
          'Your account has been fully verified and created. You can now login as an Admin.',
      true:
          'آپ کا اکاؤنٹ مکمل طور پر تصدیق شدہ اور بن گیا ہے۔ اب آپ ایڈمن کے طور پر لاگ ان کر سکتے ہیں۔',
    },
    'Login Now': {false: 'Login Now', true: 'اب لاگ ان کریں'},

    // Forgot Password Flow
    'Forgot Password': {false: 'Forgot Password', true: 'پاس ورڈ بھول گئے'},
    'Enter your registered email or phone number to receive a verification code.': {
      false: 'Enter your registered email or phone number to receive a verification code.',
      true: 'تصدیقی کوڈ حاصل کرنے کے لیے اپنا رجسٹرڈ ای میل یا فون نمبر درج کریں۔',
    },
    'Send OTP': {false: 'Send OTP', true: 'او ٹی پی بھیجیں'},
    'Change Password': {false: 'Change Password', true: 'پاس ورڈ تبدیل کریں'},
    'New Password': {false: 'New Password', true: 'نیا پاس ورڈ'},
    'Enter new password': {false: 'Enter new password', true: 'نیا پاس ورڈ درج کریں'},
    'Update Password': {false: 'Update Password', true: 'پاس ورڈ اپ ڈیٹ کریں'},
    'Password Changed!': {false: 'Password Changed!', true: 'پاس ورڈ تبدیل ہو گیا!'},
    'Your password has been successfully updated. You can now login.': {
      false: 'Your password has been successfully updated. You can now login.',
      true: 'آپ کا پاس ورڈ کامیابی سے اپ ڈیٹ ہو گیا ہے۔ اب آپ لاگ ان کر سکتے ہیں۔',
    },

    // Admin Dashboard
    'User homepage coming soon': {false: 'User homepage coming soon', true: 'صارف کا ہوم پیج جلد آ رہا ہے'},
    'Welcome back,': {false: 'Welcome back,', true: 'خوش آمدید،'},
    'Admin Dashboard': {false: 'Admin Dashboard', true: 'ایڈمن ڈیش بورڈ'},
    'Total Students': {false: 'Total Students', true: 'کل طلباء'},
    'Fees Collected': {false: 'Fees Collected', true: 'جمع شدہ فیس'},
    'Pending Payments': {false: 'Pending Payments', true: 'زیر التوا ادائیگیاں'},
    'Overdue': {false: 'Overdue', true: 'اوور ڈیو'},
    'Quick Actions': {false: 'Quick Actions', true: 'فوری کارروائیاں'},
    'Add Student': {false: 'Add Student', true: 'طالب علم شامل کریں'},
    'Create Fee': {false: 'Create Fee', true: 'فیس بنائیں'},
    'Send Reminder': {false: 'Send Reminder', true: 'یاد دہانی بھیجیں'},
    'Recent Activity': {false: 'Recent Activity', true: 'حالیہ سرگرمی'},
    'Payment received from Ahmed Khan': {false: 'Payment received from Ahmed Khan', true: 'احمد خان سے ادائیگی موصول ہوئی'},
    'New student added: Sara Ali': {false: 'New student added: Sara Ali', true: 'نئی طالبہ شامل کی گئی: سارہ علی'},
    'Reminder sent to 45 parents': {false: 'Reminder sent to 45 parents', true: '45 والدین کو یاد دہانی بھیجی گئی'},
    '2 hours ago': {false: '2 hours ago', true: '2 گھنٹے پہلے'},
    '5 hours ago': {false: '5 hours ago', true: '5 گھنٹے پہلے'},
    '1 day ago': {false: '1 day ago', true: '1 دن پہلے'},
    'Home': {false: 'Home', true: 'ہوم'},
    'Students': {false: 'Students', true: 'طلباء'},
    'Fees': {false: 'Fees', true: 'فیس'},
    'Alerts': {false: 'Alerts', true: 'الرٹس'},
    'Profile': {false: 'Profile', true: 'پروفائل'},
  };

  static String get(String key, bool isUrdu) {
    return _texts[key]?[isUrdu] ?? key;
  }
}
