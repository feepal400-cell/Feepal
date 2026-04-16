import 'package:flutter/material.dart';

void navigateWithLoader(BuildContext context, VoidCallback action) {
  showDialog(
    context: context,
    barrierColor: Colors.black12, // Subtle background
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(color: Color(0xFF2168F8)),
    ),
  );
  Future.delayed(const Duration(milliseconds: 300), () {
    if (context.mounted) {
      Navigator.pop(context); // Remove loader
      action(); // Execute navigation
    }
  });
}
