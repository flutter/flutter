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

// Set this to true for debugging to get JSON written to stdout.
const bool _printJsonAndStderr = false;
Directory _tempDir;

void main() {

  setUp(() async {
    _tempDir = await fs.systemTempDirectory.createTemp('test_app');
  });

  tearDown(() {
    try {
      _tempDir?.deleteSync(recursive: true);
      _tempDir = null;
    } catch (e) {
      // Don't fail tests if we failed to clean up temp folder.
    }
  });

  group('FlutterTesterDevice', () {
    testUsingContext('can hot reload', () async {
      await _setupSampleProject();

      // TODO(dantup): Is there a better way than spawning a proc? This breaks debugging..
      // However, there's a lot of logic inside RunCommand that wouldn't be good
      // to duplicate here.
      final Process proc = await _runFlutter(_tempDir);

      // Make broadcast streams so we can have many listeners
      final StreamController<String> stdout = new StreamController<String>.broadcast();
      final StreamController<String> stderr = new StreamController<String>.broadcast();
      _transformToLines(proc.stdout).listen((String line) => stdout.add(line));
      _transformToLines(proc.stderr).listen((String line) => stderr.add(line));

      // Capture stderr to a buffer for better error messages
      final StringBuffer errorBuffer = new StringBuffer();
      stderr.stream.listen(errorBuffer.writeln);

      if (_printJsonAndStderr) {
        stdout.stream.listen(print);
        stderr.stream.listen(print);
      }

      try {
        final Map<String, dynamic> started = await _waitFor(stdout.stream, stderr.stream, event: 'app.started');
        final String appId = started['params']['appId'];

        final Map<String, dynamic> hotReloadResp = await _send(
            stdout.stream,
            stderr.stream,
            proc.stdin,
            'app.restart',
            <String, dynamic>{'appId': appId, 'fullRestart': false});

        if (hotReloadResp['error'] != null || hotReloadResp['result'] == false)
          throw 'Unexpected error response: ${hotReloadResp['error']}\n\n${errorBuffer.toString()}';

        // Send a stop request and wait for exit.
        await _send(stdout.stream, stderr.stream, proc.stdin, 'app.stop', <String, dynamic>{'appId': appId});
        await proc.exitCode;
      } catch (e) {
        throw '$e\n${errorBuffer.toString()}';
      }
    });
  }, timeout: const Timeout.factor(3));
}

Future<void> _setupSampleProject() async {
  writePubspec(_tempDir.path);
  writePackages(_tempDir.path);
  await getPackages(_tempDir.path);
  
  final String mainPath = fs.path.join(_tempDir.path, 'lib', 'main.dart');
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
}

Future<Process> _runFlutter(Directory projectDir) async {
  final String flutterBin = fs.path.join(getFlutterRoot(), 'bin', 'flutter');
  final List<String> command = <String>[
    flutterBin,
    'run',
    '--machine',
    '-d',
    'flutter-tester'
  ];
  if (_printJsonAndStderr) {
    print('Spawning $command in ${projectDir.path}');
  }
  const ProcessManager _processManager = const LocalProcessManager();
  final Process proc = await _processManager.start(
    command,
    workingDirectory: projectDir.path,
    environment: <String, String>{
      'FLUTTER_TEST': 'true',
    }
  );
  return proc;
}

int id = 1;
Future<Map<String, dynamic>> _send(Stream<String> stdout, Stream<String> stderr, IOSink stdin, String method, dynamic params) async {
  final int requestId = id++;
  final Map<String, dynamic> req = <String, dynamic>{
    'id': requestId,
    'method': method,
    'params': params
  };
  final String jsonEncoded = json.encode(<Map<String, dynamic>>[req]);
  if (_printJsonAndStderr) {
    print(jsonEncoded);
  }
  stdin.writeln(jsonEncoded);
  return _waitFor(stdout, stderr, id: requestId);
}

Future<Map<String, dynamic>> _waitFor(Stream<String> stdout, Stream<String> stderr, {String event, int id}) async {
	// Capture output to a buffer so if we don't get the repsonse we want we can show
  // the output that did arrive in the timeout errr.
	final StringBuffer messages = new StringBuffer();
	stdout.listen(messages.writeln);
  stderr.listen(messages.writeln);

  final Completer<Map<String, dynamic>> response = new Completer<Map<String, dynamic>>();
  final StreamSubscription<String> sub = stdout.listen((String line) {
    final dynamic json = _parseFlutterResponse(line);
    if (json == null) {
      return;
    }
    else if ((event != null && json['event'] == event) || (id != null && json['id'] == id)) {
      response.complete(json);
    }
  });
  // TODO(dantup): Why can't I remove this Null/Null/Object?
  final Future<Null> timeout = Future<Null>.delayed(const Duration(seconds: 30))
      .then((Object a) => throw 'Did not receive expected event/response within 10s.\n'
          'Did get:\n${messages.toString()}');
  try {
    return await Future.any(<Future<Map<String, dynamic>>>[response.future, timeout]);
  } finally {
    sub.cancel();
  }
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
