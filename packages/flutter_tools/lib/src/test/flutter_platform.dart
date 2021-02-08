// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io' as io; // ignore: dart_io_import;

import 'package:dds/dds.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test_core/src/platform.dart'; // ignore: implementation_imports
import 'package:vm_service/vm_service.dart' as vm_service;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../compile.dart';
import '../convert.dart';
import '../dart/language_version.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../test/test_wrapper.dart';
import '../vmservice.dart';
import 'test_compiler.dart';
import 'test_config.dart';
import 'watcher.dart';

/// The address at which our WebSocket server resides and at which the sky_shell
/// processes will host the Observatory server.
final Map<InternetAddressType, InternetAddress> _kHosts = <InternetAddressType, InternetAddress>{
  InternetAddressType.IPv4: InternetAddress.loopbackIPv4,
  InternetAddressType.IPv6: InternetAddress.loopbackIPv6,
};

typedef PlatformPluginRegistration = void Function(FlutterPlatform platform);

/// Configure the `test` package to work with Flutter.
///
/// On systems where each [FlutterPlatform] is only used to run one test suite
/// (that is, one Dart file with a `*_test.dart` file name and a single `void
/// main()`), you can set an observatory port explicitly.
FlutterPlatform installHook({
  TestWrapper testWrapper = const TestWrapper(),
  @required String shellPath,
  @required DebuggingOptions debuggingOptions,
  TestWatcher watcher,
  bool enableObservatory = false,
  bool machine = false,
  int port = 0,
  String precompiledDillPath,
  Map<String, String> precompiledDillFiles,
  bool updateGoldens = false,
  bool buildTestAssets = false,
  InternetAddressType serverType = InternetAddressType.IPv4,
  Uri projectRootDirectory,
  FlutterProject flutterProject,
  String icudtlPath,
  PlatformPluginRegistration platformPluginRegistration,
}) {
  assert(testWrapper != null);
  assert(enableObservatory || (!debuggingOptions.startPaused && debuggingOptions.hostVmServicePort == null));

  // registerPlatformPlugin can be injected for testing since it's not very mock-friendly.
  platformPluginRegistration ??= (FlutterPlatform platform) {
    testWrapper.registerPlatformPlugin(
      <Runtime>[Runtime.vm],
      () {
        return platform;
      },
    );
  };
  final FlutterPlatform platform = FlutterPlatform(
    shellPath: shellPath,
    debuggingOptions: debuggingOptions,
    watcher: watcher,
    machine: machine,
    enableObservatory: enableObservatory,
    host: _kHosts[serverType],
    port: port,
    precompiledDillPath: precompiledDillPath,
    precompiledDillFiles: precompiledDillFiles,
    updateGoldens: updateGoldens,
    buildTestAssets: buildTestAssets,
    projectRootDirectory: projectRootDirectory,
    flutterProject: flutterProject,
    icudtlPath: icudtlPath,
  );
  platformPluginRegistration(platform);
  return platform;
}

