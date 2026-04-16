import 'dart:ui';
import 'package:flutter/material.dart';
import 'language_config.dart';
import 'navigation_helper.dart';
import 'parent_dashboard_screen.dart';
import 'parent_voucher_screen.dart';
import 'parent_alerts_screen.dart';
import 'parent_profile_screen.dart';

class ParentFeesScreen extends StatelessWidget {
  const ParentFeesScreen({super.key});

  Widget _buildStatusBadge(String text, Color color, Color bgColor, bool isUrdu) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        Translations.get(text, isUrdu),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInstallmentPill(String text, bool isUrdu) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA), // Light cyan bg
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        Translations.get(text, isUrdu),
        style: const TextStyle(
          color: Color(0xFF0097A7), // Darker cyan text
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, bool isUrdu) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Translations.get('Upload Voucher', isUrdu),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.black54, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  // Upload dropzone
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(Translations.get('File picker would open here', isUrdu)),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    child: CustomPaint(
                      painter: DashedRectPainter(
                        color: const Color(0xFFBDBDBD),
                        strokeWidth: 1.5,
                        gap: 6.0,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.upload_file,
                              size: 50,
                              color: Color(0xFF9E9E9E),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              Translations.get('Drag & drop your file here', isUrdu),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              Translations.get('Or click to browse', isUrdu),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              Translations.get('Support formats: PDF, JPG, PNG (Max 5MB)', isUrdu),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(Translations.get('Upload simulated successfully!', isUrdu)),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        Translations.get('Upload', isUrdu),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isUrdu, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Block with Gradient Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF009BCB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Header Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                            child: Row(
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  Translations.get('Fee Details', isUrdu),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Summary Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row 1
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Translations.get('Academic Year 2025', isUrdu),
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      Translations.get('Total Fee', isUrdu),
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                // Row 2
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Translations.get('Class 10', isUrdu),
                                      style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'Rs. 5,000',
                                      style: TextStyle(color: Color(0xFF009BCB), fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // Row 3 (Current Month)
                                Text(
                                  Translations.get('Current Month', isUrdu),
                                  style: const TextStyle(color: Color(0xFF009BCB), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                
                                // Row 4 (Amounts)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            Translations.get('Paid Amount', isUrdu),
                                            style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Rs. 2,500',
                                            style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            Translations.get('Remaining', isUrdu),
                                            style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Rs. 2,500',
                                            style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: 0.5,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '50 %',
                                    style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20), // Padding to show cyan background curve perfectly
                        ],
                      ),
                    ),
                  ),

                  // Unpaid Fee Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.get('Unpaid Fee', isUrdu),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15),
                        
                        // Unpaid Item Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Translations.get('Class 10', isUrdu),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const Text(
                                    'Rs. 2,500',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${Translations.get('Due:', isUrdu)} 1/15/2026',
                                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  _buildStatusBadge('Pending', Colors.deepOrange, const Color(0xFFFFF3E0), isUrdu),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildInstallmentPill('Installment 2', isUrdu),
                              const SizedBox(height: 20),
                              
                              // Upload button
                              SizedBox(
                                width: double.infinity,
                                height: 45,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showUploadDialog(context, isUrdu),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00D4FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.file_upload_outlined, size: 20),
                                  label: Text(
                                    Translations.get('Upload Payment Proof', isUrdu),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment History Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.get('Payment History', isUrdu),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15),
                        
                        // Payment History Item 1
                        Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Translations.get('Class 10', isUrdu),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const Text(
                                    'Rs. 2,500',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${Translations.get('Due:', isUrdu)} 12/15/2025',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money, size: 16, color: Colors.green),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${Translations.get('Paid on:', isUrdu)} 12/10/2025',
                                        style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  _buildStatusBadge('Paid', Colors.green, const Color(0xFFE8F5E9), isUrdu),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildInstallmentPill('Installment 1', isUrdu),
                            ],
                          ),
                        ),
                        
                        // Payment History Item 2
                        Container(
                          margin: const EdgeInsets.only(bottom: 25),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Translations.get('Class 10', isUrdu),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const Text(
                                    'Rs. 5,000',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${Translations.get('Due:', isUrdu)} 11/15/2025',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money, size: 16, color: Colors.green),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${Translations.get('Paid on:', isUrdu)} 11/09/2025',
                                        style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  _buildStatusBadge('Paid', Colors.green, const Color(0xFFE8F5E9), isUrdu),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 1, // Fees is 1
              selectedItemColor: const Color(0xFF00D4FF),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: 26,
              onTap: (index) {
                if (index == 0) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboardScreen()));
                  });
                } else if (index == 2) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentVoucherScreen()));
                  });
                } else if (index == 3) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentAlertsScreen()));
                  });
                } else if (index == 4) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentProfileScreen()));
                  });
                }
              },
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: Translations.get('Home', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), label: Translations.get('Fees', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), label: Translations.get('Voucher', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.notifications_none_outlined), label: Translations.get('Alerts', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: Translations.get('Profile', isUrdu)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(20))); // Radius matching internal rounding

    Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2.5; // Controls dashed gap empty space
      }
      distance = 0.0;
    }
    
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

