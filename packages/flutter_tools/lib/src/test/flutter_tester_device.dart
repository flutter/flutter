// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io' as io; // ignore: dart_io_import;

import 'package:dds/dds.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../convert.dart';
import '../device.dart';
import '../project.dart';
import '../vmservice.dart';

import 'font_config_manager.dart';
import 'test_device.dart';

/// Implementation of [TestDevice] with the Flutter Tester over a [Process].
class FlutterTesterTestDevice extends TestDevice {
  FlutterTesterTestDevice({
    @required this.id,
    @required this.platform,
    @required this.fileSystem,
    @required this.processManager,
    @required this.logger,
    @required this.shellPath,
    @required this.debuggingOptions,
    @required this.enableObservatory,
    @required this.machine,
    @required this.host,
    @required this.buildTestAssets,
    @required this.flutterProject,
    @required this.icudtlPath,
    @required this.compileExpression,
    @required this.fontConfigManager,
  })  : assert(shellPath != null), // Please provide the path to the shell in the SKY_SHELL environment variable.
        assert(!debuggingOptions.startPaused || enableObservatory),
        _gotProcessObservatoryUri = enableObservatory
            ? Completer<Uri>() : (Completer<Uri>()..complete(null));

  /// Used for logging to identify the test that is currently being executed.
  final int id;
  final Platform platform;
  final FileSystem fileSystem;
  final ProcessManager processManager;
  final Logger logger;
  final String shellPath;
  final DebuggingOptions debuggingOptions;
  final bool enableObservatory;
  final bool machine;
  final InternetAddress host;
  final bool buildTestAssets;
  final FlutterProject flutterProject;
  final String icudtlPath;
  final CompileExpression compileExpression;
  final FontConfigManager fontConfigManager;

  final Completer<Uri> _gotProcessObservatoryUri;
  final Completer<int> _exitCode = Completer<int>();

  Process _process;
  HttpServer _server;