/// Generates the bootstrap entry point script that will be used to launch an
/// individual test file.
///
/// The [testUrl] argument specifies the path to the test file that is being
/// launched.
///
/// The [host] argument specifies the address at which the test harness is
/// running.
///
/// If [testConfigFile] is specified, it must follow the conventions of test
/// configuration files as outlined in the [flutter_test] library. By default,
/// the test file will be launched directly.
///
/// The [updateGoldens] argument will set the [autoUpdateGoldens] global
/// variable in the [flutter_test] package before invoking the test.
// NOTE: this API is used by the fuchsia source tree, do not add new
// required or position parameters.
String generateTestBootstrap({
  @required Uri testUrl,
  @required InternetAddress host,
  File testConfigFile,
  bool updateGoldens = false,
  String languageVersionHeader = '',
  bool nullSafety = false,
  bool flutterTestDep = true,
}) {
  assert(testUrl != null);
  assert(host != null);
  assert(updateGoldens != null);

  final String websocketUrl = host.type == InternetAddressType.IPv4
      ? 'ws://${host.address}'
      : 'ws://[${host.address}]';
  final String encodedWebsocketUrl = Uri.encodeComponent(websocketUrl);

  final StringBuffer buffer = StringBuffer();
  buffer.write('''
$languageVersionHeader
import 'dart:async';
import 'dart:convert';  // ignore: dart_convert_import
import 'dart:io';  // ignore: dart_io_import
import 'dart:isolate';
''');
  if (flutterTestDep) {
    buffer.write('''
import 'package:flutter_test/flutter_test.dart';
''');
  }
  buffer.write('''
import 'package:test_api/src/remote_listener.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:stack_trace/stack_trace.dart';

import '$testUrl' as test;
''');
  if (testConfigFile != null) {
    buffer.write('''
import '${Uri.file(testConfigFile.path)}' as test_config;
''');
  }
  buffer.write('''

/// Returns a serialized test suite.
StreamChannel<dynamic> serializeSuite(Function getMain()) {
  return RemoteListener.start(getMain);
}

/// Capture any top-level errors (mostly lazy syntax errors, since other are
/// caught below) and report them to the parent isolate.
void catchIsolateErrors() {
  final ReceivePort errorPort = ReceivePort();
  // Treat errors non-fatal because otherwise they'll be double-printed.
  Isolate.current.setErrorsFatal(false);
  Isolate.current.addErrorListener(errorPort.sendPort);
  errorPort.listen((dynamic message) {
    // Masquerade as an IsolateSpawnException because that's what this would
    // be if the error had been detected statically.
    final IsolateSpawnException error = IsolateSpawnException(
        message[0] as String);
    final Trace stackTrace = message[1] == null ?
        Trace(const <Frame>[]) : Trace.parse(message[1] as String);
    Zone.current.handleUncaughtError(error, stackTrace);
  });
}


void main() {
  String serverPort = Platform.environment['SERVER_PORT'] ?? '';
  String server = Uri.decodeComponent('$encodedWebsocketUrl:\$serverPort');
  StreamChannel<dynamic> channel = serializeSuite(() {
    catchIsolateErrors();
''');
  if (flutterTestDep) {
    buffer.write('''
goldenFileComparator = LocalFileComparator(Uri.parse('$testUrl'));
autoUpdateGoldenFiles = $updateGoldens;
''');
  }
  if (testConfigFile != null) {
    buffer.write('''
    return () => test_config.testExecutable(test.main);
''');
  } else {
    buffer.write('''
    return test.main;
''');
  }
  buffer.write('''
  });
  WebSocket.connect(server).then((WebSocket socket) {
    socket.map((dynamic x) {
      return json.decode(x as String);
    }).pipe(channel.sink);
    socket.addStream(channel.stream.map(json.encode));
  });
}
''');
  return buffer.toString();
}

enum _TestHarnessStatus { testerCrashed, finished }

typedef Finalizer = Future<void> Function();

/// The flutter test platform used to integrate with package:test.
class FlutterPlatform extends PlatformPlugin {
  FlutterPlatform({
    @required this.shellPath,
    @required this.debuggingOptions,
    this.watcher,
    this.enableObservatory,
    this.machine,
    this.host,
    this.port,
    this.precompiledDillPath,
    this.precompiledDillFiles,
    this.updateGoldens,
    this.buildTestAssets,
    this.projectRootDirectory,
    this.flutterProject,
    this.icudtlPath,
  }) : assert(shellPath != null);

  final String shellPath;
  final DebuggingOptions debuggingOptions;
  final TestWatcher watcher;
  final bool enableObservatory;
  final bool machine;
  final InternetAddress host;
  final int port;
  final String precompiledDillPath;
  final Map<String, String> precompiledDillFiles;
  final bool updateGoldens;
  final bool buildTestAssets;
  final Uri projectRootDirectory;
  final FlutterProject flutterProject;
  final String icudtlPath;

