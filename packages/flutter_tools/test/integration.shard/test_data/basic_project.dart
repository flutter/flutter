// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'project.dart';

class BasicProject extends Project {

  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ">=2.0.0-dev.68.0 <3.0.0"

  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'dart:async';

  import 'package:flutter/material.dart';

  Future<void> main() async {
    while (true) {
      runApp(new MyApp());
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      topLevelFunction();
      return new MaterialApp( // BUILD BREAKPOINT
        title: 'Flutter Demo',
        home: new Container(),
      );
    }
  }

  topLevelFunction() {
    print("topLevelFunction"); // TOP LEVEL BREAKPOINT
  }
  ''';

  Uri get buildMethodBreakpointUri => mainDart;
  int get buildMethodBreakpointLine => lineContaining(main, '// BUILD BREAKPOINT');

  Uri get topLevelFunctionBreakpointUri => mainDart;
  int get topLevelFunctionBreakpointLine => lineContaining(main, '// TOP LEVEL BREAKPOINT');
}

class BasicProjectWithFlutterGen extends Project {
  @override
  final String generatedFile = '''
    String x = "a";
  ''';

  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ">=2.0.0-dev.68.0 <3.0.0"

  dependencies:
    flutter:
      sdk: flutter

  flutter:
    generate: true
  ''';

  @override
  final String main = r'''
  import 'dart:async';
  import 'package:flutter_gen/flutter_gen.dart';

  void main() {}
  ''';
}

class BasicProjectWithUnaryMain extends Project {

  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ">=2.0.0-dev.68.0 <3.0.0"
  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'dart:async';
  import 'package:flutter/material.dart';
  Future<void> main(List<String> args) async {
    while (true) {
      runApp(new MyApp());
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      topLevelFunction();
      return new MaterialApp( // BUILD BREAKPOINT
        title: 'Flutter Demo',
        home: new Container(),
      );
    }
  }
  topLevelFunction() {
    print("topLevelFunction"); // TOP LEVEL BREAKPOINT
  }
  ''';
}
