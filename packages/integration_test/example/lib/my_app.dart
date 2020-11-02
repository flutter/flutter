import 'dart:io' show Platform;
import 'package:flutter/material.dart';

// ignore_for_file: public_member_api_docs

void startApp() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Platform: ${Platform.operatingSystem}\n'),
        ),
      ),
    );
  }
}
