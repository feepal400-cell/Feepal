import docx
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

doc = docx.Document()

# Title
title = doc.add_heading('APPENDIX B: User Manual', level=1)
title.alignment = WD_ALIGN_PARAGRAPH.CENTER

doc.add_heading('FeePal User Manual Table of Contents', level=3)

toc_items = [
    'Introduction',
    'Intended Users',
    'System Requirements',
    '    Hardware Requirements',
    '    Software Requirements',
    'Application Installation',
    'User Registration and Login',
    '    Registration Process',
    '    Login Procedure',
    'Dashboard Overview',
    'Fee Management Module Usage',
    '    Fee Template Creation & Rollover',
    '    Viewing Fee Vouchers',
    'Local OCR Verification Module',
    '    Scanning Bank Receipts',
    '    Processing & Validation Rules',
    '    Real-time Status Syncing',
    'Manual Review and Approvals',
    'Notifications and Alerts',
    'Data Security and Privacy',
    'Troubleshooting',
    'Logout Procedure',
    'Conclusion'
]

for item in toc_items:
    doc.add_paragraph(item, style='List Paragraph')

doc.add_page_break()

# Detailed Sections

# 1. Introduction
doc.add_paragraph('Introduction', style='Heading 2')
doc.add_paragraph('Welcome to the FeePal User Manual. FeePal is a comprehensive digital solution engineered to streamline school fee management, automated voucher generation, and secure payment tracking. This manual provides an in-depth, step-by-step guide designed to help users fully leverage the system. FeePal eliminates manual data entry bottlenecks by integrating intelligent automation, offline capabilities, and advanced on-device receipt scanning to provide a seamless financial management experience for both educational institutions and families.')

# 2. Intended Users
doc.add_paragraph('Intended Users', style='Heading 2')
doc.add_paragraph('FeePal is designed with two primary user workflows in mind:')
doc.add_paragraph('1. School Administrators (Admins): Individuals responsible for configuring the school\'s financial structure, establishing fee templates, overseeing student enrollment, and verifying monthly fee collections.', style='List Bullet')
doc.add_paragraph('2. Parents: Guardians responsible for reviewing their child\'s monthly fee statements, uploading proof of payment, and keeping track of paid and outstanding dues across academic terms.', style='List Bullet')

# 3. System Requirements
doc.add_paragraph('System Requirements', style='Heading 2')
doc.add_paragraph('Hardware Requirements', style='Heading 3')
doc.add_paragraph('• Mobile Device: Smartphone or tablet with an integrated camera (minimum 5 Megapixels) for OCR receipt scanning.', style='List Bullet')
doc.add_paragraph('• Memory (RAM): Minimum 2GB RAM required for smooth ML Kit processing.', style='List Bullet')
doc.add_paragraph('• Storage: At least 100MB of free storage for app installation and localized data caching.', style='List Bullet')

doc.add_paragraph('Software Requirements', style='Heading 3')
doc.add_paragraph('• Operating System: Android 7.0 (Nougat) or newer.', style='List Bullet')
doc.add_paragraph('• Internet Connection: Active internet connection (Wi-Fi or Cellular) is required for real-time synchronization, though the app provides offline persistence for viewing previously loaded data.', style='List Bullet')

# 4. Application Installation
doc.add_paragraph('Application Installation', style='Heading 2')
doc.add_paragraph('1. Navigate to the Google Play Store or Apple App Store on your device.', style='List Number')
doc.add_paragraph('2. Search for "FeePal" in the search bar.', style='List Number')
doc.add_paragraph('3. Tap "Install" and grant the necessary permissions (Camera access is strictly required for the OCR Verification Module).', style='List Number')
doc.add_paragraph('4. Once installed, tap the FeePal icon on your home screen to launch the application.', style='List Number')

