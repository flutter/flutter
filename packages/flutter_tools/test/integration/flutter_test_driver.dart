// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:process/process.dart';
import 'package:vm_service_client/vm_service_client.dart';

import '../src/common.dart';

// Set this to true for debugging to get JSON written to stdout.
const bool _printJsonAndStderr = false;

class FlutterTestDriver {
  Directory _projectFolder;
  Process _proc;
  final StreamController<String> _stdout = new StreamController<String>.broadcast();
  final StreamController<String> _stderr = new StreamController<String>.broadcast();
  final StringBuffer _errorBuffer = new StringBuffer();
  String _currentRunningAppId;

  FlutterTestDriver(this._projectFolder);

  VMServiceClient vmService;
  String get lastErrorInfo => _errorBuffer.toString();

  // TODO(dantup): Is there a better way than spawning a proc? This breaks debugging..
  // However, there's a lot of logic inside RunCommand that wouldn't be good
  // to duplicate here.
  Future<void> run({bool withDebugger = false}) async {
    _proc = await _runFlutter(_projectFolder);
    _transformToLines(_proc.stdout).listen((String line) => _stdout.add(line));
    _transformToLines(_proc.stderr).listen((String line) => _stderr.add(line));

    // Capture stderr to a buffer so we can show it all if any requests fail.
    _stderr.stream.listen(_errorBuffer.writeln);

    // This is just debug printing to aid running/debugging tests locally.
    if (_printJsonAndStderr) {
      _stdout.stream.listen(print);
      _stderr.stream.listen(print);
    }

    // Set this up now, but we don't wait it yet. We want to make sure we don't
    // miss it while waiting for debugPort below.
    final Future<Map<String, dynamic>> started = _waitFor(event: 'app.started');

    if (withDebugger) {
      final Future<Map<String, dynamic>> debugPort = _waitFor(event: 'app.debugPort');
      final String wsUri = (await debugPort)['params']['wsUri'];
      vmService = new VMServiceClient.connect(wsUri);
    }

    // Now await the started event; if it had already happened the future will
    // have already completed.
    _currentRunningAppId = (await started)['params']['appId'];
  }

  Future<void> hotReload() async {
    if (_currentRunningAppId == null)
      throw new Exception('App has not started yet');

    final dynamic hotReloadResp = await _sendRequest(
        'app.restart',
        <String, dynamic>{'appId': _currentRunningAppId, 'fullRestart': false}
    );

    if (hotReloadResp == null || hotReloadResp['code'] != 0)
      throw 'Hot reload request failed\n\n${_errorBuffer.toString()}';
  }

  Future<int> stop() async {
    if (_currentRunningAppId != null) {
      await _sendRequest(
          'app.stop',
          <String, dynamic>{'appId': _currentRunningAppId}
      );
    }
    _currentRunningAppId = null;
    return _proc.exitCode;
  }

  Future<Process> _runFlutter(Directory projectDir) async {
    final String flutterBin = fs.path.join(getFlutterRoot(), 'bin', 'flutter');
    final List<String> command = <String>[
        flutterBin,
        'run',
        '--machine',
        '-d',
        'flutter-tester',
        '--observatory-port=0',
    ];
    if (_printJsonAndStderr) {
      print('Spawning $command in ${projectDir.path}');
    }
    const ProcessManager _processManager = const LocalProcessManager();
    return _processManager.start(
        command,
        workingDirectory: projectDir.path,
        environment: <String, String>{'FLUTTER_TEST': 'true'}
    );
  }

  Future<void> addBreakpoint(String path, int line) async {
    final VM vm = await vmService.getVM();
    final VMIsolate isolate = await vm.isolates.first.load();
    await isolate.addBreakpoint(path, line);
  }

  Future<VMIsolate> waitForBreakpointHit() async {
    final VM vm = await vmService.getVM();
    final VMIsolate isolate = await vm.isolates.first.load();
    await _withTimeout<void>(
        isolate.waitUntilPaused(),
        () => 'Isolate did not pause'
    );
    return isolate.load();
  }

  Future<VMIsolate> breakAt(String path, int line) async {
    await addBreakpoint(path, line);
    await hotReload();
    return waitForBreakpointHit();
  }

  Future<VMInstanceRef> evaluateExpression(String expression) async {
    final VM vm = await vmService.getVM();
    final VMIsolate isolate = await vm.isolates.first.load();
    final VMStack stack = await isolate.getStack();
    if (stack.frames.isEmpty) {
      throw new Exception('Stack is empty; unable to evaluate expression');
    }
    final VMFrame topFrame = stack.frames.first;
    return _withTimeout(
        topFrame.evaluate(expression),
        () => 'Timed out evaluating expression'
    );
  }

  Future<Map<String, dynamic>> _waitFor({String event, int id}) async {
    // Capture output to a buffer so if we don't get the repsonse we want we can show
    // the output that did arrive in the timeout errr.
    final StringBuffer messages = new StringBuffer();
    _stdout.stream.listen(messages.writeln);
    _stderr.stream.listen(messages.writeln);

    final Completer<Map<String, dynamic>> response = new Completer<Map<String, dynamic>>();
    final StreamSubscription<String> sub = _stdout.stream.listen((String line) {
      final dynamic json = _parseFlutterResponse(line);
      if (json == null) {
        return;
      } else if (
          (event != null && json['event'] == event)
          || (id != null && json['id'] == id)) {
        response.complete(json);
      }
    });
    
    return _withTimeout(
        response.future,
        () {
          if (event != null)
            return 'Did not receive expected $event event.\nDid get:\n${messages.toString()}';
          else if (id != null)
            return 'Did not receive response to request "$id".\nDid get:\n${messages.toString()}';
        }
    ).whenComplete(() => sub.cancel());
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

  int id = 1;
  Future<dynamic> _sendRequest(String method, dynamic params) async {
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
    // Set up the response future before we send the request to avoid any
    // races.
    final Future<Map<String, dynamic>> responseFuture = _waitFor(id: requestId);
    _proc.stdin.writeln(jsonEncoded);
    final Map<String, dynamic> resp = await responseFuture;

    if (resp['error'] != null || resp['result'] == null)
      throw 'Unexpected error response: ${resp['error']}\n\n${_errorBuffer.toString()}';

    return resp['result'];
  }
}

Future<T> _withTimeout<T>(Future<T> f, [
    String Function() getDebugMessage,
    int timeoutSeconds = 20,
  ]) {
  final Future<T> timeout =
      new Future<T>.delayed(new Duration(seconds: timeoutSeconds))
          .then((Object _) => throw new Exception(getDebugMessage()));

  return Future.any(<Future<T>>[f, timeout]);
}

Stream<String> _transformToLines(Stream<List<int>> byteStream) {
  return byteStream.transform(utf8.decoder).transform(const LineSplitter());
}
