// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/runner.dart' as tools;
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/crash_reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'src/context.dart';

void main() {
  group('crash reporting', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() async {
      tools.crashFileSystem = new MemoryFileSystem();
      tools.writelnStderr = ([_]) { };
      setExitFunctionForTests((_) { });
    });

    tearDown(() {
      tools.crashFileSystem = const LocalFileSystem();
      tools.writelnStderr = stderr.writeln;
      restoreExitFunction();
    });

    testUsingContext('should send crash reports', () async {
      String method;
      Uri uri;
      Map<String, String> fields;

      CrashReportSender.initializeWith(new MockClient((Request request) async {
        method = request.method;
        uri = request.url;

        // A very ad-hoc multipart request parser. Good enough for this test.
        String boundary = request.headers['Content-Type'];
        boundary = boundary.substring(boundary.indexOf('boundary=') + 9);
        fields = new Map<String, String>.fromIterable(
          utf8.decode(request.bodyBytes)
              .split('--$boundary')
              .map<List<String>>((String part) {
                final Match nameMatch = new RegExp(r'name="(.*)"').firstMatch(part);
                if (nameMatch == null)
                  return null;
                final String name = nameMatch[1];
                final String value = part.split('\n').skip(2).join('\n').trim();
                return <String>[name, value];
              })
              .where((List<String> pair) => pair != null),
          key: (dynamic key) {
            final List<String> pair = key;
            return pair[0];
          },
          value: (dynamic value) {
            final List<String> pair = value;
            return pair[1];
          }
        );

        return new Response(
            'test-report-id',
            200
        );
      }));

      final int exitCode = await tools.run(
        <String>['crash'],
        <FlutterCommand>[new _CrashCommand()],
        reportCrashes: true,
        flutterVersion: 'test-version',
      );

      expect(exitCode, 1);

      // Verify that we sent the crash report.
      expect(method, 'POST');
      expect(uri, new Uri(
        scheme: 'https',
        host: 'clients2.google.com',
        port: 443,
        path: '/cr/report',
        queryParameters: <String, String>{
          'product': 'Flutter_Tools',
          'version' : 'test-version',
        },
      ));
      expect(fields['uuid'], '00000000-0000-4000-0000-000000000000');
      expect(fields['product'], 'Flutter_Tools');
      expect(fields['version'], 'test-version');
      expect(fields['osName'], platform.operatingSystem);
      expect(fields['osVersion'], 'fake OS name and version');
      expect(fields['type'], 'DartError');
      expect(fields['error_runtime_type'], 'StateError');

      final BufferLogger logger = context[Logger];
      expect(logger.statusText, 'Sending crash report to Google.\n'
          'Crash report sent (report ID: test-report-id)\n');

      // Verify that we've written the crash report to disk.
      final List<String> writtenFiles =
        (await tools.crashFileSystem.directory('/').list(recursive: true).toList())
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