  Directory fontsDirectory;

  /// The test compiler produces dill files for each test main.
  ///
  /// To speed up compilation, each compile is initialized from an existing
  /// dill file from previous runs, if possible.
  TestCompiler compiler;

  // Each time loadChannel() is called, we spin up a local WebSocket server,
  // then spin up the engine in a subprocess. We pass the engine a Dart file
  // that connects to our WebSocket server, then we proxy JSON messages from
  // the test harness to the engine and back again. If at any time the engine
  // crashes, we inject an error into that stream. When the process closes,
  // we clean everything up.

  int _testCount = 0;

  @override
  Future<RunnerSuite> load(
    String path,
    SuitePlatform platform,
    SuiteConfiguration suiteConfig,
    Object message,
  ) async {
    // loadChannel may throw an exception. That's fine; it will cause the
    // LoadSuite to emit an error, which will be presented to the user.
    // Except for the Declarer error, which is a specific test incompatibility
    // error we need to catch.
    final StreamChannel<dynamic> channel = loadChannel(path, platform);
    final RunnerSuiteController controller = deserializeSuite(path, platform,
      suiteConfig, const PluginEnvironment(), channel, message);
    return controller.suite;
  }

  @override
  StreamChannel<dynamic> loadChannel(String path, SuitePlatform platform) {
    if (_testCount > 0) {
      // Fail if there will be a port conflict.
      if (debuggingOptions.hostVmServicePort != null) {
        throwToolExit('installHook() was called with an observatory port or debugger mode enabled, but then more than one test suite was run.');
      }
      // Fail if we're passing in a precompiled entry-point.
      if (precompiledDillPath != null) {
        throwToolExit('installHook() was called with a precompiled test entry-point, but then more than one test suite was run.');
      }
    }
    final int ourTestCount = _testCount;
    _testCount += 1;
    final StreamController<dynamic> localController = StreamController<dynamic>();
    final StreamController<dynamic> remoteController = StreamController<dynamic>();
    final Completer<_AsyncError> testCompleteCompleter = Completer<_AsyncError>();
    final _FlutterPlatformStreamSinkWrapper<dynamic> remoteSink = _FlutterPlatformStreamSinkWrapper<dynamic>(
      remoteController.sink,
      testCompleteCompleter.future,
    );
    final StreamChannel<dynamic> localChannel = StreamChannel<dynamic>.withGuarantees(
      remoteController.stream,
      localController.sink,
    );
    final StreamChannel<dynamic> remoteChannel = StreamChannel<dynamic>.withGuarantees(
      localController.stream,
      remoteSink,
    );
    testCompleteCompleter.complete(_startTest(path, localChannel, ourTestCount));
    return remoteChannel;
  }

  Future<String> _compileExpressionService(
    String isolateId,
    String expression,
    List<String> definitions,
    List<String> typeDefinitions,
    String libraryUri,
    String klass,
    bool isStatic,
  ) async {
    if (compiler == null || compiler.compiler == null) {
      throw 'Compiler is not set up properly to compile $expression';
    }
    final CompilerOutput compilerOutput =
      await compiler.compiler.compileExpression(expression, definitions,
        typeDefinitions, libraryUri, klass, isStatic);
    if (compilerOutput != null && compilerOutput.outputFilename != null) {
      return base64.encode(globals.fs.file(compilerOutput.outputFilename).readAsBytesSync());
    }
    throw 'Failed to compile $expression';
  }

  /// Binds an [HttpServer] serving from `host` on `port`.
  ///
  /// Only intended to be overridden in tests for [FlutterPlatform].
  @protected
  @visibleForTesting
  Future<HttpServer> bind(InternetAddress host, int port) => HttpServer.bind(host, port);

