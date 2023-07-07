// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:coverage/coverage.dart';
import 'package:path/path.dart' as p;
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test_api/backend.dart'; // ignore: deprecated_member_use
import 'package:test_core/src/runner/vm/test_compiler.dart';
import 'package:vm_service/vm_service.dart' hide Isolate;
import 'package:vm_service/vm_service_io.dart';

import '../../runner/configuration.dart';
import '../../runner/environment.dart';
import '../../runner/load_exception.dart';
import '../../runner/platform.dart';
import '../../runner/plugin/platform_helpers.dart';
import '../../runner/runner_suite.dart';
import '../../runner/suite.dart';
import '../../util/dart.dart' as dart;
import '../../util/package_config.dart';
import '../package_version.dart';
import 'environment.dart';

var _shouldPauseAfterTests = false;

/// A platform that loads tests in isolates spawned within this Dart process.
class VMPlatform extends PlatformPlugin {
  /// The test runner configuration.
  final _config = Configuration.current;
  final _compiler = TestCompiler(
      p.join(p.current, '.dart_tool', 'test', 'incremental_kernel'));
  final _closeMemo = AsyncMemoizer<void>();

  @override
  Future<RunnerSuite?> load(String path, SuitePlatform platform,
      SuiteConfiguration suiteConfig, Map<String, Object?> message) async {
    assert(platform.runtime == Runtime.vm);

    _setupPauseAfterTests();

    var receivePort = ReceivePort();
    Isolate? isolate;
    try {
      isolate =
          await _spawnIsolate(path, receivePort.sendPort, suiteConfig.metadata);
      if (isolate == null) return null;
    } catch (error) {
      receivePort.close();
      rethrow;
    }

    VmService? client;
    StreamSubscription<Event>? eventSub;
    // Typical test interaction will go across `channel`, `outerChannel` adds
    // additional communication directly between the test bootstrapping and this
    // platform to enable pausing after tests for debugging.
    var outerChannel = MultiChannel(IsolateChannel.connectReceive(receivePort));
    var outerQueue = StreamQueue(outerChannel.stream);
    var channelId = (await outerQueue.next) as int;
    var channel = outerChannel.virtualChannel(channelId).transformStream(
        StreamTransformer.fromHandlers(handleDone: (sink) async {
      if (_shouldPauseAfterTests) {
        outerChannel.sink.add('debug');
        await outerQueue.next;
      }
      receivePort.close();
      isolate!.kill();
      eventSub?.cancel();
      client?.dispose();
      sink.close();
    }));

    Environment? environment;
    IsolateRef? isolateRef;
    if (_config.debug) {
      var info =
          await Service.controlWebServer(enable: true, silenceOutput: true);
      var isolateID = Service.getIsolateID(isolate)!;

      var libraryPath = p.toUri(p.absolute(path)).toString();
      var serverUri = info.serverUri!;
      client = await vmServiceConnectUri(_wsUriFor(serverUri).toString());
      var isolateNumber = int.parse(isolateID.split('/').last);
      isolateRef = (await client.getVM())
          .isolates!
          .firstWhere((isolate) => isolate.number == isolateNumber.toString());
      await client.setName(isolateRef.id!, path);
      var libraryRef = (await client.getIsolate(isolateRef.id!))
          .libraries!
          .firstWhere((library) => library.uri == libraryPath);
      var url = _observatoryUrlFor(serverUri, isolateRef.id!, libraryRef.id!);
      environment = VMEnvironment(url, isolateRef, client);
    }

    environment ??= PluginEnvironment();

    var controller = deserializeSuite(
        path, platform, suiteConfig, environment, channel.cast(), message,
        gatherCoverage: () => _gatherCoverage(environment!));

    if (isolateRef != null) {
      await client!.streamListen('Debug');
      eventSub = client.onDebugEvent.listen((event) {
        if (event.kind == EventKind.kResume) {
          controller.setDebugging(false);
        } else if (event.kind == EventKind.kPauseInterrupted ||
            event.kind == EventKind.kPauseBreakpoint ||
            event.kind == EventKind.kPauseException) {
          controller.setDebugging(true);
        }
      });
    }

    return await controller.suite;
  }

  @override
  Future close() => _closeMemo.runOnce(_compiler.dispose);

