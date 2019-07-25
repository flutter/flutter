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

import 'package:flutter_tools/runner.dart' as tools;
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/reporting/crash_reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:pedantic/pedantic.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('crash reporting', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() async {
      tools.crashFileSystem = MemoryFileSystem();
      setExitFunctionForTests((_) { });
    });

    tearDown(() {
      tools.crashFileSystem = const LocalFileSystem();
      restoreExitFunction();
    });

    testUsingContext('should send crash reports', () async {
      final RequestInfo requestInfo = RequestInfo();

      CrashReportSender.initializeWith(MockCrashReportSender(requestInfo));
      final int exitCode = await tools.run(
        <String>['crash'],
        <FlutterCommand>[_CrashCommand()],
        reportCrashes: true,
        flutterVersion: 'test-version',
      );
      expect(exitCode, 1);

      await verifyCrashReportSent(requestInfo);
    }, overrides: <Type, Generator>{
      Stdio: () => const _NoStderr(),
    });

    testUsingContext('should send crash reports when async throws', () async {
      final Completer<int> exitCodeCompleter = Completer<int>();
      setExitFunctionForTests((int exitCode) {
        exitCodeCompleter.complete(exitCode);
      });

      final RequestInfo requestInfo = RequestInfo();

      CrashReportSender.initializeWith(MockCrashReportSender(requestInfo));

      unawaited(tools.run(
        <String>['crash'],
        <FlutterCommand>[_CrashAsyncCommand()],
        reportCrashes: true,
        flutterVersion: 'test-version',
      ));
      expect(await exitCodeCompleter.future, equals(1));
      await verifyCrashReportSent(requestInfo);
    }, overrides: <Type, Generator>{
      Stdio: () => const _NoStderr(),
    });

    testUsingContext('should not send a crash report if on a user-branch', () async {
      String method;
      Uri uri;

      CrashReportSender.initializeWith(MockClient((Request request) async {
        method = request.method;
        uri = request.url;

        return Response(
          'test-report-id',
          200,
        );
      }));

      final int exitCode = await tools.run(
        <String>['crash'],
        <FlutterCommand>[_CrashCommand()],
        reportCrashes: true,
        flutterVersion: '[user-branch]/v1.2.3',
      );

      expect(exitCode, 1);

      // Verify that the report wasn't sent
      expect(method, null);
      expect(uri, null);

      final BufferLogger logger = context.get<Logger>();
      expect(logger.statusText, '');
    }, overrides: <Type, Generator>{
      Stdio: () => const _NoStderr(),
    });

    testUsingContext('can override base URL', () async {
      Uri uri;
      CrashReportSender.initializeWith(MockClient((Request request) async {
        uri = request.url;
        return Response('test-report-id', 200);
      }));

      final int exitCode = await tools.run(
        <String>['crash'],
        <FlutterCommand>[_CrashCommand()],
        reportCrashes: true,
        flutterVersion: 'test-version',
      );

      expect(exitCode, 1);

      // Verify that we sent the crash report.
      expect(uri, isNotNull);
      expect(uri, Uri(
        scheme: 'https',
        host: 'localhost',
        port: 12345,
        path: '/fake_server',
        queryParameters: <String, String>{
          'product': 'Flutter_Tools',
          'version': 'test-version',
        },
      ));
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(
        operatingSystem: 'linux',
        environment: <String, String>{
          'HOME': '/',
          'FLUTTER_CRASH_SERVER_BASE_URL': 'https://localhost:12345/fake_server',
        },
        script: Uri(scheme: 'data'),
      ),
      Stdio: () => const _NoStderr(),
    });
  });
}

class RequestInfo {
  String method;
  Uri uri;
  Map<String, String> fields;
}

Future<void> verifyCrashReportSent(RequestInfo crashInfo) async {
  // Verify that we sent the crash report.
  expect(crashInfo.method, 'POST');
  expect(crashInfo.uri, Uri(
    scheme: 'https',
    host: 'clients2.google.com',
    port: 443,
    path: '/cr/report',
    queryParameters: <String, String>{
      'product': 'Flutter_Tools',
      'version': 'test-version',
    },
  ));
  expect(crashInfo.fields['uuid'], '00000000-0000-4000-0000-000000000000');
  expect(crashInfo.fields['product'], 'Flutter_Tools');
  expect(crashInfo.fields['version'], 'test-version');
  expect(crashInfo.fields['osName'], platform.operatingSystem);
  expect(crashInfo.fields['osVersion'], 'fake OS name and version');
  expect(crashInfo.fields['type'], 'DartError');
  expect(crashInfo.fields['error_runtime_type'], 'StateError');
  expect(crashInfo.fields['error_message'], 'Bad state: Test bad state error');
  expect(crashInfo.fields['comments'], 'crash');

  final BufferLogger logger = context.get<Logger>();
  expect(logger.statusText, 'Sending crash report to Google.\n'
      'Crash report sent (report ID: test-report-id)\n');

  // Verify that we've written the crash report to disk.
  final List<String> writtenFiles =
  (await tools.crashFileSystem.directory('/').list(recursive: true).toList())
      .map((FileSystemEntity e) => e.path).toList();
  expect(writtenFiles, hasLength(1));
  expect(writtenFiles, contains('flutter_01.log'));
}

class MockCrashReportSender extends MockClient {
  MockCrashReportSender(RequestInfo crashInfo) : super((Request request) async {
      crashInfo.method = request.method;
      crashInfo.uri = request.url;

      // A very ad-hoc multipart request parser. Good enough for this test.
      String boundary = request.headers['Content-Type'];
      boundary = boundary.substring(boundary.indexOf('boundary=') + 9);
      crashInfo.fields = Map<String, String>.fromIterable(
        utf8.decode(request.bodyBytes)
            .split('--$boundary')
            .map<List<String>>((String part) {
          final Match nameMatch = RegExp(r'name="(.*)"').firstMatch(part);
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
        },
      );

      return Response(
        'test-report-id',
        200,
      );
    });
}

/// Throws a random error to simulate a CLI crash.
class _CrashCommand extends FlutterCommand {

  @override
  String get description => 'Simulates a crash';

  @override
  String get name => 'crash';

  @override
  Future<FlutterCommandResult> runCommand() async {
    void fn1() {
      throw StateError('Test bad state error');
    }

    void fn2() {
      fn1();
    }

    void fn3() {
      fn2();
    }

    fn3();

    return null;
  }
}

/// Throws StateError from async callback.
class _CrashAsyncCommand extends FlutterCommand {

  @override
  String get description => 'Simulates a crash';

  @override
  String get name => 'crash';

  @override
  Future<FlutterCommandResult> runCommand() async {
    Timer.run(() {
      throw StateError('Test bad state error');
    });
    return Completer<FlutterCommandResult>().future; // expect StateError
  }
}

class _NoStderr extends Stdio {
  const _NoStderr();

  @override
  IOSink get stderr => const _NoopIOSink();
}

class _NoopIOSink implements IOSink {
  const _NoopIOSink();

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(_) => throw UnsupportedError('');

  @override
  void add(_) { }

  @override
  void write(_) { }

  @override
  void writeAll(_, [ __ = '' ]) { }

  @override
  void writeln([ _ = '' ]) { }

  @override
  void writeCharCode(_) { }

  @override
  void addError(_, [ __ ]) { }

  @override
  Future<dynamic> addStream(_) async { }

  @override
  Future<dynamic> flush() async { }

  @override
  Future<dynamic> close() async { }

  @override
  Future<dynamic> get done async { }
}
