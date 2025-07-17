import 'package:campus_store/bindings/general_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:campus_store/features/authentication/screens/login/login.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: GeneralBinding(),
      title: 'Campus Store',
      debugShowCheckedModeBanner: false,
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        // Add other routes here as needed
      ],
      home: const Scaffold(
        backgroundColor: Colors.orange,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
