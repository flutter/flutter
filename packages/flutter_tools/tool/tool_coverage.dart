// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:path/path.dart' as p;
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test_core/src/runner/hack_register_platform.dart' as hack; // ignore: implementation_imports
import 'package:test_core/src/executable.dart' as test; // ignore: implementation_imports
import 'package:vm_service_client/vm_service_client.dart';
import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite_platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/runner_suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/plugin/platform_helpers.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/environment.dart'; // ignore: implementation_imports
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';

/// Generates an lcov report for the flutter tool unit tests.
///
/// Example invocation:
///
///    dart tool/tool_coverage.dart.
Future<void> main(List<String> arguments) async {
  return runInContext(() async {
    final VMPlatform vmPlatform = VMPlatform();
    hack.registerPlatformPlugin(
      <Runtime>[Runtime.vm],
      () => vmPlatform,
    );
    await test.main(<String>['-x', 'no_coverage', '--no-color', '-r', 'compact', ...arguments]);
    await vmPlatform.close();
    return exitCode;
  });
}

/// A platform that loads tests in isolates spawned within this Dart process.
class VMPlatform extends PlatformPlugin {
  final CoverageCollector coverageCollector = CoverageCollector(
    flutterProject: FlutterProject.current(),
  );
  final String precompiledPath = p.join('.dart_tool', 'build', 'generated', 'flutter_tools');

  @override
  StreamChannel<void> loadChannel(String path, SuitePlatform platform) =>
      throw UnimplementedError();

  @override
  Future<RunnerSuite> load(String path, SuitePlatform platform,
      SuiteConfiguration suiteConfig, Object message) async {
    final ReceivePort receivePort = ReceivePort();
    Isolate isolate;
    try {
      isolate = await _spawnIsolate(path, receivePort.sendPort);
    } catch (error) {
      receivePort.close();
      rethrow;
    }
    final ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
    final dynamic channel = IsolateChannel<Object>.connectReceive(receivePort)
        .transformStream(StreamTransformer<Object, Object>.fromHandlers(handleDone: (EventSink<Object> sink) async {
      await coverageCollector.collectCoverageIsolate(info.serverUri);
      isolate.kill();
      sink.close();
    }));

    VMEnvironment environment;
    final RunnerSuiteController controller = deserializeSuite(
      path,
      platform,
      suiteConfig,
      environment,
      channel,
      message,
    );
    return await controller.suite;
  }

  /// Spawns an isolate and passes it [message].
  ///
  /// This isolate connects an [IsolateChannel] to [message] and sends the
  /// serialized tests over that channel.
  Future<Isolate> _spawnIsolate(String path, SendPort message) async {
    return _spawnPrecompiledIsolate(path, message, precompiledPath);
  }

  Future<Isolate> _spawnPrecompiledIsolate(String testPath, SendPort message, String precompiledPath) async {
    testPath = p.absolute(p.join(precompiledPath, testPath) + '.vm_test.dart');
    testPath = testPath.substring(0, testPath.length - '.dart'.length) + '.vm.app.dill';
    return await Isolate.spawnUri(p.toUri(testPath), <String>[], message,
      packageConfig: p.toUri('.packages'),
      checked: true,
    );
  }

  @override
  Future<void> close() async {
    final String lcovData = await coverageCollector.finalizeCoverage();
    final String outputLcovPath = p.join('coverage', 'lcov.info');
    File(outputLcovPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(lcovData);
  }
}

class VMEnvironment implements Environment {
  VMEnvironment(this.observatoryUrl, this._isolate);

  @override
  final bool supportsDebugging = false;

  @override
  final Uri observatoryUrl;

  /// The VM service isolate object used to control this isolate.
  final VMIsolateRef _isolate;


  @override
  Uri get remoteDebuggerUrl => null;

  @override
  Stream<void> get onRestart => StreamController<dynamic>.broadcast().stream;

  @override
  CancelableOperation<void> displayPause() {
    final CancelableCompleter<dynamic> completer = CancelableCompleter<dynamic>(onCancel: () => _isolate.resume());

    completer.complete(_isolate.pause().then((dynamic _) => _isolate.onPauseOrResume
        .firstWhere((VMPauseEvent event) => event is VMResumeEvent)));

    return completer.operation;
  }
}
