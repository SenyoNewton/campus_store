import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_store/features/core/screens/home/home_screen.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // Controllers
  final email = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Observables
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  // Real-time validation observables
  final emailError = RxnString();
  final passwordError = RxnString();
  final isEmailValid = false.obs;
  final isPasswordValid = false.obs;

  // Firebase instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    // Add listeners for real-time validation
    email.addListener(_validateEmailRealTime);
    password.addListener(_validatePasswordRealTime);
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Real-time email validation
  void _validateEmailRealTime() {
    String value = email.text;

    if (value.isEmpty) {
      emailError.value = null;
      isEmailValid.value = false;
      return;
    }

    // Check for invalid characters
    if (value.contains(' ')) {
      emailError.value = 'Email cannot contain spaces';
      isEmailValid.value = false;
      return;
    }

    // Check for numbers at the beginning
    if (value.isNotEmpty && RegExp(r'^[0-9]').hasMatch(value)) {
      emailError.value = 'Email cannot start with a number';
      isEmailValid.value = false;
      return;
    }

    // Check for invalid characters in email
    if (!RegExp(r'^[a-zA-Z0-9@._-]*$').hasMatch(value)) {
      emailError.value = 'Email contains invalid characters';
      isEmailValid.value = false;
      return;
    }

    // Check email format
    if (!GetUtils.isEmail(value)) {
      emailError.value = 'Please enter a valid email format';
      isEmailValid.value = false;
      return;
    }

    // Check if it's a student email (you can customize this)
    if (value.isNotEmpty && !value.contains('@')) {
      emailError.value = 'Please include @ in your email';
      isEmailValid.value = false;
      return;
    }

    emailError.value = null;
    isEmailValid.value = true;
  }

  /// Real-time password validation
  void _validatePasswordRealTime() {
    String value = password.text;

    if (value.isEmpty) {
      passwordError.value = null;
      isPasswordValid.value = false;
      return;
    }

    // Check for spaces
    if (value.contains(' ')) {
      passwordError.value = 'Password cannot contain spaces';
      isPasswordValid.value = false;
      return;
    }

    // Check minimum length
    if (value.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      isPasswordValid.value = false;
      return;
    }

    // Check for at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      passwordError.value = 'Password must contain at least one letter';
      isPasswordValid.value = false;
      return;
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      passwordError.value = 'Password must contain at least one number';
      isPasswordValid.value = false;
      return;
    }

    passwordError.value = null;
    isPasswordValid.value = true;
  }

  /// Email validation for form submission
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    if (value.contains(' ')) {
      return 'Email cannot contain spaces';
    }

    if (RegExp(r'^[0-9]').hasMatch(value)) {
      return 'Email cannot start with a number';
    }

    if (!RegExp(r'^[a-zA-Z0-9@._-]*$').hasMatch(value)) {
      return 'Email contains invalid characters';
    }

    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Password validation for form submission
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.contains(' ')) {
      return 'Password cannot contain spaces';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Check if form is valid
  bool get isFormValid => isEmailValid.value && isPasswordValid.value;

  /// Login user with email and password
  Future<void> loginUser() async {
    try {
      // Validate form first
      if (!formKey.currentState!.validate()) {
        return;
      }

      isLoading.value = true;

      // Attempt login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      // Check if user exists
      if (userCredential.user != null) {
        _showSuccessMessage('Login successful!');
        Get.offAll(() => const HomeScreen());
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle Firebase Auth exceptions
  void _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      case 'invalid-credential':
        message = 'Invalid email or password. Please check your credentials.';
        break;
      default:
        message = e.message ?? 'Login failed. Please try again.';
    }
    _showErrorMessage(message);
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Clear form fields
  void clearForm() {
    email.clear();
    password.clear();
    emailError.value = null;
    passwordError.value = null;
    isEmailValid.value = false;
    isPasswordValid.value = false;
  }
}