  Future<_AsyncError> _startTest(
    String testPath,
    StreamChannel<dynamic> controller,
    int ourTestCount,
  ) async {
    globals.printTrace('test $ourTestCount: starting test $testPath');

    _AsyncError outOfBandError; // error that we couldn't send to the harness that we need to send via our future

    final List<Finalizer> finalizers = <Finalizer>[]; // Will be run in reverse order.
    bool subprocessActive = false;
    bool controllerSinkClosed = false;
    try {
      // Callback can't throw since it's just setting a variable.
      unawaited(controller.sink.done.whenComplete(() {
        controllerSinkClosed = true;
      }));

      // Prepare our WebSocket server to talk to the engine subprocess.
      final HttpServer server = await bind(host, port);
      finalizers.add(() async {
        globals.printTrace('test $ourTestCount: shutting down test harness socket server');
        await server.close(force: true);
      });
      final Completer<WebSocket> webSocket = Completer<WebSocket>();
      server.listen(
        (HttpRequest request) {
          if (!webSocket.isCompleted) {
            webSocket.complete(WebSocketTransformer.upgrade(request));
          }
        },
        onError: (dynamic error, StackTrace stack) {
          // If you reach here, it's unlikely we're going to be able to really handle this well.
          globals.printTrace('test $ourTestCount: test harness socket server experienced an unexpected error: $error');
          if (!controllerSinkClosed) {
            controller.sink.addError(error, stack);
            controller.sink.close();
          } else {
            globals.printError('unexpected error from test harness socket server: $error');
          }
        },
        cancelOnError: true,
      );

      globals.printTrace('test $ourTestCount: starting shell process');

      // If a kernel file is given, then use that to launch the test.
      // If mapping is provided, look kernel file from mapping.
      // If all fails, create a "listener" dart that invokes actual test.
      String mainDart;
      if (precompiledDillPath != null) {
        mainDart = precompiledDillPath;
      } else if (precompiledDillFiles != null) {
        mainDart = precompiledDillFiles[testPath];
      }
      mainDart ??= _createListenerDart(finalizers, ourTestCount, testPath, server);

      if (precompiledDillPath == null && precompiledDillFiles == null) {
        // Lazily instantiate compiler so it is built only if it is actually used.
        compiler ??= TestCompiler(debuggingOptions.buildInfo, flutterProject);
        mainDart = await compiler.compile(globals.fs.file(mainDart).uri);

        if (mainDart == null) {
          controller.sink.addError(_getErrorMessage('Compilation failed', testPath, shellPath));
          return null;
        }
      }

      final Process process = await _startProcess(
        shellPath,
        mainDart,
        enableObservatory: enableObservatory,
        serverPort: server.port,
      );
      subprocessActive = true;
      finalizers.add(() async {
        if (subprocessActive) {
          globals.printTrace('test $ourTestCount: ensuring end-of-process for shell');
          process.kill(io.ProcessSignal.sigkill);
          final int exitCode = await process.exitCode;
          subprocessActive = false;
          if (!controllerSinkClosed && exitCode != -9) {
            // ProcessSignal.SIGKILL
            // We expect SIGKILL (9) because we tried to terminate it.
            // It's negative because signals are returned as negative exit codes.
            final String message = _getErrorMessage(
                _getExitCodeMessage(exitCode),
                testPath,
                shellPath);
            controller.sink.addError(message);
          }
        }
      });

      final Completer<Uri> gotProcessObservatoryUri = Completer<Uri>();
      if (!enableObservatory) {
        gotProcessObservatoryUri.complete();
      }

      // Pipe stdout and stderr from the subprocess to our printStatus console.
      // We also keep track of what observatory port the engine used, if any.
      final Uri ddsServiceUri = getDdsServiceUri();
      _pipeStandardStreamsToConsole(
        process,
        reportObservatoryUri: (Uri detectedUri) async {
          assert(!gotProcessObservatoryUri.isCompleted);
          assert(debuggingOptions.hostVmServicePort == null ||
              debuggingOptions.hostVmServicePort == detectedUri.port);

          Uri forwardingUri;
          if (!debuggingOptions.disableDds) {
            final DartDevelopmentService dds = await DartDevelopmentService.startDartDevelopmentService(
              detectedUri,
              serviceUri: ddsServiceUri,
              enableAuthCodes: !debuggingOptions.disableServiceAuthCodes,
              ipv6: host.type == InternetAddressType.IPv6,
            );
            forwardingUri = dds.uri;
            globals.printTrace('Dart Development Service started at ${dds.uri}, forwarding to VM service at ${dds.remoteVmServiceUri}.');
          } else {
            forwardingUri = detectedUri;
          }
          {
            globals.printTrace('Connecting to service protocol: $forwardingUri');
            final Future<vm_service.VmService> localVmService = connectToVmService(forwardingUri,
              compileExpression: _compileExpressionService);
            unawaited(localVmService.then((vm_service.VmService vmservice) {
              globals.printTrace('Successfully connected to service protocol: $forwardingUri');
            }));
          }
          if (debuggingOptions.startPaused && !machine) {
            globals.printStatus('The test process has been started.');
            globals.printStatus('You can now connect to it using observatory. To connect, load the following Web site in your browser:');
            globals.printStatus('  $forwardingUri');
            globals.printStatus('You should first set appropriate breakpoints, then resume the test in the debugger.');
          }
          gotProcessObservatoryUri.complete(forwardingUri);
        },
      );

      // At this point, three things can happen next:
      // The engine could crash, in which case process.exitCode will complete.
      // The engine could connect to us, in which case webSocket.future will complete.
      // The local test harness could get bored of us.
      globals.printTrace('test $ourTestCount: awaiting connection to result for test process at pid ${process.pid}');
      final _TestHarnessStatus testHarnessStatus = await Future.any<_TestHarnessStatus>(<Future<_TestHarnessStatus>>[
        process.exitCode.then<_TestHarnessStatus>((int exitCode) => _TestHarnessStatus.testerCrashed),
        gotProcessObservatoryUri.future.then<_TestHarnessStatus>((Uri processObservatoryUri) {
          if (processObservatoryUri != null) {
            globals.printTrace('test $ourTestCount: Observatory uri is available at $processObservatoryUri');
          }
          watcher?.handleStartedProcess(ProcessEvent(ourTestCount, process, processObservatoryUri));

          return webSocket.future.then<_TestHarnessStatus>((WebSocket remoteSocket) async {
            globals.printTrace('test $ourTestCount: connected to test harness, now awaiting test result');
            await _controlTests(
              controller: controller,
              remoteSocket: remoteSocket,
              onError: (dynamic error, StackTrace stackTrace) {
                // If you reach here, it's unlikely we're going to be able to really handle this well.
                globals.printError('test: $testPath\nerror: $error');
                if (!controllerSinkClosed) {
                  controller.sink.addError(error, stackTrace);
                  controller.sink.close();
                } else {
                  globals.printError('unexpected error: $error');
                }
              }
            );

            await watcher?.handleFinishedTest(ProcessEvent(ourTestCount, process, processObservatoryUri));
            return _TestHarnessStatus.finished;
          });
        })
      ]);

      if (testHarnessStatus == _TestHarnessStatus.testerCrashed) {
        globals.printTrace('test $ourTestCount: process with pid ${process.pid} crashed');
        final int exitCode = await process.exitCode;
        subprocessActive = false;
        final String message = _getErrorMessage(
            _getExitCodeMessage(exitCode),
            testPath,
            shellPath);
        controller.sink.addError(message);
        // Awaited for with 'sink.done' below in `finally`.
        unawaited(controller.sink.close());
        globals.printTrace('test $ourTestCount: waiting for controller sink to close');
        await controller.sink.done;
        await watcher?.handleTestCrashed(ProcessEvent(ourTestCount, process));
      }
    } on Exception catch (error, stack) {
      globals.printTrace('test $ourTestCount: error caught during test; ${controllerSinkClosed ? "reporting to console" : "sending to test framework"}');
      if (!controllerSinkClosed) {
        controller.sink.addError(error, stack);
      } else {
        globals.printError('unhandled error during test:\n$testPath\n$error\n$stack');
        outOfBandError ??= _AsyncError(error, stack);
      }
    } finally {
      globals.printTrace('test $ourTestCount: cleaning up...');
      // Finalizers are treated like a stack; run them in reverse order.
      for (final Finalizer finalizer in finalizers.reversed) {
        try {
          await finalizer();
        } on Exception catch (error, stack) {
          globals.printTrace('test $ourTestCount: error while cleaning up; ${controllerSinkClosed ? "reporting to console" : "sending to test framework"}');
          if (!controllerSinkClosed) {
            controller.sink.addError(error, stack);
          } else {
            globals.printError('unhandled error during finalization of test:\n$testPath\n$error\n$stack');
            outOfBandError ??= _AsyncError(error, stack);
          }
        }
      }
      if (!controllerSinkClosed) {
        // Waiting below with await.
        unawaited(controller.sink.close());
        globals.printTrace('test $ourTestCount: waiting for controller sink to close');
        await controller.sink.done;
      }
    }
    assert(!subprocessActive);
    assert(controllerSinkClosed);
    if (outOfBandError != null) {
      globals.printTrace('test $ourTestCount: finished with out-of-band failure');
    } else {
      globals.printTrace('test $ourTestCount: finished');
    }
    return outOfBandError;
  }

