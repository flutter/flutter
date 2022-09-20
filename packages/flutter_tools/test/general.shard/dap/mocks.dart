// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dds/dap.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/debug_adapters/flutter_adapter.dart';
import 'package:flutter_tools/src/debug_adapters/flutter_test_adapter.dart';

/// A [FlutterDebugAdapter] that captures what process/args will be launched.
class MockFlutterDebugAdapter extends FlutterDebugAdapter {
  factory MockFlutterDebugAdapter({
    required FileSystem fileSystem,
    required Platform platform,
    bool simulateAppStarted = true,
  }) {
    final StreamController<List<int>> stdinController = StreamController<List<int>>();
    final StreamController<List<int>> stdoutController = StreamController<List<int>>();
    final ByteStreamServerChannel channel = ByteStreamServerChannel(stdinController.stream, stdoutController.sink, null);

    return MockFlutterDebugAdapter._(
      stdinController.sink,
      stdoutController.stream,
      channel,
      fileSystem: fileSystem,
      platform: platform,
      simulateAppStarted: simulateAppStarted,
    );
  }

  MockFlutterDebugAdapter._(
    this.stdin,
    this.stdout,
    ByteStreamServerChannel channel, {
    required FileSystem fileSystem,
    required Platform platform,
    this.simulateAppStarted = true,
  }) : super(channel, fileSystem: fileSystem, platform: platform);

  final StreamSink<List<int>> stdin;
  final Stream<List<int>> stdout;
  final bool simulateAppStarted;

  late String executable;
  late List<String> processArgs;
  late Map<String, String>? env;
  final List<String> flutterRequests = <String>[];

  @override
  Future<void> launchAsProcess({
    required String executable,
    required List<String> processArgs,
    required Map<String, String>? env,
  }) async {
    this.executable = executable;
    this.processArgs = processArgs;
    this.env = env;

    // Pretend we launched the app and got the app.started event so that
    // launchRequest will complete.
    if (simulateAppStarted) {
      appId = 'TEST';
      appStartedCompleter.complete();
    }
  }

  @override
  Future<Object?> sendFlutterRequest(
    String method,
    Map<String, Object?>? params, {
    bool failSilently = true,
  }) {
    flutterRequests.add(method);
    return super.sendFlutterRequest(method, params, failSilently: failSilently);
  }

  @override
  Future<void> get debuggerInitialized {
    // If we were mocking debug mode, then simulate the debugger initializing.
    return enableDebugger
        ? Future<void>.value()
        : throw StateError('Invalid attempt to wait for debuggerInitialized when not debugging');
  }
}

/// A [FlutterTestDebugAdapter] that captures what process/args will be launched.
class MockFlutterTestDebugAdapter extends FlutterTestDebugAdapter {
  factory MockFlutterTestDebugAdapter({
    required FileSystem fileSystem,
    required Platform platform,
  }) {
    final StreamController<List<int>> stdinController = StreamController<List<int>>();
    final StreamController<List<int>> stdoutController = StreamController<List<int>>();
    final ByteStreamServerChannel channel = ByteStreamServerChannel(stdinController.stream, stdoutController.sink, null);

    return MockFlutterTestDebugAdapter._(
      stdinController.sink,
      stdoutController.stream,
      channel,
      fileSystem: fileSystem,
      platform: platform,
    );
  }

  MockFlutterTestDebugAdapter._(
    this.stdin,
    this.stdout,
    ByteStreamServerChannel channel, {
    required FileSystem fileSystem,
    required Platform platform,
  }) : super(channel, fileSystem: fileSystem, platform: platform);

  final StreamSink<List<int>> stdin;
  final Stream<List<int>> stdout;

  late String executable;
  late List<String> processArgs;
  late Map<String, String>? env;

  @override
  Future<void> launchAsProcess({
    required String executable,
    required List<String> processArgs,
    required Map<String, String>? env,
  }) async {
    this.executable = executable;
    this.processArgs = processArgs;
    this.env = env;
  }

  @override
  Future<void> get debuggerInitialized {
    // If we were mocking debug mode, then simulate the debugger initializing.
    return enableDebugger
        ? Future<void>.value()
        : throw StateError('Invalid attempt to wait for debuggerInitialized when not debugging');
  }
}

class MockRequest extends Request {
  MockRequest()
      : super.fromMap(<String, Object?>{
          'command': 'mock_command',
          'type': 'mock_type',
          'seq': _requestId++,
        });

  static int _requestId = 1;
}
