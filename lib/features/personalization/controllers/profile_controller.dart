import 'dart:io';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxMap<String, dynamic> userData = <String, dynamic>{}.obs;
  final RxString role = ''.obs;

  File? profileImage;

  @override
  void onInit() {
    fetchUserProfile();
    super.onInit();
  }

  Future<void> fetchUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        userData.value = doc.data()!;
        role.value = doc.data()?['role'] ?? '';
      }
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updatedData) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update(updatedData);
      fetchUserProfile();
      Get.snackbar("Success", "Profile updated successfully");
    }
  }

  Future<void> pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) profileImage = File(picked.path);
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final ref = FirebaseStorage.instance.ref().child("profile_pics/$uid.jpg");
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> resetPassword() async {
    final email = _auth.currentUser?.email;
    if (email != null) {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar("Email Sent", "Check your inbox to reset password");
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      Get.snackbar("Verification Sent", "Check your inbox to verify email");
    }
  }

  void logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}