  String _createListenerDart(
    List<Finalizer> finalizers,
    int ourTestCount,
    String testPath,
    HttpServer server,
  ) {
    // Prepare a temporary directory to store the Dart file that will talk to us.
    final Directory tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_test_listener.');
    finalizers.add(() async {
      globals.printTrace('test $ourTestCount: deleting temporary directory');
      tempDir.deleteSync(recursive: true);
    });

    // Prepare the Dart file that will talk to us and start the test.
    final File listenerFile = globals.fs.file('${tempDir.path}/listener.dart');
    listenerFile.createSync();
    listenerFile.writeAsStringSync(_generateTestMain(
      testUrl: globals.fs.path.toUri(globals.fs.path.absolute(testPath)),
    ));
    return listenerFile.path;
  }

  String _generateTestMain({
    Uri testUrl,
  }) {
    assert(testUrl.scheme == 'file');
    final File file = globals.fs.file(testUrl);
    final PackageConfig packageConfig = debuggingOptions.buildInfo.packageConfig;

    final LanguageVersion languageVersion = determineLanguageVersion(
      file,
      packageConfig[flutterProject?.manifest?.appName],
    );
    return generateTestBootstrap(
      testUrl: testUrl,
      testConfigFile: findTestConfigFile(globals.fs.file(testUrl)),
      host: host,
      updateGoldens: updateGoldens,
      flutterTestDep: packageConfig['flutter_test'] != null,
      languageVersionHeader: '// @dart=${languageVersion.major}.${languageVersion.minor}'
    );
  }

