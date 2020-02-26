// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:coverage/coverage.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';
import 'package:path/path.dart' as path;
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test_api/src/backend/suite_platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/runner_suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/plugin/platform_helpers.dart'; // ignore: implementation_imports
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';

/// Generates an lcov report for the flutter tool unit tests.
///
/// Example invocation:
///
///     dart tool/tool_coverage.dart
Future<void> main(List<String> arguments) async {
  return runInContext(() async {
    final VMPlatform vmPlatform = VMPlatform();
    const TestWrapper test = TestWrapper();
    test.registerPlatformPlugin(
      <Runtime>[Runtime.vm],
      () => vmPlatform,
    );
    if (arguments.isEmpty) {
      arguments = <String>[
        path.join('test', 'general.shard'),
        path.join('test', 'commands.shard', 'hermetic'),
      ];
    }
    await test.main(<String>[
      '--no-color',
      '-r', 'compact',
      '-j', '1',
      ...arguments
    ]);
    exit(exitCode);
  });
}

/// A platform that loads tests in isolates spawned within this Dart process.
class VMPlatform extends PlatformPlugin {
  final CoverageCollector coverageCollector = CoverageCollector(
    libraryPredicate: (String libraryName) => libraryName.contains(FlutterProject.current().manifest.appName),
  );
  final Map<String, Future<void>> _pending = <String, Future<void>>{};
  final String precompiledPath = path.join('.dart_tool', 'build', 'generated', 'flutter_tools');

  @override
  StreamChannel<void> loadChannel(String codePath, SuitePlatform platform) =>
      throw UnimplementedError();

  @override
  Future<RunnerSuite> load(
    String codePath,
    SuitePlatform platform,
    SuiteConfiguration suiteConfig,
    Object message,
  ) async {
    final ReceivePort receivePort = ReceivePort();
    Isolate isolate;
    try {
      isolate = await _spawnIsolate(codePath, receivePort.sendPort);
    } catch (error) {
      receivePort.close();
      rethrow;
    }
    final Completer<void> completer = Completer<void>();
    // When this is completed we remove it from the map of pending so we can
    // log the futures that get "stuck".
    unawaited(completer.future.whenComplete(() {
      _pending.remove(codePath);
    }));
    final ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
    final StreamChannel<Object> channel = IsolateChannel<Object>.connectReceive(receivePort)
      .transformStream(StreamTransformer<Object, Object>.fromHandlers(
        handleDone: (EventSink<Object> sink) async {
          try {
            // this will throw if collection fails.
            await coverageCollector.collectCoverageIsolate(info.serverUri);
          } finally {
            isolate.kill(priority: Isolate.immediate);
            isolate = null;
            sink.close();
            completer.complete();
          }
        },
        handleError: (dynamic error, StackTrace stackTrace, EventSink<Object> sink) {
          isolate.kill(priority: Isolate.immediate);
          isolate = null;
          sink.close();
          completer.complete();
        },
      ));

    final RunnerSuiteController controller = deserializeSuite(
      codePath,
      platform,
      suiteConfig,
      null,
      channel,
      message,
    );
    _pending[codePath] = completer.future;
    return await controller.suite;
  }

  /// Spawns an isolate and passes it [message].
  ///
  /// This isolate connects an [IsolateChannel] to [message] and sends the
  /// serialized tests over that channel.
  Future<Isolate> _spawnIsolate(String codePath, SendPort message) async {
    String testPath = path.absolute(path.join(precompiledPath, codePath) + '.vm_test.dart');
    testPath = testPath.substring(0, testPath.length - '.dart'.length) + '.vm.app.dill';
    return await Isolate.spawnUri(path.toUri(testPath), <String>[], message,
      packageConfig: path.toUri('.packages'),
      checked: true,
    );
  }

  @override
  Future<void> close() async {
    try {
      await Future.wait(_pending.values).timeout(const Duration(minutes: 1));
    } on TimeoutException {
      // TODO(jonahwilliams): resolve whether there are any specific tests that
      // get stuck or if it is a general infra issue with how we are collecting
      // coverage.
      // Log tests that are "Stuck" waiting for coverage.
      print('The following tests timed out waiting for coverage:');
      print(_pending.keys.join(', '));
    }
    final String packagePath = Directory.current.path;
    final Resolver resolver = Resolver(packagesPath: '.packages');
    final Formatter formatter = LcovFormatter(resolver, reportOn: <String>[
      'lib',
    ], basePath: packagePath);
    final String result = await coverageCollector.finalizeCoverage(
      formatter: formatter,
    );
    final String outputLcovPath = path.join('coverage', 'lcov.info');
    File(outputLcovPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(result);
  }
}