  /// Spawns an isolate and passes it [message].
  ///
  /// This isolate connects an [IsolateChannel] to [message] and sends the
  /// serialized tests over that channel.
  Future<Isolate?> _spawnIsolate(
      String path, SendPort message, Metadata suiteMetadata) async {
    try {
      var precompiledPath = _config.suiteDefaults.precompiledPath;
      if (precompiledPath != null) {
        return _spawnPrecompiledIsolate(path, message, precompiledPath);
      } else if (_config.pubServeUrl != null) {
        return _spawnPubServeIsolate(path, message, _config.pubServeUrl!);
      } else if (_config.useDataIsolateStrategy) {
        return _spawnDataIsolate(path, message, suiteMetadata);
      } else {
        return _spawnKernelIsolate(path, message, suiteMetadata);
      }
    } catch (_) {
      if (_closeMemo.hasRun) return null;
      rethrow;
    }
  }

  /// Compiles [path] to kernel using [_compiler] and spawns that in an
  /// isolate.
  Future<Isolate> _spawnKernelIsolate(
      String path, SendPort message, Metadata suiteMetadata) async {
    final response =
        await _compiler.compile(File(path).absolute.uri, suiteMetadata);
    var compiledDill = response.kernelOutputUri?.toFilePath();
    if (compiledDill == null || response.errorCount > 0) {
      throw LoadException(path, response.compilerOutput ?? 'unknown error');
    }
    return await Isolate.spawnUri(p.toUri(compiledDill), [], message,
        packageConfig: await packageConfigUri, checked: true);
  }
}

Future<Isolate> _spawnDataIsolate(
    String path, SendPort message, Metadata suiteMetadata) async {
  return await dart.runInIsolate('''
    ${suiteMetadata.languageVersionComment ?? await rootPackageLanguageVersionComment}
    import "dart:isolate";
    import "package:test_core/src/bootstrap/vm.dart";
    import "${p.toUri(p.absolute(path))}" as test;
    void main(_, SendPort sendPort) {
      internalBootstrapVmTest(() => test.main, sendPort);
    }
  ''', message);
}

Future<Isolate> _spawnPrecompiledIsolate(
    String testPath, SendPort message, String precompiledPath) async {
  testPath = p.absolute('${p.join(precompiledPath, testPath)}.vm_test.dart');
  var dillTestpath =
      '${testPath.substring(0, testPath.length - '.dart'.length)}.vm.app.dill';
  if (await File(dillTestpath).exists()) {
    testPath = dillTestpath;
  }
  File? packageConfig =
      File(p.join(precompiledPath, '.dart_tool/package_config.json'));
  if (!(await packageConfig.exists())) {
    packageConfig = File(p.join(precompiledPath, '.packages'));
    if (!(await packageConfig.exists())) {
      packageConfig = null;
    }
  }
  return await Isolate.spawnUri(p.toUri(testPath), [], message,
      packageConfig: packageConfig?.uri, checked: true);
}

Future<Map<String, dynamic>> _gatherCoverage(Environment environment) async {
  final isolateId = Uri.parse(environment.observatoryUrl!.fragment)
      .queryParameters['isolateId'];
  return await collect(environment.observatoryUrl!, false, false, false, {},
      isolateIds: {isolateId!});
}

Future<Isolate> _spawnPubServeIsolate(
    String testPath, SendPort message, Uri pubServeUrl) async {
  var url = pubServeUrl.resolveUri(
      p.toUri('${p.relative(testPath, from: 'test')}.vm_test.dart'));

  try {
    return await Isolate.spawnUri(url, [], message, checked: true);
  } on IsolateSpawnException catch (error) {
    if (error.message.contains('OS Error: Connection refused') ||
        error.message.contains('The remote computer refused')) {
      throw LoadException(
          testPath,
          'Error getting $url: Connection refused\n'
          'Make sure "pub serve" is running.');
    } else if (error.message.contains('404 Not Found')) {
      throw LoadException(
          testPath,
          'Error getting $url: 404 Not Found\n'
          'Make sure "pub serve" is serving the test/ directory.');
    }

    throw LoadException(testPath, error);
  }
}

Uri _wsUriFor(Uri observatoryUrl) =>
    observatoryUrl.replace(scheme: 'ws').resolve('ws');

Uri _observatoryUrlFor(Uri base, String isolateId, String id) => base.replace(
    fragment: Uri(
        path: '/inspect',
        queryParameters: {'isolateId': isolateId, 'objectId': id}).toString());

var _hasRegistered = false;
void _setupPauseAfterTests() {
  if (_hasRegistered) return;
  _hasRegistered = true;
  registerExtension('ext.test.pauseAfterTests', (_, __) async {
    _shouldPauseAfterTests = true;
    return ServiceExtensionResponse.result(jsonEncode({}));
  });
}