  File _cachedFontConfig;

  @override
  Future<dynamic> close() async {
    if (compiler != null) {
      await compiler.dispose();
      compiler = null;
    }
    if (fontsDirectory != null) {
      globals.printTrace('Deleting ${fontsDirectory.path}...');
      fontsDirectory.deleteSync(recursive: true);
      fontsDirectory = null;
    }
  }

  /// Returns a Fontconfig config file that limits font fallback to the
  /// artifact cache directory.
  File get _fontConfigFile {
    if (_cachedFontConfig != null) {
      return _cachedFontConfig;
    }

    final StringBuffer sb = StringBuffer();
    sb.writeln('<fontconfig>');
    sb.writeln('  <dir>${globals.cache.getCacheArtifacts().path}</dir>');
    sb.writeln('  <cachedir>/var/cache/fontconfig</cachedir>');
    sb.writeln('</fontconfig>');

    if (fontsDirectory == null) {
      fontsDirectory = globals.fs.systemTempDirectory.createTempSync('flutter_test_fonts.');
      globals.printTrace('Using this directory for fonts configuration: ${fontsDirectory.path}');
    }

    _cachedFontConfig = globals.fs.file('${fontsDirectory.path}/fonts.conf');
    _cachedFontConfig.createSync();
    _cachedFontConfig.writeAsStringSync(sb.toString());
    return _cachedFontConfig;
  }

