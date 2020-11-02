import 'dart:html' as html;
import 'package:flutter/material.dart';

// ignore_for_file: public_member_api_docs

void startApp() => runApp(MyWebApp());

class MyWebApp extends StatefulWidget {
  @override
  _MyWebAppState createState() => _MyWebAppState();
}

class _MyWebAppState extends State<MyWebApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          key: Key('mainapp'),
          child: Text('Platform: ${html.window.navigator.platform}\n'),
        ),
      ),
    );
  }
}