# 5. User Registration and Login
doc.add_paragraph('User Registration and Login', style='Heading 2')
doc.add_paragraph('Registration Process', style='Heading 3')
doc.add_paragraph('• Admin Registration: Admins can register their institution directly through the app\'s sign-up portal by providing their institutional details, phone number, and a secure password. Upon registration, their account is initialized in the Firestore database.', style='List Bullet')
doc.add_paragraph('• Parent Registration: Parents do not manually sign up. Instead, their accounts are automatically provisioned by the School Admin through the student management portal. Parents will receive their initial login credentials (phone number and auto-generated password) from the school administration.', style='List Bullet')

doc.add_paragraph('Login Procedure', style='Heading 3')
doc.add_paragraph('• Seamless Phone Authentication: FeePal utilizes a robust, custom secure Firestore document lookup system for Parent logins rather than standard Firebase Auth. Users enter their registered phone number (e.g., 03001234567) and password. The system automatically formats the number internally (e.g., +92 300 1234567) to match database records exactly.', style='List Bullet')
doc.add_paragraph('• Role Selection: Users must toggle between the "Admin" or "Parent" login option before submitting their credentials. The system will securely query the respective collections to validate access.', style='List Bullet')

# 6. Dashboard Overview
doc.add_paragraph('Dashboard Overview', style='Heading 2')
doc.add_paragraph('• Admin Dashboard: Provides a high-level statistical overview of the institution\'s finances, including Total Collected Fees, Pending Dues, and active student counts. It features quick-access navigation to Manage Students, Manage Fee Templates, and Review Receipts.', style='List Bullet')
doc.add_paragraph('• Parent Dashboard: Displays immediate, actionable items for the parent, including the current month\'s outstanding fee voucher, rolled-over arrears, and a history of previously verified payments.', style='List Bullet')

# 7. Fee Management Module Usage
doc.add_paragraph('Fee Management Module Usage', style='Heading 2')
doc.add_paragraph('Fee Template Creation & Rollover', style='Heading 3')
doc.add_paragraph('Admins create foundational Fee Templates for specific classes or groups. These templates establish base tuition, transportation fees, and default due dates. When a new month begins, FeePal\'s automated Rollover Engine seamlessly duplicates the previous month\'s templates into the new month. Any updates an Admin makes to the template (e.g., raising tuition due to inflation) are automatically applied to all future rolled-over vouchers without requiring manual data entry.')

doc.add_paragraph('Viewing Fee Vouchers', style='Heading 3')
doc.add_paragraph('Parents can navigate to the Vouchers screen to view detailed breakdowns of their monthly dues. The voucher transparently lists the base fee, added charges, applicable discounts, and the absolute due date. Crucially, if a parent missed the previous month\'s payment, that unpaid balance automatically rolls over into the current month as "Arrears," ensuring accurate accounting.')

# 8. Local OCR Verification Module
doc.add_paragraph('Local OCR Verification Module', style='Heading 2')
doc.add_paragraph('FeePal replaces manual data entry with an advanced Local Optical Character Recognition (OCR) Verification System, powered by Google ML Kit, designed specifically for processing physical bank receipts.')
doc.add_paragraph('Scanning Bank Receipts', style='Heading 3')
doc.add_paragraph('When a parent successfully pays their fee at an affiliated bank, they select the unpaid voucher in the app and tap "Upload Receipt". The device camera activates, allowing the parent to capture a clear, well-lit photo of the stamped receipt.')
doc.add_paragraph('Processing & Validation Rules', style='Heading 3')
doc.add_paragraph('To ensure maximum privacy and speed, the image is never sent to a third-party server for text extraction; all text recognition happens locally on the parent\'s device. The ML algorithm scans the image for specific validation keywords, including bank identifiers, transaction IDs, specific dates, and payment amounts.')
doc.add_paragraph('Real-time Status Syncing', style='Heading 3')
doc.add_paragraph('If the ML Kit successfully identifies the required bank stamps and a valid transaction ID, the system instantly uploads the proof image to Firebase Storage and updates the voucher\'s status to "Paid/Verified" in Firestore. This status change is instantly reflected in the Admin\'s dashboard via real-time data streams.')

