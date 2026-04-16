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

    // Parent Dashboard
    'Voucher': {false: 'Voucher', true: 'واؤچر'},
    'Welcome,': {false: 'Welcome,', true: 'خوش آمدید،'},
    'Parent Portal': {false: 'Parent Portal', true: 'والدین کا پورٹل'},
    'Current Month': {false: 'Current Month', true: 'موجودہ مہینہ'},
    'Total Fee': {false: 'Total Fee', true: 'کل فیس'},
    'Paid': {false: 'Paid', true: 'ادا شدہ'},
    'Remaining': {false: 'Remaining', true: 'باقی'},
    'Payment Due': {false: 'Payment Due', true: 'ادائیگی باقی ہے'},
    'Next installment due on January 15, 2026': {false: 'Next installment due on January 15, 2026', true: 'اگلی قسط 15 جنوری 2026 کو واجب الادا ہے'},
    'Fee Details': {false: 'Fee Details', true: 'فیس کی تفصیلات'},
    'View breakdown & installments': {false: 'View breakdown & installments', true: 'تفصیلات اور اقساط دیکھیں'},
    'Generate Voucher': {false: 'Generate Voucher', true: 'واؤچر بنائیں'},
    'Voucher generation & installments': {false: 'Voucher generation & installments', true: 'واؤچر کی تیاری اور اقساط'},
    'Get Alerts': {false: 'Get Alerts', true: 'الرٹس حاصل کریں'},
    'Alert & reminders': {false: 'Alert & reminders', true: 'الرٹس اور یاد دہانیاں'},
    'Recent Notifications': {false: 'Recent Notifications', true: 'حالیہ اطلاعات'},
    'Payment reminder: Next installment due in 35 days': {false: 'Payment reminder: Next installment due in 35 days', true: 'ادائیگی کی یاد دہانی: اگلی قسط 35 دنوں میں واجب الادا ہے'},
    'Payment verified: Rs. 2,500 received': {false: 'Payment verified: Rs. 2,500 received', true: 'ادائیگی کی تصدیق: 2,500 روپے موصول ہوئے'},
    '3 hours ago': {false: '3 hours ago', true: '3 گھنٹے پہلے'},
    'Parent Fees Coming Soon': {false: 'Parent Fees Coming Soon', true: 'والدین کی فیس جلد آ رہی ہے'},
    'Parent Voucher Coming Soon': {false: 'Parent Voucher Coming Soon', true: 'والدین کا واؤچر جلد آ رہا ہے'},
    'Parent Alerts Coming Soon': {false: 'Parent Alerts Coming Soon', true: 'والدین کے الرٹس جلد آ رہے ہیں'},
    'Parent Profile Coming Soon': {false: 'Parent Profile Coming Soon', true: 'والدین کی پروفائل جلد آ رہی ہے'},
    
    // Fee Details Screen
    'Academic Year 2025': {false: 'Academic Year 2025', true: 'تعلیمی سال 2025'},
    'Class 10': {false: 'Class 10', true: 'کلاس 10'},
    'Paid Amount': {false: 'Paid Amount', true: 'ادا شدہ رقم'},
    'Unpaid Fee': {false: 'Unpaid Fee', true: 'غیر ادا شدہ فیس'},
    'Due:': {false: 'Due:', true: 'مقررہ تاریخ:'},
    'Installment 1': {false: 'Installment 1', true: 'پہلی قسط'},
    'Installment 2': {false: 'Installment 2', true: 'دوسری قسط'},
    'Pending': {false: 'Pending', true: 'زیر التواء'},
    'Upload Payment Proof': {false: 'Upload Payment Proof', true: 'ادائیگی کا ثبوت اپ لوڈ کریں'},
    'Payment History': {false: 'Payment History', true: 'ادائیگی کی تاریخ'},
    'Paid on:': {false: 'Paid on:', true: 'ادائیگی کی تاریخ:'},
    
    // Upload Dialog
    'Upload Voucher': {false: 'Upload Voucher', true: 'واؤچر اپ لوڈ کریں'},
    'Drag & drop your file here': {false: 'Drag & drop your file here', true: 'اپنی فائل کو یہاں لائیں اور چھوڑیں'},
    'Or click to browse': {false: 'Or click to browse', true: 'یا تلاش کرنے کے لیے کلک کریں'},
    'Support formats: PDF, JPG, PNG (Max 5MB)': {false: 'Support formats: PDF, JPG, PNG (Max 5MB)', true: 'معاون فارمیٹس: PDF، JPG، PNG (زیادہ سے زیادہ 5MB)'},
    'Upload': {false: 'Upload', true: 'اپ لوڈ کریں'},
    
    // Voucher Screen
    'Student Name': {false: 'Student Name', true: 'طالب علم کا نام'},
    'Class': {false: 'Class', true: 'کلاس'},
    'Zain Muhammad': {false: 'Zain Muhammad', true: 'زین محمد'},
    'Create Installments': {false: 'Create Installments', true: 'اقساط بنائیں'},
    'Select Installment': {false: 'Select Installment', true: 'قسط منتخب کریں'},

    // Alerts Screen
    'Notifications': {false: 'Notifications', true: 'اطلاعات'},
    'All': {false: 'All', true: 'تمام'},
    'Unread': {false: 'Unread', true: 'غیر پڑھے ہوئے'},
    'Reminders': {false: 'Reminders', true: 'یاد دہانیاں'},
    
    'Payment reminder': {false: 'Payment reminder', true: 'ادائیگی کی یاد دہانی'},
    'Your next installment of Rs. 2,500 is due on January 05, 2026': {false: 'Your next installment of Rs. 2,500 is due on January 05, 2026', true: 'آپ کی اگلی 2,500 روپے کی قسط 05 جنوری 2026 کو واجب الادا ہے'},
    
    'Payment Verified': {false: 'Payment Verified', true: 'ادائیگی کی تصدیق ہو گئی'},
    'Your payment of Rs. 2,500 has been verified and approved': {false: 'Your payment of Rs. 2,500 has been verified and approved', true: 'آپ کی 2,500 روپے کی ادائیگی کی تصدیق اور منظوری ہو چکی ہے'},
    
    'Payment Received': {false: 'Payment Received', true: 'ادائیگی موصول ہوئی'},
    'Your payment voucher has been received and is under verification': {false: 'Your payment voucher has been received and is under verification', true: 'آپ کا ادائیگی کا واؤچر موصول ہو گیا ہے اور تصدیق کے مراحل میں ہے'},
    
    'Due Date Approaching': {false: 'Due Date Approaching', true: 'مقررہ تاریخ قریب ہے'},
    'Only 5 days left until your payment due date': {false: 'Only 5 days left until your payment due date', true: 'آپ کی ادائیگی کی مقررہ تاریخ میں صرف 5 دن باقی ہیں'},
    
    'Fee Structure Updated': {false: 'Fee Structure Updated', true: 'فیس ڈھانچہ اپ ڈیٹ ہو گیا'},
    'New fee structure for next semester has been released': {false: 'New fee structure for next semester has been released', true: 'اگلے سمسٹر کے لیے نیا فیس ڈھانچہ جاری کر دیا گیا ہے'},
    
    'Mark All as Read': {false: 'Mark All as Read', true: 'سب کو پڑھا ہوا نشان زد کریں'},
    '9 days ago': {false: '9 days ago', true: '9 دن پہلے'},
    '8 hours ago': {false: '8 hours ago', true: '8 گھنٹے پہلے'},
    
    // Profile Screen
    'Profile & Settings': {false: 'Profile & Settings', true: 'پروفائل اور ترتیبات'},
    'Ali Muhammad': {false: 'Ali Muhammad', true: 'علی محمد'},
    'Parent Account': {false: 'Parent Account', true: 'والدین کا اکاؤنٹ'},
    'Parent Information': {false: 'Parent Information', true: 'والدین کی معلومات'},
    'Name': {false: 'Name', true: 'نام'},
    'Phone': {false: 'Phone', true: 'فون'},
    'Student Information': {false: 'Student Information', true: 'طالب علم کی معلومات'},
    'Roll No': {false: 'Roll No', true: 'رول نمبر'},
    'Settings': {false: 'Settings', true: 'ترتیبات'},
    'Language': {false: 'Language', true: 'زبان'},
    'English': {false: 'English', true: 'انگریزی'},
    'Notification Preferences': {false: 'Notification Preferences', true: 'اطلاعات کی ترجیحات'},
    'Help & Support': {false: 'Help & Support', true: 'مدد اور تعاون'},
    'FAQ': {false: 'FAQ', true: 'اکثر پوچھے گئے سوالات'},
    'Contact Support': {false: 'Contact Support', true: 'سپورٹ سے رابطہ کریں'},
    'Terms & Conditions': {false: 'Terms & Conditions', true: 'شرائط و ضوابط'},
  };

  static String get(String key, bool isUrdu) {
    return _texts[key]?[isUrdu] ?? key;
  }
}
