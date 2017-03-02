// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/executable.dart' as tools;
import 'package:flutter_tools/src/base/os.dart' as os;
import 'package:flutter_tools/src/crash_reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'src/context.dart';

void main() {
  group('crash reporting', () {
    int testPort;

    setUp(() async {
      testPort = await os.findAvailablePort();
      overrideBaseCrashUrlForTesting(Uri.parse('http://localhost:$testPort/test-path'));
    });

    tearDown(() {
      resetBaseCrashUrlForTesting();
    });

    testUsingContext('should send crash reports', () async {
      Completer<Null> reportReceived = new Completer<Null>();
      String method;
      Uri uri;

      HttpServer server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V6, testPort);
      StreamSubscription<HttpRequest> sub;
      sub = server.listen(expectAsync1<Future<Null>, HttpRequest>((HttpRequest request) async {
        method = request.method;
        uri = request.uri;
        request.response.statusCode = 200;
        request.response.write('test-report-id');
        await request.response.close();
        await sub.cancel();
        await server.close();
        reportReceived.complete();
      }));

      tools.run(<String>['crash'], <FlutterCommand>[new _CrashCommand()]);

      await reportReceived.future;
      expect(method, 'POST');
      String version = FlutterVersion.getVersionString();
      expect(uri, new Uri(
        path: '/test-path',
        queryParameters: <String, String>{
          'product': 'Flutter_Tools',
          'version' : version,
        },
      ));
      BufferLogger logger = context[Logger];
      expect(logger.statusText, 'Sending crash report to Google.\n'
          'Crash report sent (report ID: test-report-id)\n');
    }, overrides: <Type, Generator>{
      FileSystem: () => new MemoryFileSystem(),
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
