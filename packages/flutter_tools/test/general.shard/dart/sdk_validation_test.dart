// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The "// ignore:" comments found in strings in this file are counted as _actual_ ignore comments.
// Since the "// ignore:" comments found in strings don't actually ignore anythin in _this_ file,
// we must allow them to be "unused." See https://github.com/dart-lang/sdk/issues/39607.
// ignore_for_file: unused_ignore_code
import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/dart/sdk.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testSampleProject('ui', 'Window');
  testSampleProject('html', 'HttpStatus');
  testSampleProject('js', 'allowInterop');
  testSampleProject('js_util', 'jsify');
}

void testSampleProject(String lib, String member) {
  testUsingContext('contains dart:$lib', () async {
    Cache.disableLocking();
    final Directory projectDirectory = fs.systemTempDirectory.createTempSync('flutter_sdk_validation_${lib}_test.').absolute;

    try {
      final File pubspecFile = fs.file(fs.path.join(projectDirectory.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('''
name: ${lib}_project
dependencies:
  flutter:
    sdk: flutter
''');

      final File dartFile = fs.file(fs.path.join(projectDirectory.path, 'lib', 'main.dart'));
      dartFile.parent.createSync();
      dartFile.writeAsStringSync('''
import 'dart:$lib' as $lib;
void main() {
  // ignore: unnecessary_statements
  $lib.$member;
}
''');

      await pub.get(context: PubContext.flutterTests, directory: projectDirectory.path);
      final AnalysisServer server = AnalysisServer(dartSdkPath, <String>[projectDirectory.path]);
      try {
        final int errorCount = await analyze(server);
        expect(errorCount, 0);
      } finally {
        await server.dispose();
      }
    } finally {
      tryToDelete(projectDirectory);
      Cache.enableLocking();
    }
  }, skip: true);
}

Future<int> analyze(AnalysisServer server) async {
  int errorCount = 0;
  final Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
  server.onErrors.listen((FileAnalysisErrors result) {
    for (AnalysisError error in result.errors) {
      print(error.toString().trim());
    }
    errorCount += result.errors.length;
  });

  await server.start();
  await onDone;

  return errorCount;
}
