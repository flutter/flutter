// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';

import '../test_utils.dart';
import 'project.dart';

class BasicProject extends Project {

  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ">=2.12.0-0 <3.0.0"

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
      runApp(MyApp());
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      topLevelFunction();
      return MaterialApp( // BUILD BREAKPOINT
        title: 'Flutter Demo',
        home: Container(),
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

class BasicProjectWithSecondary extends Project {
  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ">=2.12.0-0 <3.0.0"

  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String secondary = r'''
  int foo() {
    return 12; // HOT RELOAD API
  }
  ''';

  @override
  final String main = r'''
  import 'dart:async';

  import 'package:flutter/material.dart';
  import 'bar.dart';

  void main() {
    runApp(MyApp());
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      topLevelFunction();
      return MaterialApp( // BUILD BREAKPOINT
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }

  topLevelFunction() {
    print("${foo()}"); // TOP LEVEL BREAKPOINT
  }
  ''';

  Uri get buildMethodBreakpointUri => mainDart;
  int get buildMethodBreakpointLine => lineContaining(main, '// BUILD BREAKPOINT');

  Uri get topLevelFunctionBreakpointUri => mainDart;
  int get topLevelFunctionBreakpointLine => lineContaining(main, '// TOP LEVEL BREAKPOINT');

  void updateSecondaryReturnValue(int value) {
    final File file = fileSystem.file(fileSystem.path.join(dir.path, 'lib', 'bar.dart'));
    final List<String> lines = <String>[];
    for (final String line in file.readAsLinesSync()) {
      if (line.endsWith('// HOT RELOAD API')) {
        lines.add('return $value; // HOT RELOAD API');
      } else {
        lines.add(line);
      }
    }
    writeFile(file.path, lines.join('\n'));
  }
}

class BasicProjectWithTimelineTraces extends Project {
  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ">=2.12.0-0 <3.0.0"

  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'dart:async';
  import 'dart:developer';

  import 'package:flutter/material.dart';

  Future<void> main() async {
    while (true) {
      runApp(MyApp());
      await Future.delayed(const Duration(milliseconds: 50));
      Timeline.instantSync('main');
    }
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      topLevelFunction();
      return MaterialApp( // BUILD BREAKPOINT
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }

  topLevelFunction() {
    print("topLevelFunction"); // TOP LEVEL BREAKPOINT
  }
  ''';
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
    sdk: ">=2.12.0-0 <3.0.0"

  dependencies:
    flutter:
      sdk: flutter

  flutter:
    generate: true
  ''';

  @override
  final String main = r'''
  // @dart = 2.8
  // generated package does not support null safety.
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
    sdk: ">=2.12.0-0 <3.0.0"
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
      runApp(MyApp());
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      topLevelFunction();
      return MaterialApp( // BUILD BREAKPOINT
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }
  topLevelFunction() {
    print("topLevelFunction"); // TOP LEVEL BREAKPOINT
  }
  ''';
}
