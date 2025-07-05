import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'buyer_home_screen.dart';
import 'seller_home_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<String?> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return doc.data()?['role']?.toString().toLowerCase();
    } catch (e) {
      debugPrint('Error fetching role: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;

        switch (role) {
          case 'buyer':
            return const BuyerHomeScreen();
          case 'seller':
            return const SellerHome();
          default:
            return const Scaffold(
              body: Center(
                child: Text(
                  '⚠️ Unable to determine user role.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            );
        }
      },
    );
  }
}
