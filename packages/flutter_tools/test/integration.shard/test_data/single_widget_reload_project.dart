// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../test_utils.dart';
import 'project.dart';

class SingleWidgetReloadProject extends Project {
  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: '>=3.0.0-0 <4.0.0'

  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'package:flutter/material.dart';
  import 'package:flutter/scheduler.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter/widgets.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed')!;
    await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    runApp(MyApp());
  }

  int count = 1;

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      // PARENT WIDGET

      print('((((TICK $count))))');
      count += 1;

      return MaterialApp(
        title: 'Flutter Demo',
        home: SecondWidget(),
      );
    }
  }

  class SecondWidget extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      // Do not remove the next line, it's uncommented by a test to verify that
      // hot reloading worked:
      // printHotReloadWorked();
      return Container();
    }
  }

  void printHotReloadWorked() {
    // The call to this function is uncommented by a test to verify that hot
    // reloading worked.
    print('(((((RELOAD WORKED)))))');
  }
  ''';

  Uri get parentWidgetUri => mainDart;
  int get parentWidgetLine => lineContaining(main, '// PARENT WIDGET');

  void uncommentHotReloadPrint() {
    final String newMainContents = main.replaceAll(
      '// printHotReloadWorked();',
      'printHotReloadWorked();',
    );
    writeFile(
      fileSystem.path.join(dir.path, 'lib', 'main.dart'),
      newMainContents,
      writeFutureModifiedDate: true,
    );
  }

  void modifyFunction() {
    final String newMainContents = main.replaceAll(
      '(((((RELOAD WORKED)))))',
      '(((((RELOAD WORKED 2)))))',
    );
    writeFile(
      fileSystem.path.join(dir.path, 'lib', 'main.dart'),
      newMainContents,
      writeFutureModifiedDate: true,
    );
  }
}
