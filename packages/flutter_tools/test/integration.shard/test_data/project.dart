// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';

import '../test_utils.dart';
import 'deferred_components_config.dart';

const String _kDefaultHtml  = '''
<html>
    <head>
        <title>Hello, World</title>
    </head>
    <body>
        <script src="main.dart.js"></script>
    </body>
</html>
''';

abstract class Project {
  Directory dir;

  String get pubspec;
  String get main;
  String get test => null;
  String get generatedFile => null;
  DeferredComponentsConfig get deferredComponents => null;

  Uri get mainDart => Uri.parse('package:test/main.dart');

  Future<void> setUpIn(Directory dir) async {
    this.dir = dir;
    writeFile(fileSystem.path.join(dir.path, 'pubspec.yaml'), pubspec);
    if (main != null) {
      writeFile(fileSystem.path.join(dir.path, 'lib', 'main.dart'), main);
    }
    if (test != null) {
      writeFile(fileSystem.path.join(dir.path, 'test', 'test.dart'), test);
    }
    if (generatedFile != null) {
      writeFile(fileSystem.path.join(dir.path, '.dart_tool', 'flutter_gen', 'flutter_gen.dart'), generatedFile);
    }
    if (deferredComponents != null) {
      deferredComponents.setUpIn(dir);
    }
    writeFile(fileSystem.path.join(dir.path, 'web', 'index.html'), _kDefaultHtml);
    writePackages(dir.path);
    await getPackages(dir.path);
  }

  int lineContaining(String contents, String search) {
    final int index = contents.split('\n').indexWhere((String l) => l.contains(search));
    if (index == -1) {
      throw Exception("Did not find '$search' inside the file");
    }
    return index + 1; // first line is line 1, not line 0
  }
}
