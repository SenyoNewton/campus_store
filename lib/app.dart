import 'package:campus_store/bindings/general_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  GetMaterialApp(
      initialBinding: GeneralBinding(),
      title: 'Campus Store',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        backgroundColor: Colors.orange,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
