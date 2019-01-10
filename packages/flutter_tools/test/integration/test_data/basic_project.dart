// Copyright 2018 The Chromium Authors. All rights reserved.
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
  import 'package:flutter/material.dart';

  void main() => runApp(new MyApp());

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      topLevelFunction();
      return new MaterialApp( // BREAKPOINT
        title: 'Flutter Demo',
        home: new Container(),
      );
    }
  }

  topLevelFunction() {
    print("topLevelFunction"); // TOP LEVEL BREAKPOINT
  }
  ''';

  Uri get buildMethodBreakpointUri => breakpointUri;
  int get buildMethodBreakpointLine => breakpointLine;

  Uri get topLevelFunctionBreakpointUri => breakpointUri;
  int get topLevelFunctionBreakpointLine => lineContaining(main, '// TOP LEVEL BREAKPOINT');
}
