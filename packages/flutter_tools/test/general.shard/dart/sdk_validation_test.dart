// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:meta/meta.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('sdk validation', () {
    AnalysisServer server;
    Directory tempDir;

    setUpAll(() {
      Cache.disableLocking();
      tempDir =
          fs.systemTempDirectory.createTempSync('sdk_validation_test').absolute;
    });

    tearDownAll(() {
      Cache.enableLocking();
      tryToDelete(tempDir);
      return server?.dispose();
    });

    testUsingContext('contains dart:ui', () async {
      createSampleProject(tempDir, dartSource: '''
import 'dart:ui' as ui;
void main() {
  // ignore: unnecessary_statements
  ui.Window;
}
''');

      await pubGet(context: PubContext.flutterTests, directory: tempDir.path);

      server = AnalysisServer(dartSdkPath, <String>[tempDir.path]);

      final int errorCount = await analyze(server);
      expect(errorCount, 0);
    });

    testUsingContext('contains dart:html', () async {
      createSampleProject(tempDir, dartSource: '''
import 'dart:html' as html;
void main() {
  // ignore: unnecessary_statements
  html.HttpStatus;
}
''');

      await pubGet(context: PubContext.flutterTests, directory: tempDir.path);

      server = AnalysisServer(dartSdkPath, <String>[tempDir.path]);

      final int errorCount = await analyze(server);
      expect(errorCount, 0);
    });

    testUsingContext('contains dart:js', () async {
      createSampleProject(tempDir, dartSource: '''
import 'dart:js' as js;
void main() {
  // ignore: unused_local_variable
  var foo = js.allowInterop(null);
}
''');

      await pubGet(context: PubContext.flutterTests, directory: tempDir.path);

      server = AnalysisServer(dartSdkPath, <String>[tempDir.path]);

      final int errorCount = await analyze(server);
      expect(errorCount, 0);
    });

    testUsingContext('contains dart:js_util', () async {
      createSampleProject(tempDir, dartSource: '''
import 'dart:js_util' as js_util;
void main() {
  // ignore: unused_local_variable
  var bar = js_util.jsify(null);
}
''');

      await pubGet(context: PubContext.flutterTests, directory: tempDir.path);

      server = AnalysisServer(dartSdkPath, <String>[tempDir.path]);

      final int errorCount = await analyze(server);
      expect(errorCount, 0);
    });
  }, skip: true);
}

void createSampleProject(Directory directory, {@required String dartSource}) {
  final File pubspecFile =
      fs.file(fs.path.join(directory.path, 'pubspec.yaml'));
  pubspecFile.writeAsStringSync('''
name: foo_project
dependencies:
  flutter:
    sdk: flutter
''');

  final File dartFile =
      fs.file(fs.path.join(directory.path, 'lib', 'main.dart'));
  dartFile.parent.createSync();
  dartFile.writeAsStringSync(dartSource);
}

Future<int> analyze(AnalysisServer server, {bool printErrors = true}) async {
  int errorCount = 0;
  final Future<bool> onDone =
      server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
  server.onErrors.listen((FileAnalysisErrors errors) {
    if (printErrors) {
      for (AnalysisError error in errors.errors) {
        print(error.toString().trim());
      }
    }
    errorCount += errors.errors.length;
  });

  await server.start();
  await onDone;

  return errorCount;
}
