import 'package:flutter/material.dart';

void navigateWithLoader(BuildContext context, VoidCallback action) {
  // Execute navigation immediately to avoid redundant loading indicators
  action();
}