# 9. Manual Review and Approvals
doc.add_paragraph('Manual Review and Approvals', style='Heading 2')
doc.add_paragraph('While the OCR system automates most verifications, Admins retain full control through the Manual Review module. If a parent uploads a receipt that is too blurry, torn, or faded for the OCR to read, it flags the receipt as "Pending Verification". The Admin can manually view the uploaded receipt image, cross-reference their bank statements, and manually override the status to "Paid" or "Rejected" with a single tap.')

# 10. Notifications and Alerts
doc.add_paragraph('Notifications and Alerts', style='Heading 2')
doc.add_paragraph('FeePal utilizes a multi-channel automated communication strategy. Important events—such as an Admin generating a new fee voucher, a payment being successfully verified, or a direct message being sent via the In-App Chat Module—automatically trigger:')
doc.add_paragraph('• In-App visual alerts.', style='List Bullet')
doc.add_paragraph('• Push Notifications via Firebase Cloud Messaging (FCM).', style='List Bullet')
doc.add_paragraph('• Email Notifications (if configured by the user).', style='List Bullet')
doc.add_paragraph('For Support, users can reach the FeePal team at feepal400@gmail.com or via WhatsApp at +92 313 4469206.')

# 11. Data Security and Privacy
doc.add_paragraph('Data Security and Privacy', style='Heading 2')
doc.add_paragraph('FeePal prioritizes user data integrity. Passwords are securely hashed, and direct database access is heavily guarded by Firestore Security Rules. The Local OCR system guarantees that sensitive financial documents are processed exclusively on the user\'s local hardware, only uploading the finalized image payload to secure Google Cloud Storage buckets once explicitly authorized.')

# 12. Troubleshooting
doc.add_paragraph('Troubleshooting', style='Heading 2')

def add_table(doc, headers, rows):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = 'Table Grid'
    hdr_cells = table.rows[0].cells
    for i, header in enumerate(headers):
        hdr_cells[i].text = header
        hdr_cells[i].paragraphs[0].runs[0].bold = True
    for row_data in rows:
        row_cells = table.add_row().cells
        for i, text in enumerate(row_data):
            row_cells[i].text = text
    doc.add_paragraph('')

add_table(doc, ['Category', 'Issue / Error State', 'Resolution'], [
    ['Authentication', 'Lookup failure / User Not Found', 'Ensure the phone number is entered correctly. The app supports spaced and unspaced inputs. Verify registration status with the Admin.'],
    ['Authentication', 'Incorrect Password', 'Parents cannot reset passwords directly for security reasons; contact the Admin for a password reset.'],
    ['OCR System', 'Receipt Not Recognized', 'Ensure the receipt is flat, well-lit, and the bank stamp is clearly visible. Retake the photo.'],
    ['OCR System', 'Transaction ID Mismatch', 'If the OCR misreads characters (e.g., confusing O and 0), submit the image anyway; the Admin will process it via Manual Review.'],
    ['Connectivity', 'Data Not Syncing / Vouchers Not Loading', 'Ensure you have an active Wi-Fi or Cellular connection. Restart the app to force a Firestore resync.'],
])

# 13. Logout Procedure
doc.add_paragraph('Logout Procedure', style='Heading 2')
doc.add_paragraph('To securely exit your session:')
doc.add_paragraph('1. Navigate to the App Drawer or Profile Settings menu located at the top right of the dashboard.', style='List Number')
doc.add_paragraph('2. Scroll to the bottom of the menu and select "Logout".', style='List Number')
doc.add_paragraph('3. Confirm the prompt. The system will clear your localized session data, detach the FCM push notification token to prevent unwanted alerts, and return you to the primary Login Screen.', style='List Number')

# 14. Conclusion
doc.add_paragraph('Conclusion', style='Heading 2')
doc.add_paragraph('FeePal represents a modern leap forward in institutional financial management. By adhering to the procedures outlined in this manual, both Administrators and Parents can enjoy a transparent, efficient, and error-free fee management cycle. We continually strive to update and refine the platform, ensuring your experience remains state-of-the-art. Thank you for choosing FeePal.')

doc.save('user_manual_feepal_v2.docx')
print('Detailed User manual successfully created at user_manual_feepal_v2.docx.')
