// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../test_utils.dart';
import 'project.dart';

class HotReloadConstProject extends Project {
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
  import 'package:flutter/material.dart';
  import 'package:flutter/scheduler.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter/widgets.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed')!;
    await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp();

    final int field = 2;

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }
  ''';

  void removeFieldFromConstClass() {
    final String newMainContents = main.replaceAll(
      'final int field = 2;',
      '// final int field = 2;',
    );
    writeFile(fileSystem.path.join(dir.path, 'lib', 'main.dart'), newMainContents);
  }
}
