// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/executable.dart' as tools;
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart' as os;
import 'package:flutter_tools/src/crash_reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'src/context.dart';

void main() {
  group('crash reporting', () {
    int testPort;

    setUp(() async {
      tools.fs = new MemoryFileSystem();
      setExitFunctionForTests((_) { });
      testPort = await os.findAvailablePort();
      overrideBaseCrashUrlForTesting(Uri.parse('http://localhost:$testPort/test-path'));
    });

    tearDown(() {
      tools.fs = new LocalFileSystem();
      restoreExitFunction();
      resetBaseCrashUrlForTesting();
    });

    testUsingContext('should send crash reports', () async {
      String method;
      Uri uri;

      CrashReportSender.initializeWith(new MockClient((Request request) async {
        method = request.method;
        uri = request.url;
        return new Response(
            'test-report-id',
            200
        );
      }));

      int exitCode = await tools.run(
        <String>['crash'],
        <FlutterCommand>[new _CrashCommand()],
        reportCrashes: true,
        flutterVersion: 'test-version',
      );

      expect(exitCode, 1);

      // Verify that we sent the crash report.
      expect(method, 'POST');
      expect(uri, new Uri(
        scheme: 'http',
        host: 'localhost',
        port: testPort,
        path: '/test-path',
        queryParameters: <String, String>{
          'product': 'Flutter_Tools',
          'version' : 'test-version',
        },
      ));
      BufferLogger logger = context[Logger];
      expect(logger.statusText, 'Sending crash report to Google.\n'
          'Crash report sent (report ID: test-report-id)\n');

      // Verify that we've written the crash report to disk.
      List<String> writtenFiles =
        (await tools.fs.directory('/').list(recursive: true).toList())
            .map((FileSystemEntity e) => e.path).toList();
      expect(writtenFiles, hasLength(1));
      expect(writtenFiles, contains('flutter_01.log'));
    });
  });
}

/// Throws a random error to simulate a CLI crash.
class _CrashCommand extends FlutterCommand {

  @override
  String get description => 'Simulates a crash';

  @override
  String get name => 'crash';

  @override
  Future<Null> runCommand() async {
    void fn1() {
      throw new StateError('Test bad state error');
    }

    void fn2() {
      fn1();
    }

    void fn3() {
      fn2();
    }

    fn3();
  }
}
