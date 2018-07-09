// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';

import '../src/context.dart';
import 'test_driver.dart';
import 'test_utils.dart';

Directory _tempDir;
FlutterTestDriver _flutterRun, _flutterAttach;

void main() {

  setUp(() async {
    _tempDir = await fs.systemTempDirectory.createTemp('test_app');
    await _setupSampleProject();
    _flutterRun = new FlutterTestDriver(_tempDir);
    _flutterAttach = new FlutterTestDriver(_tempDir);
  });

  tearDown(() async {
    try {
      await _flutterRun.stop();
      await _flutterAttach.stop();
      _tempDir?.deleteSync(recursive: true);
      _tempDir = null;
    } catch (e) {
      // Don't fail tests if we failed to clean up temp folder.
    }
  });

  group('attached process', () {
    testUsingContext('can hot reload', () async {
      await _flutterRun.run(withDebugger: true);
      await _flutterAttach.attach(_flutterRun.vmServicePort);
      
      await _flutterAttach.hotReload();
    });
  }, timeout: const Timeout.factor(3));
}

// TODO: Rebase on other PRs with better sample projects (class-based) before
// landing...
Future<void> _setupSampleProject() async {
  writePubspec(_tempDir.path);
  writePackages(_tempDir.path);
  await getPackages(_tempDir.path);
  
  final String mainPath = fs.path.join(_tempDir.path, 'lib', 'main.dart');
  writeFile(mainPath, r'''
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
  ''');
}
