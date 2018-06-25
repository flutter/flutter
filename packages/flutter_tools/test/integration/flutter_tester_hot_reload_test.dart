// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';
import 'package:vm_service_client/vm_service_client.dart';

import '../src/context.dart';
import 'flutter_test_driver.dart';
import 'util.dart';

Directory _tempDir;
FlutterTestDriver _flutter;

void main() {

  setUp(() async {
    _tempDir = await fs.systemTempDirectory.createTemp('test_app');
    await _setupSampleProject();
    _flutter = new FlutterTestDriver(_tempDir); 
  });

  tearDown(() async {
    try {
      await _flutter.stop();
      _tempDir?.deleteSync(recursive: true);
      _tempDir = null;
    } catch (e) {
      // Don't fail tests if we failed to clean up temp folder.
    }
  });

  Future<VMIsolate> breakInBuildMethod(FlutterTestDriver flutter) async {
    return _flutter.breakAt(
      fs.path.join(_tempDir.path, 'lib', 'main.dart'),
      9
    );
  }

  Future<VMIsolate> breakInTopLevelFunction(FlutterTestDriver flutter) async {
    return _flutter.breakAt(
      fs.path.join(_tempDir.path, 'lib', 'main.dart'),
      17
    );
  }

  // TODO(dantup): Is there a better way to do this (ideally inlined in the tests)?
  // Feels clumsy, and not being able to use `as` means an extra line just for
  // casting.
  void expectTypeAndValue<T extends VMInstanceRef>(VMInstanceRef ref, bool Function(T ref) checkValue) {
    expect(ref, new isInstanceOf<T>());
    final T typedRef = ref;
    checkValue(typedRef);
  }

  group('FlutterTesterDevice', () {

    // This test fails on Windows due to https://github.com/flutter/flutter/issues/17833
    testUsingContext('can hot reload', () async {
      await _flutter.run();
      await _flutter.hotReload();
    });

    // This test fails due to https://github.com/flutter/flutter/issues/18441
    testUsingContext('can hit breakpoints with file:// prefixes after reload', () async {
      await _flutter.run(withDebugger: true);
      
      // Add the breakpoint using a file:// URI.
      await _flutter.addBreakpoint(
          // Test currently passes with a FS path, but not with file:// URI.
          // fs.path.join(_tempDir.path, 'lib', 'main.dart'),
          new Uri.file(fs.path.join(_tempDir.path, 'lib', 'main.dart')).toString(),
          9
      );
      
      await _flutter.hotReload();

      // Ensure we hit the breakpoint.
      final VMIsolate isolate = await _flutter.waitForBreakpointHit();
      expect(isolate.pauseEvent, const isInstanceOf<VMPauseBreakpointEvent>());
    });

    Future<void> evaluateTrivialExpressions() async {
      expectTypeAndValue(
          await _flutter.evaluateExpression('"test"'),
          (VMStringInstanceRef s) => s.value == 'test2',
      );
      expectTypeAndValue(
          await _flutter.evaluateExpression('1'),
          (VMIntInstanceRef s) => s.value == 2,
      );
      expectTypeAndValue(
          await _flutter.evaluateExpression('true'),
          (VMBoolInstanceRef s) => s.value == false,
      );
    }

    Future<void> evaluateComplexExpressions() async {
      expectTypeAndValue(
          await _flutter.evaluateExpression('new DateTime.now().year'),
          (VMIntInstanceRef s) => s.value == new DateTime.now().year,
      );
    }

    Future<void> evaluateComplexReturningExpressions() async {
      final DateTime now = new DateTime.now();
      final VMInstanceRef resp = await _flutter.evaluateExpression('new DateTime.now()');
      expect(resp.klass.name, equals('DateTime'));
      final DateTime value = await resp.getValue();
      // Ensure we got a reasonable approximation. The more accurate we try to
      // make this, the more likely it'll fail due to differences in the time
      // in the remote VM and the local VM.
      expect('${value.year}-${value.month}-${value.day}',
          equals('${now.year}-${now.month}-${now.day}'));
    }

    // This test fails due to https://github.com/flutter/flutter/issues/18678.
    testUsingContext('can evaluate trivial expressions in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateTrivialExpressions();
    });

    // This test fails due to https://github.com/flutter/flutter/issues/18678.
    testUsingContext('can evaluate trivial expressions in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateTrivialExpressions();
    });

    // This test fails due to https://github.com/flutter/flutter/issues/18678.
    testUsingContext('can evaluate complex expressions in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateTrivialExpressions();
    });

    // This test fails due to https://github.com/flutter/flutter/issues/18678.
    testUsingContext('can evaluate complex expressions in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateComplexExpressions();
    });

    // This test fails due to https://github.com/flutter/flutter/issues/18678.
    testUsingContext('can evaluate expressions returning complex objects in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateComplexReturningExpressions();
    });

    // This test fails due to https://github.com/flutter/flutter/issues/18678.
    testUsingContext('can evaluate expressions returning complex objects in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateComplexReturningExpressions();
    });

  }, timeout: const Timeout.factor(3));
}

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
