// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../test_utils.dart';
import 'project.dart';

/// A project where the entrypoint is outside `lib/`, used to test hot
/// reload with entrypoints like `integration_test/main.dart`.
class HotReloadOutsideLibProject extends Project {
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
  String get main => r'''
  import 'package:flutter/material.dart';
  import 'package:flutter/scheduler.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter/widgets.dart';
  import 'package:flutter/foundation.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed')!;
    await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    runApp(MyApp());
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      // Do not remove the next line, it's uncommented by a test to verify that
      // hot reload worked:
      // printHotReloadWorked();

      return MaterialApp(
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }

  Future<void> printHotReloadWorked() async {
    print('(((((RELOAD WORKED)))))');

    if (kIsWeb) {
      while (true) {
        await Future.delayed(const Duration(seconds: 1));
        print('(((((RELOAD WORKED)))))');
      }
    }
  }
  ''';

  String get entrypointPath => fileSystem.path.join(dir.path, 'integration_test', 'main.dart');

  @override
  Future<void> setUpIn(Directory dir, {bool generateMain = true}) async {
    await super.setUpIn(dir, generateMain: false);
    writeFile(entrypointPath, main);
  }

  void uncommentHotReloadPrint() {
    final String newMainContents = main.replaceAll(
      '// printHotReloadWorked();',
      'printHotReloadWorked();',
    );
    writeFile(entrypointPath, newMainContents, writeFutureModifiedDate: true);
  }
}
