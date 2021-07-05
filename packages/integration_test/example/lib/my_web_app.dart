// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'package:flutter/material.dart';

// ignore_for_file: public_member_api_docs

void startApp() => runApp(const MyWebApp());

class MyWebApp extends StatefulWidget {
  const MyWebApp({Key? key}) : super(key: key);

  @override
  State<MyWebApp> createState() => _MyWebAppState();
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
          key: const Key('mainapp'),
          child: Text('Platform: ${html.window.navigator.platform}\n'),
        ),
      ),
    );
  }
}
