import 'package:campus_store/app.dart';
import 'package:campus_store/features/core/controllers/authentication_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  // app satrt, show splash screen
  FlutterNativeSplash.preserve(
      widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  await Firebase.initializeApp();

  GetStorage.init();
  // handle auth and later remove the slasp screen
  Get.put(AuthenticationController());
  runApp(const MyApp());
}
