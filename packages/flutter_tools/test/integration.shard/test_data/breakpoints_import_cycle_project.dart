// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../test_utils.dart';
import 'project.dart';

class BreakpointsImportCycleProject extends Project {
  @override
  Future<void> setUpIn(Directory dir) {
    this.dir = dir;
    writeFile(fileSystem.path.join(dir.path, 'lib_a', 'pubspec.yaml'), _libAPubspec);
    writeFile(fileSystem.path.join(dir.path, 'lib_a', 'lib', 'lib_a.dart'), _libA);
    writeFile(fileSystem.path.join(dir.path, 'lib_b', 'pubspec.yaml'), _libBPubspec);
    writeFile(fileSystem.path.join(dir.path, 'lib_b', 'lib', 'lib_b.dart'), _libB);
    return super.setUpIn(dir.childDirectory('main_lib'));
  }

  @override
  final pubspec = '''
  name: main_lib
  environment:
    sdk: ^3.7.0-0
  dependencies:
    flutter:
      sdk: flutter
    lib_a:
      path: ../lib_a
  ''';

  @override
  final main = r'''
  import 'package:flutter/material.dart';
  import 'package:lib_a/lib_a.dart';

  void main() => runApp(MyApp());

  class MyApp extends StatefulWidget {
    @override
    _MyAppState createState() => _MyAppState();
  }

  class _MyAppState extends State<MyApp> {
    @override
    void initState() {
      print(a1());
      print(a2());
      super.initState();
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

  final _libAPubspec = '''
  name: lib_a
  environment:
    sdk: ^3.7.0-0
  dependencies:
    flutter:
      sdk: flutter
    lib_b:
      path: ../lib_b
  ''';

  final _libA = r'''
  import 'package:lib_b/lib_b.dart';

  String a1() {
    return 'a1';
  }

  String a2() {
    return 'a2${b2()}'; // BREAKPOINT 1
  }
  ''';

  final _libBPubspec = '''
  name: lib_b
  environment:
    sdk: ^3.7.0-0
  dependencies:
    flutter:
      sdk: flutter
    lib_a:
      path: ../lib_a
  ''';

  final _libB = r'''
  import 'package:lib_a/lib_a.dart';

  String b1() {
    return 'b1${a1()}';
  }

  String b2() {
    return 'b2'; // BREAKPOINT 2
  }
  ''';

  Uri get breakpointUri1 => Uri.parse('package:lib_a/lib_a.dart');
  int get breakpointLine1 => lineContaining(_libA, '// BREAKPOINT 1');
  Uri get breakpointUri2 => Uri.parse('package:lib_b/lib_b.dart');
  int get breakpointLine2 => lineContaining(_libB, '// BREAKPOINT 2');
}