  Future<Process> _startProcess(
    String executable,
    String testPath, {
    bool enableObservatory = false,
    int serverPort,
  }) {
    assert(executable != null); // Please provide the path to the shell in the SKY_SHELL environment variable.
    assert(!debuggingOptions.startPaused || enableObservatory);

    final int observatoryPort = debuggingOptions.disableDds ? debuggingOptions.hostVmServicePort : 0;

    final List<String> command = <String>[
      executable,
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
        if (observatoryPort != null) '--observatory-port=$observatoryPort',
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
      testPath,
    ];

    globals.printTrace(command.join(' '));
    // If the FLUTTER_TEST environment variable has been set, then pass it on
    // for package:flutter_test to handle the value.
    //
    // If FLUTTER_TEST has not been set, assume from this context that this
    // call was invoked by the command 'flutter test'.
    final String flutterTest = globals.platform.environment.containsKey('FLUTTER_TEST')
        ? globals.platform.environment['FLUTTER_TEST']
        : 'true';
    final Map<String, String> environment = <String, String>{
      'FLUTTER_TEST': flutterTest,
      'FONTCONFIG_FILE': _fontConfigFile.path,
      'SERVER_PORT': serverPort.toString(),
      'APP_NAME': flutterProject?.manifest?.appName ?? '',
      if (buildTestAssets)
        'UNIT_TEST_ASSETS': globals.fs.path.join(flutterProject?.directory?.path ?? '', 'build', 'unit_test_assets'),
    };
    return globals.processManager.start(command, environment: environment);
  }

  void _pipeStandardStreamsToConsole(
    Process process, {
    Future<void> reportObservatoryUri(Uri uri),
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
          if (line.startsWith("error: Unable to read Dart source 'package:test/")) {
            globals.printTrace('Shell: $line');
            globals.printError('\n\nFailed to load test harness. Are you missing a dependency on flutter_test?\n');
          } else if (line.startsWith(observatoryString)) {
            globals.printTrace('Shell: $line');
            try {
              final Uri uri = Uri.parse(line.substring(observatoryString.length));
              if (reportObservatoryUri != null) {
                await reportObservatoryUri(uri);
              }
            } on Exception catch (error) {
              globals.printError('Could not parse shell observatory port message: $error');
            }
          } else if (line != null) {
            globals.printStatus('Shell: $line');
          }
        },
        onError: (dynamic error) {
          globals. printError('shell console stream for process pid ${process.pid} experienced an unexpected error: $error');
        },
        cancelOnError: true,
      );
    }
  }

  String _getErrorMessage(String what, String testPath, String shellPath) {
    return '$what\nTest: $testPath\nShell: $shellPath\n\n';
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

  @visibleForTesting
  @protected
  Uri getDdsServiceUri() {
    return Uri(
      scheme: 'http',
      host: (host.type == InternetAddressType.IPv6 ?
        InternetAddress.loopbackIPv6 :
        InternetAddress.loopbackIPv4
      ).host,
      port: debuggingOptions.hostVmServicePort ?? 0,
    );
  }
}

