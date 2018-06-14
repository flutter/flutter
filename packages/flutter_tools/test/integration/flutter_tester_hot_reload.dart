// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'util.dart';

void main() {
  Directory tempDir;

  setUp(() async {
    tempDir = await fs.systemTempDirectory.createTemp('test_app');
  });

  tearDown(() {
    try {
      tempDir?.deleteSync(recursive: true);
      tempDir = null;
    } catch (e) {
      // Ignored.
    }
  });

  group('FlutterTesterDevice', () {
    testUsingContext('can hot reload', () async {
      writePubspec(tempDir.path);
      writePackages(tempDir.path);
      await getPackages(tempDir.path);

      final String mainPath = fs.path.join(tempDir.path, 'lib', 'main.dart');
      writeFile(mainPath, r'''
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      home: new Container(),
    );
  }
}
''');

      const ProcessManager _processManager = const LocalProcessManager();
      final Process proc = await _processManager.start(
        <String>[
          fs.path.join(getFlutterRoot(), 'bin', 'flutter'),
          'run',
          '--machine',
          '-d',
          'flutter-tester',
          mainPath
        ],
        workingDirectory: tempDir.path,
      );

      String appId;
      bool ok;
      final Completer<Null> ready = new Completer<Null>();
      // Make a broadcast stream for stdout so we can have many listeners
      final StreamController<String> stdout = new StreamController<String>.broadcast();
      _transformToLines(proc.stdout).listen((String line) => stdout.add(line));
      // Capture stderr to a buffer for better error messages
      final StringBuffer stderr = new StringBuffer();
      _transformToLines(proc.stderr).listen(stderr.writeln);
      stdout.stream.listen(print);
      // Handle startup and log any non-JSON output to the error buffer (since
      // we're running in machine, we get errors in stdout).
      stdout.stream.listen((String line) {
        final dynamic json = _parseFlutterResponse(line);
        if (json != null && json['event'] == 'app.started') {
          appId = json['params']['appId'];
          ready.complete();
          ok = true;
        } else if (json == null) {
          stderr.writeln(line);
        }
      });
      // Set a flag on exit so we know we quit unexpectedly.
      proc.exitCode.then((int exitCode) => ok = false);
      await Future.any(<Future<void>>[ready.future, proc.exitCode]);
      if (!ok) {
        throw 'Failed to run test app.\n\n$stderr';
      }

      // Send a hot reload.
      final Future<Map<String, dynamic>> hotReloadRequest = _sendFlutterRequest(
          stdout.stream,
          proc.stdin,
          'app.restart',
          <String, dynamic>{'appId': appId, 'fullRestart': false});

      // Wait for a response or the app to quit
      await Future.any(<Future<void>>[proc.exitCode, hotReloadRequest]);

      if (!ok) {
        throw 'App crashed during hot reloads.\n\n$stderr';
      }

      final Map<String, dynamic> hotReloadResp = await hotReloadRequest;

      if (hotReloadResp['error'] != null)
        throw 'Unexpected error response ${hotReloadResp['error']}';

      // Send a stop request and wait for successfull exit.
      _sendFlutterRequest(stdout.stream, proc.stdin,
          'app.stop', <String, dynamic>{'appId': appId});
      final int result = await proc.exitCode;
      if (result != 0)
        throw 'Received unexpected exit code $result from run process.\n\n$stderr';
    });
  });
}

int id = 1;
Future<Map<String, dynamic>> _sendFlutterRequest(
    Stream<String> stdout, IOSink stdin, String method, dynamic params) async {
  final int requestId = id++;
  final Completer<Map<String, dynamic>> response = new Completer<Map<String, dynamic>>();
  final StreamSubscription<String> responseSubscription = stdout.listen((String line) {
    final Map<String, dynamic> json = _parseFlutterResponse(line);
    if (json != null && json['id'] == requestId) {
      response.complete(json);
    }
  });
  final Map<String, dynamic> req = <String, dynamic>{
    'id': requestId,
    'method': method,
    'params': params
  };
  final String jsonEncoded = json.encode(<Map<String, dynamic>>[req]);
  stdin.writeln(jsonEncoded);
  final Map<String, dynamic> result = await response.future;
  responseSubscription.cancel();
  return result;
}

Map<String, dynamic> _parseFlutterResponse(String line) {
  if (line.startsWith('[') && line.endsWith(']')) {
    try {
      return json.decode(line)[0];
    } catch (e) {
      // Not valid JSON, so likely some other output that was surrounded by [brackets]
      return null;
    }
  }
  return null;
}

Stream<String> _transformToLines(Stream<List<int>> byteStream) {
  return byteStream.transform(utf8.decoder).transform(const LineSplitter());
}
