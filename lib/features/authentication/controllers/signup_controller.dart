import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_store/features/authentication/screens/login/login.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  final email = TextEditingController();
  final password = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void registerUser() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      Get.snackbar('Success', 'Account created! Please log in.');
      Get.offAll(() => const LoginScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Signup Error', e.message ?? 'Something went wrong');
    }
  }
}
