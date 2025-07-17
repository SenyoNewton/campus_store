import 'package:campus_store/app.dart';
import 'package:campus_store/features/core/controllers/authentication_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  // app start, show splash screen
  FlutterNativeSplash.preserve(
      widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    // For debug/development - change to playIntegrity for production
    androidProvider: AndroidProvider.debug,
    // For iOS (if you're using it)
    // appleProvider: AppleProvider.debug,
  );

  // Set Firebase Auth language
  await FirebaseAuth.instance.setLanguageCode('en');

  // Initialize GetStorage
  await GetStorage.init();

  // Handle auth and later remove the splash screen
  Get.put(AuthenticationController());

  runApp(const MyApp());
}