// The [_shellProcessClosed] future can't have errors thrown on it because it
// crosses zones (it's fed in a zone created by the test package, but listened
// to by a parent zone, the same zone that calls [close] below).
//
// This is because Dart won't let errors that were fed into a Future in one zone
// propagate to listeners in another zone. (Specifically, the zone in which the
// future was completed with the error, and the zone in which the listener was
// registered, are what matters.)
//
// Because of this, the [_shellProcessClosed] future takes an [_AsyncError]
// object as a result. If it's null, it's as if it had completed correctly; if
// it's non-null, it contains the error and stack trace of the actual error, as
// if it had completed with that error.
class _FlutterPlatformStreamSinkWrapper<S> implements StreamSink<S> {
  _FlutterPlatformStreamSinkWrapper(this._parent, this._shellProcessClosed);

  final StreamSink<S> _parent;
  final Future<_AsyncError> _shellProcessClosed;

  @override
  Future<void> get done => _done.future;
  final Completer<void> _done = Completer<void>();

  @override
  Future<dynamic> close() {
    Future.wait<dynamic>(<Future<dynamic>>[
      _parent.close(),
      _shellProcessClosed,
    ]).then<void>(
      (List<dynamic> futureResults) {
        assert(futureResults.length == 2);
        assert(futureResults.first == null);
        final dynamic lastResult = futureResults.last;
        if (lastResult is _AsyncError) {
          _done.completeError(lastResult.error, lastResult.stack);
        } else {
          assert(lastResult == null);
          _done.complete();
        }
      },
      onError: _done.completeError,
    );
    return done;
  }

  @override
  void add(S event) => _parent.add(event);
  @override
  void addError(dynamic errorEvent, [ StackTrace stackTrace ]) => _parent.addError(errorEvent, stackTrace);
  @override
  Future<dynamic> addStream(Stream<S> stream) => _parent.addStream(stream);
}

@immutable
class _AsyncError {
  const _AsyncError(this.error, this.stack);
  final dynamic error;
  final StackTrace stack;
}

/// Bridges the package:test controller and the remote tester.
///
/// Sets up a that allows the package:test test [controller] to communicate with
/// a [remoteSocket] that runs the test. The returned future completes when
/// either side is closed, which also indicates when the tests have finished.
Future<void> _controlTests({
  @required
  StreamChannel<dynamic> controller,
  @required
  WebSocket remoteSocket,
  @required
  void Function(dynamic, StackTrace) onError,
}) async {
  final Completer<void> harnessDone = Completer<void>();
  final StreamSubscription<dynamic> harnessToTest =
      controller.stream.listen(
    (dynamic event) {
      remoteSocket.add(json.encode(event));
    },
    onDone: harnessDone.complete,
    onError: (dynamic error, StackTrace stack) {
      globals.printError('test harness controller stream experienced an unexpected error');
      onError(error, stack);
    },
    cancelOnError: true,
  );

  final Completer<void> testDone = Completer<void>();
  final StreamSubscription<dynamic> testToHarness = remoteSocket.listen(
    (dynamic encodedEvent) {
      assert(encodedEvent is String); // we shouldn't ever get binary messages
      controller.sink.add(json.decode(encodedEvent as String));
    },
    onDone: testDone.complete,
    onError: (dynamic error, StackTrace stack) {
      globals.printError('test socket stream experienced an unexpected error');
      onError(error, stack);
    },
    cancelOnError: true,
  );

  globals.printTrace('waiting for test harness or tests to finish');

  await Future.any<void>(<Future<void>>[
    harnessDone.future.then<void>((void value) {
      globals.printTrace('test process is no longer needed by test harness');
    }),
    testDone.future.then<void>((void value) {
      globals.printTrace('test harness is no longer needed by test process');
    }),
  ]);

  await Future.wait<void>(<Future<void>>[
    harnessToTest.cancel(),
    testToHarness.cancel(),
  ]);
}
