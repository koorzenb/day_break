import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/app_constants.dart';

/// Utility class for showing consistent snackbar messages throughout the app
class SnackBarHelper {
  /// Private constructor to prevent instantiation
  SnackBarHelper._();

  /// Show a generic snackbar with custom styling
  static void _showSnackBar(
    String title,
    String message,
    Color backgroundColor,
  ) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor.withAlpha((0.8 * 255).toInt()),
        colorText: Colors.white,
        duration: Duration(seconds: AppConstants.snackbarDuration),
      );
    }
  }

  /// Show success snackbar with green background
  static void showSuccess(String title, String message) {
    _showSnackBar(title, message, Colors.green);
  }

  /// Show error snackbar with red background
  static void showError(String title, String message) {
    _showSnackBar(title, message, Colors.red);
  }

  /// Show info snackbar with blue background
  static void showInfo(String title, String message) {
    _showSnackBar(title, message, Colors.blue);
  }

  /// Show warning snackbar with orange background
  static void showWarning(String title, String message) {
    _showSnackBar(title, message, Colors.orange);
  }

  /// Show custom snackbar with specified background color
  static void showCustom(String title, String message, Color backgroundColor) {
    _showSnackBar(title, message, backgroundColor);
  }
}
