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
import 'package:flutter_tools/src/crash_reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import 'src/common.dart';
import 'src/context.dart';

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
      String method;
      Uri uri;
      Map<String, String> fields;

      CrashReportSender.initializeWith(MockClient((Request request) async {
        method = request.method;
        uri = request.url;

        // A very ad-hoc multipart request parser. Good enough for this test.
        String boundary = request.headers['Content-Type'];
        boundary = boundary.substring(boundary.indexOf('boundary=') + 9);
        fields = Map<String, String>.fromIterable(
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
          }
        );

        return Response(
            'test-report-id',
            200
        );
      }));

      final int exitCode = await tools.run(
        <String>['crash'],
        <FlutterCommand>[_CrashCommand()],
        reportCrashes: true,
        flutterVersion: 'test-version',
      );

      expect(exitCode, 1);

      // Verify that we sent the crash report.
      expect(method, 'POST');
      expect(uri, Uri(
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
          'version' : 'test-version',
        },
      ));
    }, overrides: <Type, Generator> {
      Platform: () => FakePlatform(
        operatingSystem: 'linux',
        environment: <String, String>{
          'FLUTTER_CRASH_SERVER_BASE_URL': 'https://localhost:12345/fake_server',
        },
        script: Uri(scheme: 'data'),
      ),
      Stdio: () => const _NoStderr(),
    });
  });

  // EngineCrash class tests
  test('EngineCrash class', () async {
    EngineCrash crashData = EngineCrash();

    // Full example backtrace data.
    crashData.addTraceLine("F/libc    (25429): Fatal signal 6 (SIGABRT), code -6 in tid 25446 (1.ui), pid 25429 (mple.helloworld)");
    crashData.addTraceLine("*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***");
    crashData.addTraceLine("Build fingerprint: 'google/bullhead/bullhead:8.1.0/OPM2.171019.029/4657601:user/release-keys'");
    crashData.addTraceLine("Revision: 'rev_1.0'");
    crashData.addTraceLine("ABI: 'arm'");
    crashData.addTraceLine("pid: 25429, tid: 25446, name: 1.ui  >>> com.example.helloworld <<<");
    crashData.addTraceLine("signal 6 (SIGABRT), code -6 (SI_TKILL), fault addr --------");
    crashData.addTraceLine("Abort message: '../../flutter/third_party/txt/src/txt/paragraph.cc:430: void txt::Paragraph::Layout(double, bool): assertion \"false\" failed'");
    crashData.addTraceLine("    r0 00000000  r1 00006366  r2 00000006  r3 00000008");
    crashData.addTraceLine("    r4 00006355  r5 00006366  r6 d88fbecc  r7 0000010c");
    crashData.addTraceLine("    r8 00000000  r9 d93edb15  sl da15e600  fp d74ad000");
    crashData.addTraceLine("    ip d88fe108  sp d88fbeb8  lr f63248b1  pc f631e39a  cpsr 20070030");
    crashData.addTraceLine("backtrace:");
    crashData.addTraceLine("    #00 pc 0001a39a  /system/lib/libc.so (abort+63)");
    crashData.addTraceLine("    #01 pc 0001a5bd  /system/lib/libc.so (__assert2+20)");
    crashData.addTraceLine("    #02 pc 011fb5b9  /data/app/com.example.helloworld-gfUKX_ShbxBIjWuT-44Wjw==/lib/arm/libflutter.so (offset 0x9a7000)");
    crashData.addTraceLine("    #03 pc 00a2b2e9  /data/app/com.example.helloworld-gfUKX_ShbxBIjWuT-44Wjw==/lib/arm/libflutter.so (offset 0x9a7000)");
    crashData.addTraceLine("    #04 pc 00a28017  /data/app/com.example.helloworld-gfUKX_ShbxBIjWuT-44Wjw==/lib/arm/libflutter.so (offset 0x9a7000)");
    crashData.addTraceLine("    #05 pc 00a03763  /data/app/com.example.helloworld-gfUKX_ShbxBIjWuT-44Wjw==/lib/arm/libflutter.so (offset 0x9a7000)");
    crashData.addTraceLine("    #06 pc 00a036bf  /data/app/com.example.helloworld-gfUKX_ShbxBIjWuT-44Wjw==/lib/arm/libflutter.so (offset 0x9a7000)");
    crashData.addTraceLine("    #07 pc 00a27b33  /data/app/com.example.helloworld-gfUKX_ShbxBIjWuT-44Wjw==/lib/arm/libflutter.so (offset 0x9a7000)");
    crashData.addTraceLine("    #08 pc 013df649  /data/app/com.example.helloworld-gfUKX_ShbxBIjWuT-44Wjw==/lib/arm/libflutter.so (offset 0x9a7000)");
    crashData.addTraceLine("    #09 pc 00000804  <anonymous:d7d80000>");

    expect(crashData.parseSignature(), "Fatal Abort message: '../../flutter/third_party/txt/src/txt/paragraph.cc:430: void txt::Paragraph::Layout(double, bool): assertion \"false\" failed'");
    expect(crashData.squashBacktrace(0, 1), 'F/libc    (25429): Fatal signal 6 (SIGABRT), code -6 in tid 25446 (1.ui), pid 25429 (mple.helloworld)\n');
    expect(crashData.squashBacktrace(0, 2), 'F/libc    (25429): Fatal signal 6 (SIGABRT), code -6 in tid 25446 (1.ui), pid 25429 (mple.helloworld)\n*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***\n');
    expect(crashData.squashBacktrace(1, 2), '*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***\n')
    expect(crashData.squashBacktrace(22, 22), '');
    expect(crashData.squashBacktrace(22, 23), '    #09 pc 00000804  <anonymous:d7d80000>');
    expect(crashData.squashBacktrace(35, 93), '');
    expect(crashData.squashBacktrace(17, 9), '');
    expect(crashData.lineContaining('backtrace', 12));
    expect(crashData.lineContaining('Revision:', 3));
    expect(crashData.lineContaining('#09 pc 00000804', 22));
    expect(crashData.lineContaining('F/libc', 0));
    expect(crashData.lineContaining('F', 0));
    expect(crashData.lineContaining('NOT IN THE DATA', -1));
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
  void add(_) {}

  @override
  void write(_) {}

  @override
  void writeAll(_, [__]) {}

  @override
  void writeln([_]) {}

  @override
  void writeCharCode(_) {}

  @override
  void addError(_, [__]) {}

  @override
  Future<dynamic> addStream(_) async {}

  @override
  Future<dynamic> flush() async {}

  @override
  Future<dynamic> close() async {}

  @override
  Future<dynamic> get done async {}
}
