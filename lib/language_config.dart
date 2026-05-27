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
    'School Address': {false: 'School Address', true: 'اسکول کا پتہ'},

    'School Logo': {false: 'School Logo', true: 'اسکول کا لوگو'},
    'Upload School Logo': {false: 'Upload School Logo', true: 'اسکول کا لوگو اپ لوڈ کریں'},
    'Invalid phone number format. Must start with +92.': {
      false: 'Invalid phone number format. Must start with +92.',
      true: 'فون نمبر کا فارمیٹ غلط ہے۔ +92 سے شروع ہونا چاہیے۔',
    },
    'School Information': {false: 'School Information', true: 'اسکول کی معلومات'},
    'Admin Information': {false: 'Admin Information', true: 'ایڈمن کی معلومات'},
    'Please upload school logo.': {
      false: 'Please upload school logo.',
      true: 'براہ کرم اسکول کا لوگو اپ لوڈ کریں۔',
    },
    'Enter school address': {false: 'Enter school address', true: 'اسکول کا پتہ درج کریں'},
    'Processing...': {false: 'Processing...', true: 'پروسیسنگ...'},
    'Logo uploaded successfully': {
      false: 'Logo uploaded successfully',
      true: 'لوگو کامیابی کے ساتھ اپ لوڈ ہو گیا!',
    },
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

    // Notifications
    'Important': {false: 'Important', true: 'اہم'},
    'New Fee Issued': {false: 'New Fee Issued', true: 'نئی فیس جاری کر دی گئی'},
    'A new monthly fee has been created.': {
      false: 'A new monthly fee has been created.',
      true: 'ایک نئی ماہانہ فیس تیار کی گئی ہے۔',
    },
    'Due date': {false: 'Due date', true: 'آخری تاریخ'},
    'SMS Alert': {false: 'SMS Alert', true: 'ایس ایم ایس الرٹ'},
    'Email Alert': {false: 'Email Alert', true: 'ای میل الرٹ'},
    'App Notifications': {false: 'App Notifications', true: 'ایپ نوٹیفیکیشنز'},
    'Mandatory': {false: 'Mandatory', true: 'لازمی'},
    'Select notification channels': {
      false: 'Select notification channels',
      true: 'نوٹیفیکیشن چینلز منتخب کریں',
    },
    'Downloading voucher...': {
      false: 'Downloading voucher...',
      true: 'واؤچر ڈاؤن لوڈ ہو رہا ہے...',
    },
    'Downloading...': {
      false: 'Downloading...',
      true: 'ڈاؤن لوڈ ہو رہا ہے...',
    },
    'Download Voucher': {
      false: 'Download Voucher',
      true: 'واؤچر ڈاؤن لوڈ کریں',
    },

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
      true: "پہلے سے ہی اکاؤنٹ ہے؟ ",
    },
    "Please fill in all required fields.": {
      false: "Please fill in all required fields.",
      true: "براہ کرم تمام مطلوبہ فیلڈز پُر کریں۔",
    },
    "Passwords do not match.": {
      false: "Passwords do not match.",
      true: "پاس ورڈ مماثلت نہیں رکھتے۔",
    },
    "Invalid email format.": {
      false: "Invalid email format.",
      true: "ای میل کا فارمیٹ درست نہیں ہے۔",
    },
    "Password must be at least 6 characters.": {
      false: "Password must be at least 6 characters.",
      true: "پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے۔",
    },
    "Invalid phone number.": {
      false: "Invalid phone number.",
      true: "فون نمبر درست نہیں ہے۔",
    },
    'Account Created Successfully.': {
      false: 'Account Created Successfully.',
      true: 'اکاؤنٹ کامیابی کے ساتھ بن گیا ہے۔',
    },
    'Import from Excel': {
      false: 'Import from Excel',
      true: 'ایکسل فائل سے درآمد کریں',
    },
    'Select Excel File': {
      false: 'Select Excel File',
      true: 'ایکسل فائل منتخب کریں',
    },
    'Import': {false: 'Import', true: 'درآمد کریں'},
    'Students Record imported successfully!': {
      false: 'Students Record imported successfully!',
      true: 'طلبا کا ریکارڈ کامیابی کے ساتھ درآمد کر لیا گیا!',
    },
    'Student Name': {false: 'Student Name', true: 'طالبعلم کا نام'},
    'Class': {false: 'Class', true: 'کلاس'},
    'Roll Number': {false: 'Roll Number', true: 'رول نمبر'},
    'Parent Name': {false: 'Parent Name', true: 'والد کا نام'},
    'Parent Phone': {false: 'Parent Phone', true: 'والد کا فون نمبر'},
    'Parent Email': {false: 'Parent Email', true: 'والد کا ای میل'},
    'Search Students...': {
      false: 'Search Students...',
      true: 'طلبا کو تلاش کریں...',
    },
    'Search Student by Name or Roll no': {
      false: 'Search Student by Name or Roll no',
      true: 'طالبعلم کو نام یا رول نمبر سے تلاش کریں',
    },
    'Sibling Discount (Rs.)': {
      false: 'Sibling Discount (Rs.)',
      true: 'بہن بھائیوں کی رعایت (روپے)',
    },
    'Set a global discount amount for students with siblings.': {
      false: 'Set a global discount amount for students with siblings.',
      true: 'بہن بھائیوں والے طلبا کے لیے ایک عالمی رعایتی رقم مقرر کریں۔',
    },
    'Discount Amount': {
      false: 'Discount Amount',
      true: 'رعایتی رقم',
    },
    'Picking & Parsing File...': {
      false: 'Picking & Parsing File...',
      true: 'فائل کو منتخب اور پارس کیا جا رہا ہے...',
    },
    'Edit Student': {false: 'Edit Student', true: 'طالبعلم کی معلومات تبدیل کریں'},
    'Save Changes': {false: 'Save Changes', true: 'تبدیلیاں محفوظ کریں'},
    'Delete Student': {false: 'Delete Student', true: 'طالبعلم کو ختم کریں'},
    'Fees (Rs.)': {false: 'Fees (Rs.)', true: 'فیس (روپے)'},
    'Are you sure?': {false: 'Are you sure?', true: 'کیا آپ کو یقین ہے؟'},
    'This action cannot be undone.': {
      false: 'This action cannot be undone.',
      true: 'اس عمل کو واپس نہیں لیا جا سکتا۔',
    },
    'Cancel': {false: 'Cancel', true: 'منسوخ کریں'},
    'Delete': {false: 'Delete', true: 'ختم کریں'},
    'Delete Account': {false: 'Delete Account', true: 'اکاؤنٹ حذف کریں'},
    'Are you sure you want to delete your account? This action is permanent and cannot be undone.': {
      false: 'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
      true: 'کیا آپ واقعی اپنا اکاؤنٹ حذف کرنا چاہتے ہیں؟ یہ عمل مستقل ہے اور اسے واپس نہیں لیا جا سکتا۔',
    },
    'Account Deleted Successfully': {
      false: 'Account Deleted Successfully',
      true: 'اکاؤنٹ کامیابی سے حذف ہو گیا',
    },

    // OTP Screen
    'Verification': {false: 'Verification', true: 'تصدیق'},
    'OTP Verification': {false: 'OTP Verification', true: 'او ٹی پی تصدیق'},
    'We have sent a verification code to your registered email or phone number.': {
      false:
          'We have sent a verification code to your registered email or phone number.',
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
      false:
          'Enter your registered email or phone number to receive a verification code.',
      true:
          'تصدیقی کوڈ حاصل کرنے کے لیے اپنا رجسٹرڈ ای میل یا فون نمبر درج کریں۔',
    },
    'Send OTP': {false: 'Send OTP', true: 'او ٹی پی بھیجیں'},
    'Change Password': {false: 'Change Password', true: 'پاس ورڈ تبدیل کریں'},
    'New Password': {false: 'New Password', true: 'نیا پاس ورڈ'},
    'Enter new password': {
      false: 'Enter new password',
      true: 'نیا پاس ورڈ درج کریں',
    },
    'Update Password': {false: 'Update Password', true: 'پاس ورڈ اپ ڈیٹ کریں'},
    'Password Changed!': {
      false: 'Password Changed!',
      true: 'پاس ورڈ تبدیل ہو گیا!',
    },
    'Your password has been successfully updated. You can now login.': {
      false: 'Your password has been successfully updated. You can now login.',
      true:
          'آپ کا پاس ورڈ کامیابی سے اپ ڈیٹ ہو گیا ہے۔ اب آپ لاگ ان کر سکتے ہیں۔',
    },
    'Current Password': {false: 'Current Password', true: 'موجودہ پاس ورڈ'},
    'Confirm New Password': {false: 'Confirm New Password', true: 'نئے پاس ورڈ کی تصدیق کریں'},
    'Incorrect current password.': {false: 'Incorrect current password.', true: 'موجودہ پاس ورڈ غلط ہے۔'},
    'Your new password cannot be the same as your current password.': {
      false: 'Your new password cannot be the same as your current password.',
      true: 'آپ کا نیا پاس ورڈ آپ کے موجودہ پاس ورڈ جیسا نہیں ہو سکتا۔',
    },
    'Password must be at least 6 characters long.': {
      false: 'Password must be at least 6 characters long.',
      true: 'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے۔',
    },
    'New passwords do not match. Please try again.': {
      false: 'New passwords do not match. Please try again.',
      true: 'نئے پاس ورڈ مماثلت نہیں رکھتے۔ براہ کرم دوبارہ کوشش کریں۔',
    },
    'Verify to Change Password': {
      false: 'Verify to Change Password',
      true: 'پاس ورڈ تبدیل کرنے کے لیے تصدیق کریں',
    },
    'Secure your account by updating your password.': {
      false: 'Secure your account by updating your password.',
      true: 'اپنا پاس ورڈ اپ ڈیٹ کرکے اپنے اکاؤنٹ کو محفوظ بنائیں۔',
    },
    'Wrong OTP Code': {false: 'Wrong OTP Code', true: 'غلط او ٹی پی کوڈ'},
    'Minimum 6 characters': {false: 'Minimum 6 characters', true: 'کم از کم 6 حروف'},
    'Repeat your password': {false: 'Repeat your password', true: 'اپنا پاس ورڈ دوبارہ لکھیں'},

    // Admin Dashboard
    'User homepage coming soon': {
      false: 'User homepage coming soon',
      true: 'صارف کا ہوم پیج جلد آ رہا ہے',
    },
    'Welcome back,': {false: 'Welcome back,', true: 'خوش آمدید،'},
    'Admin Dashboard': {false: 'Admin Dashboard', true: 'ایڈمن ڈیش بورڈ'},
    'Total Students': {false: 'Total Students', true: 'کل طلباء'},
    'Total Fees': {false: 'Total Fees', true: 'کل فیس'},
    'Fees Collected': {false: 'Fees Collected', true: 'جمع شدہ فیس'},
    'Pending Payments': {
      false: 'Pending Payments',
      true: 'زیر التوا ادائیگیاں',
    },
    'Overdue': {false: 'Overdue', true: 'اوور ڈیو'},
    'Quick Actions': {false: 'Quick Actions', true: 'فوری کارروائیاں'},
    'Add Student': {false: 'Add Student', true: 'طالب علم شامل کریں'},
    'Create Fee': {false: 'Create Fee', true: 'فیس بنائیں'},
    'Send Reminder': {false: 'Send Reminder', true: 'یاد دہانی بھیجیں'},
    'Recent Activity': {false: 'Recent Activity', true: 'حالیہ سرگرمی'},
    'Activity History': {false: 'Activity History', true: 'سرگرمی کی تاریخ'},
    'View All': {false: 'View All', true: 'سب دیکھیں'},
    'No activity history found': {false: 'No activity history found', true: 'کوئی سرگرمی نہیں ملی'},
    'Click back again to close the app': {
      false: 'Click back again to close the app',
      true: 'ایپ بند کرنے کے لیے دوبارہ پیچھے کلک کریں',
    },
    'Tap again to exit': {
      false: 'Tap again to exit',
      true: 'باہر نکلنے کے لیے دوبارہ کلک کریں',
    },
    'Arrears Relief (2 Installments)': {
      false: 'Arrears Relief (2 Installments)',
      true: 'بقایا جات میں ریلیف (2 اقساط)',
    },
    'Split into 2 installments': {
      false: 'Split into 2 installments',
      true: '2 اقساط میں تقسیم کریں',
    },
    'Arrears over Rs. 5000 can be split': {
      false: 'Arrears over Rs. 5000 can be split',
      true: '5000 روپے سے زیادہ کے بقایا جات کو تقسیم کیا جا سکتا ہے',
    },
    'Reset Installments': {
      false: 'Reset Installments',
      true: 'اقساط کو ری سیٹ کریں',
    },
    'Arrears Installment': {
      false: 'Arrears Installment',
      true: 'بقایا جات کی قسط',
    },
    'Installment': {
      false: 'Installment',
      true: 'قسط',
    },
    'Payment received from Ahmed Khan': {
      false: 'Payment received from Ahmed Khan',
      true: 'احمد خان سے ادائیگی موصول ہوئی',
    },
    'Subscription': {
      false: 'Subscription',
      true: 'سبسکرپشن',
    },
    'Verification in Progress': {
      false: 'Verification in Progress',
      true: 'تصدیق جاری ہے',
    },
    'FeePal Team is verifying your payment. This usually takes less than 24 hours.': {
      false: 'FeePal Team is verifying your payment. This usually takes less than 24 hours.',
      true: 'فی پال ٹیم آپ کی ادائیگی کی تصدیق کر رہی ہے۔ اس میں عام طور پر 24 گھنٹے سے بھی کم وقت لگتا ہے۔',
    },
    'Choose Your Plan': {
      false: 'Choose Your Plan',
      true: 'اپنا پلان منتخب کریں',
    },
    'Upload Payment Proof': {
      false: 'Upload Payment Proof',
      true: 'ادائیگی کا ثبوت اپ لوڈ کریں',
    },
    'Submit Proof': {
      false: 'Submit Proof',
      true: 'ثبوت جمع کروائیں',
    },
    'Congratulations!': {
      false: 'Congratulations!',
      true: 'مبارک ہو!',
    },
    'Your subscription has been successfully enabled by FeePal Team.': {
      false: 'Your subscription has been successfully enabled by FeePal Team.',
      true: 'آپ کی سبسکرپشن فی پال ٹیم کی طرف سے کامیابی کے ساتھ فعال کر دی گئی ہے۔',
    },
    'Make sure to update your bank details and school profile.': {
      false: 'Make sure to update your bank details and school profile.',
      true: 'یقینی بنائیں کہ آپ اپنے بینک کی تفصیلات اور اسکول پروفائل کو اپ ڈیٹ کرتے ہیں۔',
    },
    'Get Started': {
      false: 'Get Started',
      true: 'شروع کریں',
    },
    'Purchase Request sent successfully to FeePal Team. They will verify and enable subscription within 24 hours.': {
      false: 'Purchase Request sent successfully to FeePal Team. They will verify and enable subscription within 24 hours.',
      true: 'خریداری کی درخواست فی پال ٹیم کو کامیابی کے ساتھ بھیج دی گئی ہے۔ وہ 24 گھنٹوں کے اندر سبسکرپشن کی تصدیق اور اسے فعال کر دیں گے۔',
    },
    'Please select a plan and upload payment proof.': {
      false: 'Please select a plan and upload payment proof.',
      true: 'براہ کرم پلان منتخب کریں اور ادائیگی کا ثبوت اپ لوڈ کریں۔',
    },
    'New student added: Sara Ali': {
      false: 'New student added: Sara Ali',
      true: 'نئی طالبہ شامل کی گئی: سارہ علی',
    },
    'Reminder sent to 45 parents': {
      false: 'Reminder sent to 45 parents',
      true: '45 والدین کو یاد دہانی بھیجی گئی',
    },
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
    'Next installment due on January 15, 2026': {
      false: 'Next installment due on January 15, 2026',
      true: 'اگلی قسط 15 جنوری 2026 کو واجب الادا ہے',
    },
    'Fee Details': {false: 'Fee Details', true: 'فیس کی تفصیلات'},
    'View breakdown & installments': {
      false: 'View breakdown & installments',
      true: 'تفصیلات اور اقساط دیکھیں',
    },
    'Generate Voucher': {false: 'Generate Voucher', true: 'واؤچر بنائیں'},
    'Voucher generation & installments': {
      false: 'Voucher generation & installments',
      true: 'واؤچر کی تیاری اور اقساط',
    },
    'Get Alerts': {false: 'Get Alerts', true: 'الرٹس حاصل کریں'},
    'Alert & reminders': {
      false: 'Alert & reminders',
      true: 'الرٹس اور یاد دہانیاں',
    },
    'Recent Notifications': {
      false: 'Recent Notifications',
      true: 'حالیہ اطلاعات',
    },
    'Payment reminder: Next installment due in 35 days': {
      false: 'Payment reminder: Next installment due in 35 days',
      true: 'ادائیگی کی یاد دہانی: اگلی قسط 35 دنوں میں واجب الادا ہے',
    },
    'Payment verified: Rs. 2,500 received': {
      false: 'Payment verified: Rs. 2,500 received',
      true: 'ادائیگی کی تصدیق: 2,500 روپے موصول ہوئے',
    },
    '3 hours ago': {false: '3 hours ago', true: '3 گھنٹے پہلے'},
    'Parent Fees Coming Soon': {
      false: 'Parent Fees Coming Soon',
      true: 'والدین کی فیس جلد آ رہی ہے',
    },
    'Parent Voucher Coming Soon': {
      false: 'Parent Voucher Coming Soon',
      true: 'والدین کا واؤچر جلد آ رہا ہے',
    },
    'Parent Alerts Coming Soon': {
      false: 'Parent Alerts Coming Soon',
      true: 'والدین کے الرٹس جلد آ رہے ہیں',
    },
    'Parent Profile Coming Soon': {
      false: 'Parent Profile Coming Soon',
      true: 'والدین کی پروفائل جلد آ رہی ہے',
    },

    // Fee Details Screen
    'Academic Year 2025': {
      false: 'Academic Year 2025',
      true: 'تعلیمی سال 2025',
    },
    'Class 10': {false: 'Class 10', true: 'کلاس 10'},
    'Paid Amount': {false: 'Paid Amount', true: 'ادا شدہ رقم'},
    'Unpaid Fee': {false: 'Unpaid Fee', true: 'غیر ادا شدہ فیس'},
    'Due:': {false: 'Due:', true: 'مقررہ تاریخ:'},
    'Installment 1': {false: 'Installment 1', true: 'پہلی قسط'},
    'Installment 2': {false: 'Installment 2', true: 'دوسری قسط'},
    'Pending': {false: 'Pending', true: 'زیر التواء'},
    'No unpaid dues': {false: 'No unpaid dues', true: 'کوئی واجب الادا رقم نہیں ہے'},
    'Current Due': {false: 'Current Due', true: 'موجودہ واجب الادا'},
    'Payment History': {false: 'Payment History', true: 'ادائیگی کی تاریخ'},
    'Paid on:': {false: 'Paid on:', true: 'ادائیگی کی تاریخ:'},

    // Upload Dialog
    'Upload Voucher': {false: 'Upload Voucher', true: 'واؤچر اپ لوڈ کریں'},
    'Drag & drop your file here': {
      false: 'Drag & drop your file here',
      true: 'اپنی فائل کو یہاں لائیں اور چھوڑیں',
    },
    'Or click to browse': {
      false: 'Or click to browse',
      true: 'یا تلاش کرنے کے لیے کلک کریں',
    },
    'Support formats: PDF, JPG, PNG (Max 5MB)': {
      false: 'Support formats: PDF, JPG, PNG (Max 5MB)',
      true: 'معاون فارمیٹس: PDF، JPG، PNG (زیادہ سے زیادہ 5MB)',
    },
    'Upload': {false: 'Upload', true: 'اپ لوڈ کریں'},

    // Voucher Screen
    'Create Installments': {false: 'Create Installments', true: 'اقساط بنائیں'},
    'Select Installment': {false: 'Select Installment', true: 'قسط منتخب کریں'},

    // Alerts Screen
    'Notifications': {false: 'Notifications', true: 'اطلاعات'},
    'All': {false: 'All', true: 'تمام'},
    'Unread': {false: 'Unread', true: 'غیر پڑھے ہوئے'},
    'Reminders': {false: 'Reminders', true: 'یاد دہانیاں'},
    'Fee Alerts': {false: 'Fee Alerts', true: 'فیس الرٹس'},

    'Payment reminder': {
      false: 'Payment reminder',
      true: 'ادائیگی کی یاد دہانی',
    },
    'Your next installment of Rs. 2,500 is due on January 05, 2026': {
      false: 'Your next installment of Rs. 2,500 is due on January 05, 2026',
      true: 'آپ کی اگلی 2,500 روپے کی قسط 05 جنوری 2026 کو واجب الادا ہے',
    },

    'Payment Verified': {
      false: 'Payment Verified',
      true: 'ادائیگی کی تصدیق ہو گئی',
    },
    'Your payment of Rs. 2,500 has been verified and approved': {
      false: 'Your payment of Rs. 2,500 has been verified and approved',
      true: 'آپ کی 2,500 روپے کی ادائیگی کی تصدیق اور منظوری ہو چکی ہے',
    },

    'Payment Received': {false: 'Payment Received', true: 'ادائیگی موصول ہوئی'},
    'Your payment voucher has been received and is under verification': {
      false: 'Your payment voucher has been received and is under verification',
      true: 'آپ کا ادائیگی کا واؤچر موصول ہو گیا ہے اور تصدیق کے مراحل میں ہے',
    },

    'Due Date Approaching': {
      false: 'Due Date Approaching',
      true: 'مقررہ تاریخ قریب ہے',
    },
    'Only 5 days left until your payment due date': {
      false: 'Only 5 days left until your payment due date',
      true: 'آپ کی ادائیگی کی مقررہ تاریخ میں صرف 5 دن باقی ہیں',
    },

    'Fee Structure Updated': {
      false: 'Fee Structure Updated',
      true: 'فیس ڈھانچہ اپ ڈیٹ ہو گیا',
    },
    'New fee structure for next semester has been released': {
      false: 'New fee structure for next semester has been released',
      true: 'اگلے سمسٹر کے لیے نیا فیس ڈھانچہ جاری کر دیا گیا ہے',
    },

    'Mark All as Read': {
      false: 'Mark All as Read',
      true: 'سب کو پڑھا ہوا نشان زد کریں',
    },
    '9 days ago': {false: '9 days ago', true: '9 دن پہلے'},
    '8 hours ago': {false: '8 hours ago', true: '8 گھنٹے پہلے'},

    // Profile Screen
    'Profile & Settings': {
      false: 'Profile & Settings',
      true: 'پروفائل اور ترتیبات',
    },
    'Ali Muhammad': {false: 'Ali Muhammad', true: 'علی محمد'},
    'Parent Account': {false: 'Parent Account', true: 'والدین کا اکاؤنٹ'},
    'Parent Information': {
      false: 'Parent Information',
      true: 'والدین کی معلومات',
    },
    'Name': {false: 'Name', true: 'نام'},
    'Phone': {false: 'Phone', true: 'فون'},
    'Student Information': {
      false: 'Student Information',
      true: 'طالب علم کی معلومات',
    },
    'Roll No': {false: 'Roll No', true: 'رول نمبر'},
    'Settings': {false: 'Settings', true: 'ترتیبات'},
    'Language': {false: 'Language', true: 'زبان'},
    'English': {false: 'English', true: 'انگریزی'},
    'Notification Preferences': {
      false: 'Notification Preferences',
      true: 'اطلاعات کی ترجیحات',
    },
    'Help & Support': {false: 'Help & Support', true: 'مدد اور تعاون'},
    'FAQ': {false: 'FAQ', true: 'اکثر پوچھے گئے سوالات'},
    'Contact Support': {false: 'Contact Support', true: 'سپورٹ سے رابطہ کریں'},
    'Upload Proof': {false: 'Upload Proof', true: 'ثبوت اپ لوڈ کریں'},
    'Fee': {false: 'Fee', true: 'فیس'},
    'Processing payment proof...': {false: 'Processing payment proof...', true: 'ادائیگی کے ثبوت پر کارروائی ہو رہی ہے...'},
    'AI is validating your voucher...': {false: 'AI is validating your voucher...', true: 'مصنوعی ذہانت آپ کے واؤچر کی تصدیق کر رہی ہے...'},
    'Voucher validated! Fee marked as Paid.': {false: 'Voucher validated! Fee marked as Paid.', true: 'واؤچر کی تصدیق ہوگئی! فیس ادا شدہ نشان زد کر دی گئی۔'},
    'Terms & Conditions': {false: 'Terms & Conditions', true: 'شرائط و ضوابط'},
    'Edit Fee Template': {false: 'Edit Fee Template', true: 'فیس ٹیمپلیٹ میں ترمیم کریں'},
    'Update Template': {false: 'Update Template', true: 'ٹیمپلیٹ اپ ڈیٹ کریں'},
    'Delete Fee Template': {false: 'Delete Fee Template', true: 'فیس ٹیمپلیٹ ختم کریں'},
    'Are you sure? This will also remove vouchers for all students in this class.': {
      false: 'Are you sure? This will also remove vouchers for all students in this class.',
      true: 'کیا آپ کو یقین ہے؟ اس سے اس کلاس کے تمام طلباء کے واؤچر بھی ختم ہو جائیں گے۔',
    },
    'Fee template deleted successfully': {
      false: 'Fee template deleted successfully',
      true: 'فیس ٹیمپلیٹ کامیابی کے ساتھ ختم کر دیا گیا',
    },
    'Edit': {false: 'Edit', true: 'ترمیم'},
    'Update': {false: 'Update', true: 'اپ ڈیٹ'},
    'Select Class': {false: 'Select Class', true: 'کلاس منتخب کریں'},
    'Base Fee': {false: 'Base Fee', true: 'بنیادی فیس'},
    'Additional Charges': {false: 'Additional Charges', true: 'اضافی چارجز'},
    'Late Penalty': {false: 'Late Penalty', true: 'لیٹ جرمانہ'},
    'Sibling Discount (%)': {false: 'Sibling Discount (%)', true: 'بہن بھائی ڈسکاؤنٹ (%)'},
    'Save Template': {false: 'Save Template', true: 'ٹیمپلیٹ محفوظ کریں'},
    'Issued for': {false: 'Issued for', true: 'کے لیے جاری کیا گیا'},
    'Are you sure you want to logout?': {
      false: 'Are you sure you want to logout?',
      true: 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟',
    },
    'Fee templates duplication is not allowed': {
      false: 'Fee templates duplication is not allowed',
      true: 'فیس ٹیمپلیٹس کی نقل کی اجازت نہیں ہے',
    },
    'Verify OTP': {false: 'Verify OTP', true: 'او ٹی پی تصدیق کریں'},
    'Verify Email': {false: 'Verify Email', true: 'ای میل کی تصدیق کریں'},
    'Please enter the 6-digit code sent to ': {
      false: 'Please enter the 6-digit code sent to ',
      true: 'براہ کرم اس ای میل پر بھیجا گیا 6 ہندسوں کا کوڈ درج کریں: ',
    },
    'Resend in': {false: 'Resend in', true: 'دوبارہ بھیجیں: '},
    'Didn\'t receive the code? ': {
      false: 'Didn\'t receive the code? ',
      true: 'کوڈ موصول نہیں ہوا؟ ',
    },
    'Parent Password': {false: 'Parent Password', true: 'والدین کا پاس ورڈ'},
    'Reset Password?': {false: 'Reset Password?', true: 'پاس ورڈ ری سیٹ کریں؟'},
    'This will generate a new random password for the parent. You must save changes to apply it.': {
      false: 'This will generate a new random password for the parent. You must save changes to apply it.',
      true: 'یہ والدین کے لیے ایک نیا بے ترتیب پاس ورڈ تیار کرے گا۔ اسے لاگو کرنے کے لیے آپ کو تبدیلیاں محفوظ کرنی ہوں گی۔',
    },
    'Regenerate': {false: 'Regenerate', true: 'دوبارہ بنائیں'},
    'Reset to Change': {false: 'Reset to Change', true: 'تبدیل کرنے کے لیے ری سیٹ کریں'},
    'Academic Year': {
      false: 'Academic Year',
      true: 'تعلیمی سال',
    },
    'Note: A Late Fee Penalty of Rs.': {
      false: 'Note: A Late Fee Penalty of Rs.',
      true: 'نوٹ: لیٹ فیس جرمانہ مبلغ ',
    },
    'has been added to your voucher.': {
      false: 'has been added to your voucher.',
      true: 'روپے آپ کے واؤچر میں شامل کر دیا گیا ہے۔',
    },
    'About Us': {false: 'About Us', true: 'ہمارے بارے میں'},
    'Contact Us': {false: 'Contact Us', true: 'ہم سے رابطہ کریں'},
    'Business Inquiries': {false: 'Business Inquiries', true: 'کاروباری پوچھ گچھ'},
    'Call / WhatsApp': {false: 'Call / WhatsApp', true: 'کال / واٹس ایپ'},
    'About FeePal': {false: 'About FeePal', true: 'فی پال کے بارے میں'},
    'FeePal Introduction': {
      false: 'FeePal is a comprehensive student management and fee automation platform designed to streamline school operations. We provide a secure, efficient way for administrators to manage records and for parents to handle fee payments seamlessly.',
      true: 'فی پال ایک جامع اسٹوڈنٹ مینجمنٹ اور فیس آٹومیشن پلیٹ فارم ہے جو اسکول کے معاملات کو آسان بنانے کے لیے ڈیزائن کیا گیا ہے۔ ہم ایڈمنسٹریٹرز کے لیے ریکارڈ مینیج کرنے اور والدین کے لیے فیس کی ادائیگیوں کو بغیر کسی دشواری کے ہینڈل کرنے کا ایک محفوظ اور موثر طریقہ فراہم کرتے ہیں۔',
    },
    'Send SMS Alert': {
      false: 'Send SMS Alert',
      true: 'ایس ایم ایس الرٹ بھیجیں',
    },
    'SMS prioritized over Email': {
      false: 'SMS prioritized over Email',
      true: 'ایس ایم ایس کو ای میل پر ترجیح دی گئی ہے',
    },
    'Email Alert active by default': {
      false: 'Email Alert active by default',
      true: 'ای میل الرٹ بطور ڈیفالٹ فعال ہے',
    },
    'Priority parents will be reminded twice in a week.': {
      false: 'Priority parents will be reminded twice in a week.',
      true: 'ترجیحی والدین کو ہفتے میں دو بار یاد دہانی کرائی جائے گی۔',
    },
    'Please set a valid future due date. Default (10th) has passed.': {
      false: 'Please set a valid future due date. Default (10th) has passed.',
      true: 'براہ کرم مستقبل کی درست تاریخ منتخب کریں۔ ڈیفالٹ (10 تاریخ) گزر چکی ہے۔',
    },
    'Standard': {false: 'Standard', true: 'اسٹینڈرڈ'},
    'Priority': {false: 'Priority', true: 'ترجیحی'},
    'Due date cannot be in the past': {
      false: 'Due date cannot be in the past',
      true: 'آخری تاریخ ماضی میں نہیں ہو سکتی',
    },
    'You must enter base fee.': {
      false: 'You must enter base fee.',
      true: 'آپ کو بنیادی فیس درج کرنی ہوگی۔',
    },
    'New Monthly Fee Template has been created and issued to all students.': {
      false: 'New Monthly Fee Template has been created and issued to all students.',
      true: 'نئی ماہانہ فیس کا ٹیمپلیٹ تیار کر لیا گیا ہے اور تمام طلباء کو جاری کر دیا گیا ہے۔',
    },
    'Success!': {false: 'Success!', true: 'کامیابی!'},
    'Deleted!': {false: 'Deleted!', true: 'حذف کر دیا گیا!'},
    'Status': {false: 'Status', true: 'اسٹیٹس'},
    'Annual': {false: 'Annual', true: 'سالانہ'},
    'Your record is up to date. No pending months found for the current period.': {
      false: 'Your record is up to date. No pending months found for the current period.',
      true: 'آپ کا ریکارڈ اپ ٹو ڈیٹ ہے۔ موجودہ مدت کے لیے کوئی زیر التوا مہینے نہیں ملے۔',
    },
    'Pending Months': {false: 'Pending Months', true: 'زیر التوا مہینے'},
    'Unpaid': {false: 'Unpaid', true: 'غیر ادا شدہ'},
    'The email and password you used to sign up, they can be used to log back in to continue purchasing the subscription': {
      false: 'The email and password you used to sign up, they can be used to log back in to continue purchasing the subscription',
      true: 'وہ ای میل اور پاس ورڈ جو آپ نے سائن اپ کرنے کے لیے استعمال کیا تھا، انہیں دوبارہ لاگ ان کرنے اور سبسکرپشن کی خریداری جاری رکھنے کے لیے استعمال کیا جا سکتا ہے۔',
    },
    'Logout': {false: 'Logout', true: 'لاگ آؤٹ'},
  };

  static String get(String key, bool isUrdu) {
    return _texts[key]?[isUrdu] ?? key;
  }
}
