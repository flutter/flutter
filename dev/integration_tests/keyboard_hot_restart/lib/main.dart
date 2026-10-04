// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

// If true, the app autofocuses a text field, making the software keyboard visible.
// The test changes this line while the app is running.
// If you change this line, update the test as well.
// See:
// //dev/devicelab/lib/tasks/keyboard_hot_restart_test.dart
const bool forceKeyboard = true;

bool? keyboardVisible;

void main() {
  runApp(const MyApp());
  unawaited(printKeyboardState());
}

Future<void> printKeyboardState() async {
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (keyboardVisible == null) {
      continue;
    }

    // Print whether the keyboard is visible or not.
    // If you change this line, update the test as well.
    // See:
    // //dev/devicelab/lib/tasks/keyboard_hot_restart_test.dart
    // ignore: avoid_print
    print('Keyboard is ${keyboardVisible! ? 'open' : 'closed'}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MyHomePage());
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final EdgeInsets insets = MediaQuery.of(context).viewInsets;

    keyboardVisible = insets.bottom > 0;

    return const Scaffold(
      body: Center(child: TextField(autofocus: forceKeyboard)),
    );
  }
}