  @override
  Future<StreamChannel<String>> start({@required String compiledEntrypointPath}) async {
    assert(!_exitCode.isCompleted);
    assert(_process == null);
    assert(_server == null);

    // Prepare our WebSocket server to talk to the engine subprocess.
    // Let the server choose an unused port.
    _server = await bind(host, /*port*/ 0);
    logger.printTrace('test $id: test harness socket server is running at port:${_server.port}');

    final List<String> command = <String>[
      shellPath,
      if (enableObservatory) ...<String>[
        // Some systems drive the _FlutterPlatform class in an unusual way, where
        // only one test file is processed at a time, and the operating
        // environment hands out specific ports ahead of time in a cooperative
        // manner, where we're only allowed to open ports that were given to us in
        // advance like this. For those esoteric systems, we have this feature
        // whereby you can create _FlutterPlatform with a pair of ports.
        //
        // I mention this only so that you won't be tempted, as I was, to apply
        // the obvious simplification to this code and remove this entire feature.
        '--observatory-port=${debuggingOptions.disableDds ? debuggingOptions.hostVmServicePort: 0}',
        if (debuggingOptions.startPaused) '--start-paused',
        if (debuggingOptions.disableServiceAuthCodes) '--disable-service-auth-codes',
      ]
      else
        '--disable-observatory',
      if (host.type == InternetAddressType.IPv6) '--ipv6',
      if (icudtlPath != null) '--icu-data-file-path=$icudtlPath',
      '--enable-checked-mode',
      '--verify-entry-points',
      '--enable-software-rendering',
      '--skia-deterministic-rendering',
      '--enable-dart-profiling',
      '--non-interactive',
      '--use-test-fonts',
      '--packages=${debuggingOptions.buildInfo.packagesPath}',
      if (debuggingOptions.nullAssertions)
        '--dart-flags=--null_assertions',
      ...debuggingOptions.dartEntrypointArgs,
      compiledEntrypointPath,
    ];

    // If the FLUTTER_TEST environment variable has been set, then pass it on
    // for package:flutter_test to handle the value.
    //
    // If FLUTTER_TEST has not been set, assume from this context that this
    // call was invoked by the command 'flutter test'.
    final String flutterTest = platform.environment.containsKey('FLUTTER_TEST')
        ? platform.environment['FLUTTER_TEST']
        : 'true';
    final Map<String, String> environment = <String, String>{
      'FLUTTER_TEST': flutterTest,
      'FONTCONFIG_FILE': fontConfigManager.fontConfigFile.path,
      'SERVER_PORT': _server.port.toString(),
      'APP_NAME': flutterProject?.manifest?.appName ?? '',
      if (buildTestAssets)
        'UNIT_TEST_ASSETS': fileSystem.path.join(flutterProject?.directory?.path ?? '', 'build', 'unit_test_assets'),
    };

    logger.printTrace('test $id: Starting flutter_tester process with command=$command, environment=$environment');
    _process = await processManager.start(command, environment: environment);

    // Unawaited to update state.
    unawaited(_process.exitCode.then((int exitCode) {
      logger.printTrace('test $id: flutter_tester process at pid ${_process.pid} exited with code=$exitCode');
      _exitCode.complete(exitCode);
    }));

    logger.printTrace('test $id: Started flutter_tester process at pid ${_process.pid}');

    // Pipe stdout and stderr from the subprocess to our printStatus console.
    // We also keep track of what observatory port the engine used, if any.
    _pipeStandardStreamsToConsole(
      process: _process,
      reportObservatoryUri: (Uri detectedUri) async {
        assert(!_gotProcessObservatoryUri.isCompleted);
        assert(debuggingOptions.hostVmServicePort == null ||
            debuggingOptions.hostVmServicePort == detectedUri.port);

        Uri forwardingUri;
        if (!debuggingOptions.disableDds) {
          logger.printTrace('test $id: Starting Dart Development Service');
          final DartDevelopmentService dds = await startDds(detectedUri);
          forwardingUri = dds.uri;
          logger.printTrace('test $id: Dart Development Service started at ${dds.uri}, forwarding to VM service at ${dds.remoteVmServiceUri}.');
        } else {
          forwardingUri = detectedUri;
        }

        logger.printTrace('Connecting to service protocol: $forwardingUri');
        final Future<vm_service.VmService> localVmService = connectToVmService(
          forwardingUri,
          compileExpression: compileExpression,
        );
        unawaited(localVmService.then((vm_service.VmService vmservice) {
          logger.printTrace('test $id: Successfully connected to service protocol: $forwardingUri');
        }));

        if (debuggingOptions.startPaused && !machine) {
          logger.printStatus('The test process has been started.');
          logger.printStatus('You can now connect to it using observatory. To connect, load the following Web site in your browser:');
          logger.printStatus('  $forwardingUri');
          logger.printStatus('You should first set appropriate breakpoints, then resume the test in the debugger.');
        }
        _gotProcessObservatoryUri.complete(forwardingUri);
      },
    );

    return remoteChannel;
  }

  @override
  Future<Uri> get observatoryUri {
    assert(_gotProcessObservatoryUri != null);
    return _gotProcessObservatoryUri.future;
  }

  @override
  Future<void> kill() async {
    logger.printTrace('test $id: Terminating flutter_tester process');
    _process?.kill(io.ProcessSignal.sigkill);

    logger.printTrace('test $id: Shutting down test harness socket server');
    await _server?.close(force: true);
    await finished;
  }

  @override
  Future<void> get finished async {
    final int exitCode = await _exitCode.future;

    // On Windows, the [exitCode] and the terminating signal have no correlation.
    if (platform.isWindows) {
      return;
    }

    // ProcessSignal.SIGKILL. Negative because signals are returned as negative
    // exit codes.
    if (exitCode == -9) {
      // We expect SIGKILL (9) because we could have tried to [kill] it.
      return;
    }
    throw TestDeviceException(_getExitCodeMessage(exitCode), StackTrace.current);
  }

