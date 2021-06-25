// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


// ignore_for_file: public_member_api_docs

void startApp() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const MethodChannel _channel = MethodChannel('plugins.flutter.io/integration_test');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(children: <Widget> [
            Text('Platform: ${Platform.operatingSystem}\n'),
            ElevatedButton(child: const Text('Hello'), onPressed: () {
              _channel.invokeMethod<void>('captureScreenshot', <String, dynamic>{});
            },),
          ],
        ),
      ),
    )
    );
  }
}
