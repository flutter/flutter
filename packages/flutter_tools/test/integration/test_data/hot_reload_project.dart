// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';

import '../test_utils.dart';
import 'project.dart';

class HotReloadProject extends Project {
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
      // Do not remove this line, it's uncommented by a test to verify that hot
      // reloading worked.
      // printHotReloadWorked();

      return new MaterialApp( // BREAKPOINT
        title: 'Flutter Demo',
        home: new Container(),
      );
    }
  }

  printHotReloadWorked() {
    // The call to this function is uncommented by a test to verify that hot
    // reloading worked.
    print('(((((RELOAD WORKED)))))');
  }
  ''';

  void uncommentHotReloadPrint() {
    final String newMainContents = main.replaceAll(
        '// printHotReloadWorked();', 'printHotReloadWorked();');
    writeFile(fs.path.join(dir.path, 'lib', 'main.dart'), newMainContents);
  }
}
