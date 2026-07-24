// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../test_utils.dart';
import 'project.dart';

/// A project whose `web/index.html` and `web/flutter_bootstrap.js` contain user
/// `--web-define` placeholders (`{{MY_VERSION}}` and `{{API_URL}}`), used by the
/// end-to-end tests that verify `--web-define` substitution.
class WebDefineProject extends Project {
  WebDefineProject() : super(indexHtml: _indexHtml);

  static const String kVersion = 'v9.9.9';
  static const String kApiUrl = 'https://example.invalid/api';

  static const String _indexHtml = '''
<html>
    <head>
        <meta charset='utf-8'>
        <title>Hello, World</title>
        <meta name="app-version" content="{{MY_VERSION}}">
        <meta name="api-url" content="{{API_URL}}">
    </head>
    <body>
        <script src="main.dart.js"></script>
    </body>
</html>
''';

  // The default generated bootstrap has no user placeholder, so the fixture
  // supplies a template with one to make bootstrap substitution observable.
  static const String _flutterBootstrapJs = '''
// build: {{MY_VERSION}} api: {{API_URL}}
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load();
''';

  @override
  String get pubspec =>
      '''
  name: $name
  environment:
    sdk: ^3.7.0-0

  dependencies:
    flutter:
      sdk: flutter
  ''';

  // Rebuild continuously so hot reload/restart have an observable effect.
  @override
  final main = r'''
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
      return MaterialApp(
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }
  ''';

  @override
  Future<void> setUpIn(Directory dir, {bool generateMain = true}) async {
    await super.setUpIn(dir, generateMain: generateMain);
    // Project.setUpIn does not write a flutter_bootstrap.js, so add the custom template here.
    writeFile(fileSystem.path.join(dir.path, 'web', 'flutter_bootstrap.js'), _flutterBootstrapJs);
  }
}
