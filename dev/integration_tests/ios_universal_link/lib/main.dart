import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Intercept the navigation channel to verify cold-start deep links are handed off.
  SystemChannels.navigation.setMethodCallHandler((MethodCall call) async {
    stderr.writeln('Engine sent: ${call.method} ${call.arguments}');
    if (call.method == 'pushRouteInformation' || call.method == 'pushRoute') {
      // Return false to explicitly signal to the engine that the route was not handled.
      return false;
    }
    return null;
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deep Link Tester',
      home: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: Text('Home Page')),
      ),
    );
  }
}
