// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'project.dart';

class SteppingProject extends Project {
  @override
  final String pubspec = '''
  name: test
  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'dart:async';

  import 'package:flutter/material.dart';

  void main() => runApp(new MyApp());

  class MyApp extends StatefulWidget {
    @override
    _MyAppState createState() => _MyAppState();
  }

  class _MyAppState extends State<MyApp> {
    @override
    void initState() {
      doAsyncStuff();
      super.initState();
    }

    Future<void> doAsyncStuff() async {
      print("test"); // BREAKPOINT
      await new Future.value(true); // STEP 1
      await new Future.microtask(() => true); // STEP 2 // STEP 3
      await new Future.delayed(const Duration(milliseconds: 1)); // STEP 4 // STEP 5
      print("done!"); // STEP 6
    }

    @override
    Widget build(BuildContext context) {
      return new MaterialApp(
        title: 'Flutter Demo',
        home: new Container(),
      );
    }
  }
  ''';

  int lineForStep(int i) => lineContaining(main, '// STEP $i');

  final int numberOfSteps = 6;
}
