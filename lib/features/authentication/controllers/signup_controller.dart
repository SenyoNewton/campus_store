import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:campus_store/features/core/screens/home/home_screen.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  // Controllers
  final name = TextEditingController();
  final email = TextEditingController();
  final indexNumber = TextEditingController();
  final course = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Observables
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final selectedRole = 'buyer'.obs;
  final roles = ['buyer', 'seller'].obs;

  // Real-time validation observables
  final nameError = RxnString();
  final emailError = RxnString();
  final indexNumberError = RxnString();
  final courseError = RxnString();
  final phoneError = RxnString();
  final passwordError = RxnString();

  final isNameValid = false.obs;
  final isEmailValid = false.obs;
  final isIndexNumberValid = false.obs;
  final isCourseValid = false.obs;
  final isPhoneValid = false.obs;
  final isPasswordValid = false.obs;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    // Add listeners for real-time validation
    name.addListener(_validateNameRealTime);
    email.addListener(_validateEmailRealTime);
    indexNumber.addListener(_validateIndexNumberRealTime);
    course.addListener(_validateCourseRealTime);
    phone.addListener(_validatePhoneRealTime);
    password.addListener(_validatePasswordRealTime);
  }

  @override
  void onClose() {
    name.dispose();
    email.dispose();
    indexNumber.dispose();
    course.dispose();
    phone.dispose();
    password.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Update selected role
  void updateRole(String role) {
    selectedRole.value = role;
  }

  /// Real-time name validation
  void _validateNameRealTime() {
    String value = name.text;

    if (value.isEmpty) {
      nameError.value = null;
      isNameValid.value = false;
      return;
    }

    // Check for numbers in name
    if (RegExp(r'[0-9]').hasMatch(value)) {
      nameError.value = 'Name cannot contain numbers';
      isNameValid.value = false;
      return;
    }

    // Check for special characters except spaces
    if (!RegExp(r'^[a-zA-Z\s]*$').hasMatch(value)) {
      nameError.value = 'Name can only contain letters and spaces';
      isNameValid.value = false;
      return;
    }

    // Check minimum length
    if (value.trim().length < 2) {
      nameError.value = 'Name must be at least 2 characters';
      isNameValid.value = false;
      return;
    }

    // Check for excessive spaces
    if (value.contains(RegExp(r'\s{2,}'))) {
      nameError.value = 'Name cannot have multiple consecutive spaces';
      isNameValid.value = false;
      return;
    }

    nameError.value = null;
    isNameValid.value = true;
  }

  /// Real-time email validation
  void _validateEmailRealTime() {
    String value = email.text;

    if (value.isEmpty) {
      emailError.value = null;
      isEmailValid.value = false;
      return;
    }

    // Check for spaces
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

    // Check for invalid characters
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

    emailError.value = null;
    isEmailValid.value = true;
  }

  /// Real-time index number validation
  void _validateIndexNumberRealTime() {
    String value = indexNumber.text;

    if (value.isEmpty) {
      indexNumberError.value = null;
      isIndexNumberValid.value = false;
      return;
    }

    // Check for spaces
    if (value.contains(' ')) {
      indexNumberError.value = 'Index number cannot contain spaces';
      isIndexNumberValid.value = false;
      return;
    }

    // Check for lowercase letters
    if (RegExp(r'[a-z]').hasMatch(value)) {
      indexNumberError.value = 'Index number should be in uppercase';
      isIndexNumberValid.value = false;
      return;
    }

    // Check for invalid characters
    if (!RegExp(r'^[A-Z0-9]*$').hasMatch(value)) {
      indexNumberError.value =
          'Index number can only contain uppercase letters and numbers';
      isIndexNumberValid.value = false;
      return;
    }

    // Check minimum length
    if (value.length < 5) {
      indexNumberError.value = 'Index number must be at least 5 characters';
      isIndexNumberValid.value = false;
      return;
    }

    indexNumberError.value = null;
    isIndexNumberValid.value = true;
  }

  /// Real-time course validation
  void _validateCourseRealTime() {
    String value = course.text;

    if (value.isEmpty) {
      courseError.value = null;
      isCourseValid.value = false;
      return;
    }

    // Check for numbers at the beginning
    if (RegExp(r'^[0-9]').hasMatch(value)) {
      courseError.value = 'Course cannot start with a number';
      isCourseValid.value = false;
      return;
    }

    // Check for invalid characters
    if (!RegExp(r'^[a-zA-Z\s&]*$').hasMatch(value)) {
      courseError.value = 'Course can only contain letters, spaces, and &';
      isCourseValid.value = false;
      return;
    }

    // Check for excessive spaces
    if (value.contains(RegExp(r'\s{2,}'))) {
      courseError.value = 'Course cannot have multiple consecutive spaces';
      isCourseValid.value = false;
      return;
    }

    courseError.value = null;
    isCourseValid.value = true;
  }

  /// Real-time phone validation
  void _validatePhoneRealTime() {
    String value = phone.text;

    if (value.isEmpty) {
      phoneError.value = null;
      isPhoneValid.value = false;
      return;
    }

    // Check for letters
    if (RegExp(r'[a-zA-Z]').hasMatch(value)) {
      phoneError.value = 'Phone number cannot contain letters';
      isPhoneValid.value = false;
      return;
    }

    // Check for invalid characters
    if (!RegExp(r'^[0-9+\-\s()]*$').hasMatch(value)) {
      phoneError.value = 'Phone number contains invalid characters';
      isPhoneValid.value = false;
      return;
    }

    // Check minimum length (adjust as needed)
    if (value.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
      phoneError.value = 'Phone number must be at least 10 digits';
      isPhoneValid.value = false;
      return;
    }

    phoneError.value = null;
    isPhoneValid.value = true;
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

  /// Check if form is valid
  bool get isFormValid =>
      isNameValid.value &&
      isEmailValid.value &&
      isIndexNumberValid.value &&
      isCourseValid.value &&
      isPhoneValid.value &&
      isPasswordValid.value;

  /// Validate name
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'Name cannot contain numbers';
    }
    if (!RegExp(r'^[a-zA-Z\s]*$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate email
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
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate index number
  String? validateIndexNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your index number';
    }
    if (value.contains(' ')) {
      return 'Index number cannot contain spaces';
    }
    if (!RegExp(r'^[A-Z0-9]*$').hasMatch(value)) {
      return 'Index number can only contain uppercase letters and numbers';
    }
    if (value.length < 5) {
      return 'Please enter a valid index number';
    }
    return null;
  }

  /// Validate course
  String? validateCourse(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your course of study';
    }
    if (RegExp(r'^[0-9]').hasMatch(value)) {
      return 'Course cannot start with a number';
    }
    if (!RegExp(r'^[a-zA-Z\s&]*$').hasMatch(value)) {
      return 'Course can only contain letters, spaces, and &';
    }
    return null;
  }

  /// Validate phone number
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Phone number cannot contain letters';
    }
    if (!RegExp(r'^[0-9+\-\s()]*$').hasMatch(value)) {
      return 'Phone number contains invalid characters';
    }
    if (value.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
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

  /// Register new user
  Future<void> registerUser() async {
    try {
      // Validate form first
      if (!formKey.currentState!.validate()) {
        return;
      }

      isLoading.value = true;

      // Create user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw Exception('Failed to create user account');
      }

      // Create user profile in Firestore
      await _createUserProfile(uid);

      _showSuccessMessage('Account created successfully!');

      // Navigate to home screen instead of login
      Get.offAll(() => const HomeScreen());
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e) {
      _showErrorMessage('Registration failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name.text.trim(),
        'email': email.text.trim(),
        'indexNumber': indexNumber.text.trim(),
        'course': course.text.trim(),
        'phone': phone.text.trim(),
        'role': selectedRole.value.toLowerCase(),
        'createdAt': Timestamp.now(),
        'isActive': true,
      });
    } catch (e) {
      // If Firestore fails, delete the Auth user to maintain consistency
      await _auth.currentUser?.delete();
      throw Exception('Failed to create user profile');
    }
  }

  /// Handle Firebase Auth exceptions
  void _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      default:
        message = e.message ?? 'Registration failed. Please try again.';
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
    name.clear();
    email.clear();
    indexNumber.clear();
    course.clear();
    phone.clear();
    password.clear();
    selectedRole.value = 'buyer';

    // Clear validation states
    nameError.value = null;
    emailError.value = null;
    indexNumberError.value = null;
    courseError.value = null;
    phoneError.value = null;
    passwordError.value = null;

    isNameValid.value = false;
    isEmailValid.value = false;
    isIndexNumberValid.value = false;
    isCourseValid.value = false;
    isPhoneValid.value = false;
    isPasswordValid.value = false;
  }
}
