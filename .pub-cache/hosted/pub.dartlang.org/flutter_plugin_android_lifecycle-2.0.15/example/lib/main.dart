// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// MyApp is the Main Application.
class MyApp extends StatelessWidget {
  /// Default Constructor
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sample flutter_plugin_android_lifecycle usage'),
        ),
        body: const Center(
            child: Text(
                'This plugin only provides Android Lifecycle API\n for other Android plugins.')),
      ),
    );
  }
}
