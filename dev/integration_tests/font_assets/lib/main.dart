// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore: deprecated_member_use
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Fonts',
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              const Icon(Icons.abc),
              Text('Hello world', style: TextStyle(fontFamily: 'BBHBartle')),
              Text('Hello world'),
            ],
          ),
        ),
      ),
    );
  }
}
