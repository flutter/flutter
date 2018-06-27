// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';

import 'test_project.dart';

class BasicProject extends TestProject {

  @override
  final String pubspec = '''
  name: test
  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'package:flutter/material.dart';
  
  void main() => runApp(new MyApp());
  
  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      topLevelFunction();
      return new MaterialApp(
        title: 'Flutter Demo',
        home: new Container(),
      );
    }
  }

  topLevelFunction() {
    print("test");
  }
  ''';

  @override
  String get breakpointFile => buildMethodBreakpointFile;
  @override
  int get breakpointLine => buildMethodBreakpointLine;

  String get buildMethodBreakpointFile => fs.path.join(dir.path, 'lib', 'main.dart');
  int get buildMethodBreakpointLine => 9;

  String get topLevelFunctionBreakpointFile => fs.path.join(dir.path, 'lib', 'main.dart');
  int get topLevelFunctionBreakpointLine => 17;
}
