// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'project.dart';

class SteppingProject extends Project {
  @override
  final pubspec = '''
  name: test
  environment:
    sdk: ^3.7.0-0
  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final main = r'''
  import 'dart:async';

  import 'package:flutter/material.dart';

  void main() => runApp(MyApp());

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
      await Future.value(true); // STEP 1 // STEP 2
      await Future.microtask(() => true); // STEP 3 // STEP 4
      await Future.delayed(const Duration(milliseconds: 1)); // STEP 5 // STEP 6
      print("done!"); // STEP 7
    } // STEP 8

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }
  ''';

  Uri get breakpointUri => mainDart;
  int get breakpointLine => lineContaining(main, '// BREAKPOINT');
  int lineForStep(int i) => lineContaining(main, '// STEP $i');

  final numberOfSteps = 8;
}

class WebSteppingProject extends Project {
  @override
  final pubspec = '''
  name: test
  environment:
    sdk: ^3.7.0-0
  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final main = r'''
  import 'dart:async';

  import 'package:flutter/material.dart';

  void main() => runApp(MyApp());

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
      await Future.value(true); // STEP 1
      await Future.microtask(() => true);
      await Future.delayed(const Duration(milliseconds: 1));
      print("done!");
    }

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }
  ''';

  Uri get breakpointUri => mainDart;
  int get breakpointLine => lineContaining(main, '// BREAKPOINT');
  int lineForStep(int i) => lineContaining(main, '// STEP $i');

  final numberOfSteps = 1;
}
