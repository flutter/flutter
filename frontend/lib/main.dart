import 'package:flutter/material.dart';
import 'package:parkngo/homepage.dart';
import 'package:parkngo/splashscreen.dart'; // Importing your HomePage widget from homepage.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(), // Setting the home page to your HomePage widget
      debugShowCheckedModeBanner: false, // Removing the debug banner
    );
  }
}
