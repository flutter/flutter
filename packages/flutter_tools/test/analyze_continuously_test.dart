// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/commands/analyze_continuously.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:test/test.dart';

import 'src/analyze_test_common.dart';
import 'src/context.dart';

void main() {
  AnalysisServer server;
  Directory tempDir;

  setUp(() {
    FlutterCommandRunner.initFlutterRoot();
    tempDir = fs.systemTempDirectory.createTempSync('analysis_test');
  });

  tearDown(() {
    tempDir?.deleteSync(recursive: true);
    return server?.dispose();
  });

  group('analyze --watch', () {
    testUsingContext('success', () async {
      createSampleProject(tempDir);

      await pubGet(directory: tempDir.path);

      server = new AnalysisServer(dartSdkPath, <String>[tempDir.path]);

      int errorCount = 0;
      Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
      server.onErrors.listen((FileAnalysisErrors errors) => errorCount += errors.errors.length);

      await server.start();
      await onDone;

      expect(errorCount, 0);
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => os
    });

    testUsingContext('errors', () async {
      createSampleProject(tempDir, brokenCode: true);

      await pubGet(directory: tempDir.path);

      server = new AnalysisServer(dartSdkPath, <String>[tempDir.path]);

      // Analysis server returns multiple instances of the same error
      // thus use a Set to remove duplicates.
      Set<AnalysisError> errorsFound = new Set<AnalysisError>();
      Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
      server.onErrors.listen((FileAnalysisErrors errors) => errorsFound.addAll(errors.errors));

      void expectError(String text) {
        for (AnalysisError err in errorsFound) {
          if (err.message.contains(text))
            return;
        }
        String errorMsgText = '';
        for (AnalysisError err in errorsFound) {
          errorMsgText += '\n  ${err.message}';
        }
        fail('Expected\n  $text\nbut found$errorMsgText');
      }

      await server.start();
      await onDone;

      // language warning
      expectError('The function \'prints\' isn\'t defined.');
      // expect lint specified in flutter user analysis options
      expectError('Avoid empty else statements.');
      // expect lint specified in user's options file
      expectError('Only throw instances of classes extending either Exception or Error');

      expect(errorsFound, hasLength(3));
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => os
    });
  });
}