  Uri get _ddsServiceUri {
    return Uri(
      scheme: 'http',
      host: (host.type == InternetAddressType.IPv6 ?
        InternetAddress.loopbackIPv6 :
        InternetAddress.loopbackIPv4
      ).host,
      port: debuggingOptions.hostVmServicePort ?? 0,
    );
  }

  @visibleForTesting
  @protected
  Future<DartDevelopmentService> startDds(Uri uri) {
    return DartDevelopmentService.startDartDevelopmentService(
      uri,
      serviceUri: _ddsServiceUri,
      enableAuthCodes: !debuggingOptions.disableServiceAuthCodes,
      ipv6: host.type == InternetAddressType.IPv6,
    );
  }

  /// Binds an [HttpServer] serving from `host` on `port`.
  ///
  /// Only intended to be overridden in tests.
  @protected
  @visibleForTesting
  Future<HttpServer> bind(InternetAddress host, int port) => HttpServer.bind(host, port);

  @protected
  @visibleForTesting
  Future<StreamChannel<String>> get remoteChannel async {
    assert(_server != null);

    try {
      final HttpRequest firstRequest = await _server.first;
      final WebSocket webSocket = await WebSocketTransformer.upgrade(firstRequest);
      return _webSocketToStreamChannel(webSocket);
    } on Exception catch (error, stackTrace) {
      throw TestDeviceException('Unable to connect to flutter_tester process: $error', stackTrace);
    }
  }

  @override
  String toString() {
    final String status = _process != null
        ? 'pid: ${_process.pid}, ${_exitCode.isCompleted ? 'exited' : 'running'}'
        : 'not started';
    return 'Flutter Tester ($status) for test $id';
  }

  void _pipeStandardStreamsToConsole({
    @required Process process,
    @required Future<void> reportObservatoryUri(Uri uri),
  }) {
    const String observatoryString = 'Observatory listening on ';
    for (final Stream<List<int>> stream in <Stream<List<int>>>[
      process.stderr,
      process.stdout,
    ]) {
      stream
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen(
            (String line) async {
          logger.printTrace('test $id: Shell: $line');

          if (line.startsWith(observatoryString)) {
            try {
              final Uri uri = Uri.parse(line.substring(observatoryString.length));
              if (reportObservatoryUri != null) {
                await reportObservatoryUri(uri);
              }
            } on Exception catch (error) {
              logger.printError('Could not parse shell observatory port message: $error');
            }
          } else if (line != null) {
            logger.printStatus('Shell: $line');
          }
        },
        onError: (dynamic error) {
          logger.printError('shell console stream for process pid ${process.pid} experienced an unexpected error: $error');
        },
        cancelOnError: true,
      );
    }
  }
}

String _getExitCodeMessage(int exitCode) {
  switch (exitCode) {
    case 1:
      return 'Shell subprocess cleanly reported an error. Check the logs above for an error message.';
    case 0:
      return 'Shell subprocess ended cleanly. Did main() call exit()?';
    case -0x0f: // ProcessSignal.SIGTERM
      return 'Shell subprocess crashed with SIGTERM ($exitCode).';
    case -0x0b: // ProcessSignal.SIGSEGV
      return 'Shell subprocess crashed with segmentation fault.';
    case -0x06: // ProcessSignal.SIGABRT
      return 'Shell subprocess crashed with SIGABRT ($exitCode).';
    case -0x02: // ProcessSignal.SIGINT
      return 'Shell subprocess terminated by ^C (SIGINT, $exitCode).';
    default:
      return 'Shell subprocess crashed with unexpected exit code $exitCode.';
  }
}

StreamChannel<String> _webSocketToStreamChannel(WebSocket webSocket) {
  final StreamChannelController<String> controller = StreamChannelController<String>();

  controller.local.stream
      .map<dynamic>((String message) => message as dynamic)
      .pipe(webSocket);
  webSocket
      // We're only communicating with string encoded JSON.
      .map<String>((dynamic message) => message as String)
      .pipe(controller.local.sink);

  return controller.foreign;
}
