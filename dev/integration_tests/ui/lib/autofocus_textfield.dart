// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'keys.dart' as keys;

void main() {
  enableFlutterDriverExtension();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autofocus TextField',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        body: Center(
          child: TextField(
            key: const ValueKey<String>(keys.kDefaultTextField),
            autofocus: true,
          ),
        ),
      ),
    );
  }
}
