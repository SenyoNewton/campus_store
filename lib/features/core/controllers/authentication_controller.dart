import 'package:campus_store/features/authentication/screens/login/login.dart';
import 'package:campus_store/features/core/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


class AuthenticationController extends GetxController {
  static AuthenticationController get instance => Get.find();

  final devicestorage = GetStorage();
  final _auth = FirebaseAuth.instance;
  User? get authUser => _auth.currentUser;

   @override
  void onReady() {
    FlutterNativeSplash.remove();
    screenRedirect();
    super.onReady();
  }
  void screenRedirect() {
    final user = _auth.currentUser;
    if (user != null && user.emailVerified) {
      Get.offAll(() => const HomeScreen());
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }

  void logoutUser() async {
    await _auth.signOut();
    Get.offAll(() => const LoginScreen());
  }
}
