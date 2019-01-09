// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite_platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/hack_register_platform.dart' as hack; // ignore: implementation_imports
import 'package:test_core/src/runner/runner_suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/plugin/platform_helpers.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/environment.dart'; // ignore: implementation_imports

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../vmservice.dart';
import 'bootstrap.dart';
import 'watcher.dart';

/// The timeout we give the test process to connect to the test harness
/// once the process has entered its main method.
const Duration _kTestStartupTimeout = Duration(minutes: 1);

/// The timeout we give the test process to start executing Dart code. When the
/// CPU is under severe load, this can take a while, but it's not indicative of
/// any problem with Flutter, so we give it a large timeout.
const Duration _kTestProcessTimeout = Duration(minutes: 5);

/// The address at which our WebSocket server resides and at which the sky_shell
/// processes will host the Observatory server.
final Map<InternetAddressType, InternetAddress> kHosts = <InternetAddressType, InternetAddress>{
  InternetAddressType.IPv4: InternetAddress.loopbackIPv4,
  InternetAddressType.IPv6: InternetAddress.loopbackIPv6,
};

/// Configure the `test` package to work with Flutter.
///
/// On systems where each [_FlutterPlatform] is only used to run one test suite
/// (that is, one Dart file with a `*_test.dart` file name and a single `void
/// main()`), you can set an observatory port explicitly.
void installHook({
  @required String shellPath,
  TestWatcher watcher,
  bool enableObservatory = false,
  bool machine = false,
  bool startPaused = false,
  int port = 0,
  @required Map<String, String> precompiledDillFiles,
  bool trackWidgetCreation = false,
  bool updateGoldens = false,
  int observatoryPort,
  InternetAddressType serverType = InternetAddressType.IPv4,
  Uri projectRootDirectory,
  Map<String, List<Finalizer>> fileFinalizers = const <String, List<Finalizer>>{},
}) {
  assert(enableObservatory || (!startPaused && observatoryPort == null));
  assert(precompiledDillFiles != null && precompiledDillFiles.isNotEmpty);
  hack.registerPlatformPlugin(
    <Runtime>[Runtime.vm],
    () => _FlutterPlatform(
      shellPath: shellPath,
      watcher: watcher,
      machine: machine,
      enableObservatory: enableObservatory,
      startPaused: startPaused,
      explicitObservatoryPort: observatoryPort,
      host: kHosts[serverType],
      port: port,
      precompiledDillFiles: precompiledDillFiles,
      trackWidgetCreation: trackWidgetCreation,
      updateGoldens: updateGoldens,
      projectRootDirectory: projectRootDirectory,
    ),
  );
}

enum _InitialResult { crashed, timedOut, connected }
enum _TestResult { crashed, harnessBailed, testBailed }

class _FlutterPlatform extends PlatformPlugin {
  _FlutterPlatform({
    @required this.shellPath,
    this.watcher,
    this.enableObservatory,
    this.machine,
    this.startPaused,
    this.explicitObservatoryPort,
    this.host,
    this.port,
    this.precompiledDillFiles,
    this.trackWidgetCreation,
    this.updateGoldens,
    this.projectRootDirectory,
  }) : assert(shellPath != null);

  final String shellPath;
  final TestWatcher watcher;
  final bool enableObservatory;
  final bool machine;
  final bool startPaused;
  final int explicitObservatoryPort;
  final InternetAddress host;
  final int port;
  final Map<String, String> precompiledDillFiles;
  final bool trackWidgetCreation;
  final bool updateGoldens;
  final Uri projectRootDirectory;

  Directory fontsDirectory;

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
    try {
      final StreamChannel<dynamic> channel = loadChannel(path, platform);
      final RunnerSuiteController controller = deserializeSuite(path, platform,
        suiteConfig, const PluginEnvironment(), channel, message);
      return await controller.suite;
    } catch (err) {
      /// Rethrow a less confusing error if it is a test incompatibility.
      if (err.toString().contains('type \'Declarer\' is not a subtype of type \'Declarer\'')) {
        throw UnsupportedError('Package incompatibility between flutter and test packages:\n'
          '  * flutter is incompatible with test <1.4.0.\n'
          '  * flutter is incompatible with mockito <4.0.0\n'
          'To fix this error, update test to at least \'^1.4.0\' and mockito to at least \'^4.0.0\'\n'
        );
      }
      // Guess it was a different error.
      rethrow;
    }
  }

  @override
  StreamChannel<dynamic> loadChannel(String testPath, SuitePlatform platform) {
    if (_testCount > 0) {
      // Fail if there will be a port conflict.
      if (explicitObservatoryPort != null)
        throwToolExit('installHook() was called with an observatory port or debugger mode enabled, but then more than one test suite was run.');
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
    testCompleteCompleter.complete(_startTest(testPath, localChannel, ourTestCount));
    return remoteChannel;
  }

  Future<_AsyncError> _startTest(
    String testPath,
    StreamChannel<dynamic> controller,
    int ourTestCount,
  ) async {
    printTrace('test $ourTestCount: starting test $testPath');

    _AsyncError
        outOfBandError; // error that we couldn't send to the harness that we need to send via our future

    final List<Finalizer> finalizers =
        <Finalizer>[]; // Will be run in reverse order.
    bool subprocessActive = false;
    bool controllerSinkClosed = false;
    try {
      // Callback can't throw since it's just setting a variable.
      controller.sink.done.whenComplete(() { // ignore: unawaited_futures
        controllerSinkClosed = true;
      }); // ignore: unawaited_futures

      // Prepare our WebSocket server to talk to the engine subproces.
      final HttpServer server = await HttpServer.bind(host, port);
      finalizers.add(() async {
        printTrace('test $ourTestCount: shutting down test harness socket server');
        await server.close(force: true);
      });
      final Completer<WebSocket> webSocket = Completer<WebSocket>();
      server.listen(
        (HttpRequest request) {
          if (!webSocket.isCompleted)
            webSocket.complete(WebSocketTransformer.upgrade(request));
        },
        onError: (dynamic error, dynamic stack) {
          // If you reach here, it's unlikely we're going to be able to really handle this well.
          printTrace('test $ourTestCount: test harness socket server experienced an unexpected error: $error');
          if (!controllerSinkClosed) {
            controller.sink.addError(error, stack);
            controller.sink.close();
          } else {
            printError('unexpected error from test harness socket server: $error');
          }
        },
        cancelOnError: true,
      );

      printTrace('test $ourTestCount: starting shell process');

      // If a kernel file is given, then use that to launch the test.
      // If mapping is provided, look kernel file from mapping.
      // If all fails, create a "listener" dart that invokes actual test.
      final String mainDart = precompiledDillFiles[testPath];

      final Process process = await _startProcess(
        shellPath,
        mainDart,
        packages: PackageMap.globalPackagesPath,
        enableObservatory: enableObservatory,
        startPaused: startPaused,
        observatoryPort: explicitObservatoryPort,
        serverPort: server.port,
      );
      subprocessActive = true;
      finalizers.add(() async {
        if (subprocessActive) {
          printTrace('test $ourTestCount: ensuring end-of-process for shell');
          process.kill();
          final int exitCode = await process.exitCode;
          subprocessActive = false;
          if (!controllerSinkClosed && exitCode != -15) {
            // ProcessSignal.SIGTERM
            // We expect SIGTERM (15) because we tried to terminate it.
            // It's negative because signals are returned as negative exit codes.
            final String message = _getErrorMessage(
                _getExitCodeMessage(exitCode, 'after tests finished'),
                testPath,
                shellPath);
            controller.sink.addError(message);
          }
        }
      });

      final Completer<void> timeout = Completer<void>();
      final Completer<void> gotProcessObservatoryUri = Completer<void>();
      if (!enableObservatory) {
        gotProcessObservatoryUri.complete();
      }

      // Pipe stdout and stderr from the subprocess to our printStatus console.
      // We also keep track of what observatory port the engine used, if any.
      Uri processObservatoryUri;
      _pipeStandardStreamsToConsole(
        process,
        reportObservatoryUri: (Uri detectedUri) {
          assert(processObservatoryUri == null);
          assert(explicitObservatoryPort == null ||
              explicitObservatoryPort == detectedUri.port);
          if (startPaused && !machine) {
            printStatus('The test process has been started.');
            printStatus('You can now connect to it using observatory. To connect, load the following Web site in your browser:');
            printStatus('  $detectedUri');
            printStatus('You should first set appropriate breakpoints, then resume the test in the debugger.');
          } else {
            printTrace('test $ourTestCount: using observatory uri $detectedUri from pid ${process.pid}');
          }
          processObservatoryUri = detectedUri;
          {
            printTrace('Connecting to service protocol: $processObservatoryUri');
            final Future<VMService> localVmService = VMService.connect(processObservatoryUri);
            localVmService.then((VMService vmservice) {
              printTrace('Successfully connected to service protocol: $processObservatoryUri');
            });
          }
          gotProcessObservatoryUri.complete();
          watcher?.handleStartedProcess(
              ProcessEvent(ourTestCount, process, processObservatoryUri));
        },
        startTimeoutTimer: () {
          Future<_InitialResult>.delayed(_kTestStartupTimeout)
              .then<void>((_) => timeout.complete());
        },
      );

      // At this point, three things can happen next:
      // The engine could crash, in which case process.exitCode will complete.
      // The engine could connect to us, in which case webSocket.future will complete.
      // The local test harness could get bored of us.

      printTrace('test $ourTestCount: awaiting initial result for pid ${process.pid}');
      final _InitialResult initialResult =
          await Future.any<_InitialResult>(<Future<_InitialResult>>[
        process.exitCode
            .then<_InitialResult>((int exitCode) => _InitialResult.crashed),
        timeout.future
            .then<_InitialResult>((void value) => _InitialResult.timedOut),
        Future<_InitialResult>.delayed(
            _kTestProcessTimeout, () => _InitialResult.timedOut),
        gotProcessObservatoryUri.future.then<_InitialResult>((void value) {
          return webSocket.future.then<_InitialResult>(
            (WebSocket webSocket) => _InitialResult.connected,
          );
        }),
      ]);

      switch (initialResult) {
        case _InitialResult.crashed:
          printTrace('test $ourTestCount: process with pid ${process.pid} crashed before connecting to test harness');
          final int exitCode = await process.exitCode;
          subprocessActive = false;
          final String message = _getErrorMessage(
              _getExitCodeMessage(
                  exitCode, 'before connecting to test harness'),
              testPath,
              shellPath);
          controller.sink.addError(message);
          // Awaited for with 'sink.done' below.
          controller.sink.close(); // ignore: unawaited_futures
          printTrace('test $ourTestCount: waiting for controller sink to close');
          await controller.sink.done;
          await watcher?.handleTestCrashed(ProcessEvent(ourTestCount, process));
          break;
        case _InitialResult.timedOut:
          // Could happen either if the process takes a long time starting
          // (_kTestProcessTimeout), or if once Dart code starts running, it takes a
          // long time to open the WebSocket connection (_kTestStartupTimeout).
          printTrace('test $ourTestCount: timed out waiting for process with pid ${process.pid} to connect to test harness');
          final String message = _getErrorMessage('Test never connected to test harness.', testPath, shellPath);
          controller.sink.addError(message);
          // Awaited for with 'sink.done' below.
          controller.sink.close(); // ignore: unawaited_futures
          printTrace('test $ourTestCount: waiting for controller sink to close');
          await controller.sink.done;
          await watcher
              ?.handleTestTimedOut(ProcessEvent(ourTestCount, process));
          break;
        case _InitialResult.connected:
          printTrace('test $ourTestCount: process with pid ${process.pid} connected to test harness');
          final WebSocket testSocket = await webSocket.future;

          final Completer<void> harnessDone = Completer<void>();
          final StreamSubscription<dynamic> harnessToTest =
              controller.stream.listen(
            (dynamic event) {
              testSocket.add(json.encode(event));
            },
            onDone: harnessDone.complete,
            onError: (dynamic error, dynamic stack) {
              // If you reach here, it's unlikely we're going to be able to really handle this well.
              printError('test harness controller stream experienced an unexpected error\ntest: $testPath\nerror: $error');
              if (!controllerSinkClosed) {
                controller.sink.addError(error, stack);
                controller.sink.close();
              } else {
                printError('unexpected error from test harness controller stream: $error');
              }
            },
            cancelOnError: true,
          );

          final Completer<void> testDone = Completer<void>();
          final StreamSubscription<dynamic> testToHarness = testSocket.listen(
            (dynamic encodedEvent) {
              assert(encodedEvent
                  is String); // we shouldn't ever get binary messages
              controller.sink.add(json.decode(encodedEvent));
            },
            onDone: testDone.complete,
            onError: (dynamic error, dynamic stack) {
              // If you reach here, it's unlikely we're going to be able to really handle this well.
              printError('test socket stream experienced an unexpected error\ntest: $testPath\nerror: $error');
              if (!controllerSinkClosed) {
                controller.sink.addError(error, stack);
                controller.sink.close();
              } else {
                printError('unexpected error from test socket stream: $error');
              }
            },
            cancelOnError: true,
          );

          printTrace('test $ourTestCount: awaiting test result for pid ${process.pid}');
          final _TestResult testResult =
              await Future.any<_TestResult>(<Future<_TestResult>>[
            process.exitCode.then<_TestResult>((int exitCode) {
              return _TestResult.crashed;
            }),
            harnessDone.future.then<_TestResult>((void value) {
              return _TestResult.harnessBailed;
            }),
            testDone.future.then<_TestResult>((void value) {
              return _TestResult.testBailed;
            }),
          ]);

          await Future.wait<void>(<Future<void>>[
            harnessToTest.cancel(),
            testToHarness.cancel(),
          ]);

          switch (testResult) {
            case _TestResult.crashed:
              printTrace('test $ourTestCount: process with pid ${process.pid} crashed');
              final int exitCode = await process.exitCode;
              subprocessActive = false;
              final String message = _getErrorMessage(
                  _getExitCodeMessage(
                      exitCode, 'before test harness closed its WebSocket'),
                  testPath,
                  shellPath);
              controller.sink.addError(message);
              // Awaited for with 'sink.done' below.
              controller.sink.close(); // ignore: unawaited_futures
              printTrace('test $ourTestCount: waiting for controller sink to close');
              await controller.sink.done;
              break;
            case _TestResult.harnessBailed:
            case _TestResult.testBailed:
              if (testResult == _TestResult.harnessBailed) {
                printTrace('test $ourTestCount: process with pid ${process.pid} no longer needed by test harness');
              } else {
                assert(testResult == _TestResult.testBailed);
                printTrace('test $ourTestCount: process with pid ${process.pid} no longer needs test harness');
              }
              await watcher?.handleFinishedTest(
                  ProcessEvent(ourTestCount, process, processObservatoryUri));
              break;
          }
          break;
      }
    } catch (error, stack) {
      printTrace('test $ourTestCount: error caught during test; ${controllerSinkClosed ? "reporting to console" : "sending to test framework"}');
      if (!controllerSinkClosed) {
        controller.sink.addError(error, stack);
      } else {
        printError('unhandled error during test:\n$testPath\n$error\n$stack');
        outOfBandError ??= _AsyncError(error, stack);
      }
    } finally {
      printTrace('test $ourTestCount: cleaning up...');
      // Finalizers are treated like a stack; run them in reverse order.
      for (Finalizer finalizer in finalizers.reversed) {
        try {
          await finalizer();
        } catch (error, stack) {
          printTrace('test $ourTestCount: error while cleaning up; ${controllerSinkClosed ? "reporting to console" : "sending to test framework"}');
          if (!controllerSinkClosed) {
            controller.sink.addError(error, stack);
          } else {
            printError('unhandled error during finalization of test:\n$testPath\n$error\n$stack');
            outOfBandError ??= _AsyncError(error, stack);
          }
        }
      }
      if (!controllerSinkClosed) {
        // Waiting below with await.
        controller.sink.close(); // ignore: unawaited_futures
        printTrace('test $ourTestCount: waiting for controller sink to close');
        await controller.sink.done;
      }
    }
    assert(!subprocessActive);
    assert(controllerSinkClosed);
    if (outOfBandError != null) {
      printTrace('test $ourTestCount: finished with out-of-band failure');
    } else {
      printTrace('test $ourTestCount: finished');
    }
    return outOfBandError;
  }

  File _cachedFontConfig;

  @override
  Future<dynamic> close() async {
    if (fontsDirectory != null) {
      printTrace('Deleting ${fontsDirectory.path}...');
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
    sb.writeln('  <dir>${cache.getCacheArtifacts().path}</dir>');
    sb.writeln('  <cachedir>/var/cache/fontconfig</cachedir>');
    sb.writeln('</fontconfig>');

    if (fontsDirectory == null) {
      fontsDirectory = fs.systemTempDirectory.createTempSync('flutter_test_fonts.');
      printTrace('Using this directory for fonts configuration: ${fontsDirectory.path}');
    }

    _cachedFontConfig = fs.file('${fontsDirectory.path}/fonts.conf');
    _cachedFontConfig.createSync();
    _cachedFontConfig.writeAsStringSync(sb.toString());
    return _cachedFontConfig;
  }

  Future<Process> _startProcess(
    String executable,
    String testPath, {
    String packages,
    bool enableObservatory = false,
    bool startPaused = false,
    int observatoryPort,
    int serverPort,
  }) {
    assert(executable != null); // Please provide the path to the shell in the SKY_SHELL environment variable.
    assert(!startPaused || enableObservatory);
    final List<String> command = <String>[executable];
    if (enableObservatory) {
      // Some systems drive the _FlutterPlatform class in an unusual way, where
      // only one test file is processed at a time, and the operating
      // environment hands out specific ports ahead of time in a cooperative
      // manner, where we're only allowed to open ports that were given to us in
      // advance like this. For those esoteric systems, we have this feature
      // whereby you can create _FlutterPlatform with a pair of ports.
      //
      // I mention this only so that you won't be tempted, as I was, to apply
      // the obvious simplification to this code and remove this entire feature.
      if (observatoryPort != null)
        command.add('--observatory-port=$observatoryPort');
      if (startPaused) {
        command.add('--start-paused');
      }
    } else {
      command.add('--disable-observatory');
    }
    if (host.type == InternetAddressType.IPv6) {
      command.add('--ipv6');
    }

    command.add('--enable-checked-mode');
    command.addAll(<String>[
      '--enable-software-rendering',
      '--skia-deterministic-rendering',
      '--enable-dart-profiling',
      '--non-interactive',
      '--use-test-fonts',
      '--packages=$packages',
      testPath,
    ]);
    printTrace(command.join(' '));
    final Map<String, String> environment = <String, String>{
      'FLUTTER_TEST': 'true',
      'FONTCONFIG_FILE': _fontConfigFile.path,
      'SERVER_PORT': serverPort.toString(),
    };
    return processManager.start(command, environment: environment);
  }

  void _pipeStandardStreamsToConsole(
    Process process, {
    void startTimeoutTimer(),
    void reportObservatoryUri(Uri uri),
  }) {
    const String observatoryString = 'Observatory listening on ';
    for (Stream<List<int>> stream in <Stream<List<int>>>[
      process.stderr,
      process.stdout
    ]) {
      stream
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen(
        (String line) {
          if (line == kStartTimeoutTimerMessage) {
            if (startTimeoutTimer != null) {
              startTimeoutTimer();
            }
          } else if (line.startsWith('error: Unable to read Dart source \'package:test/')) {
            printTrace('Shell: $line');
            printError('\n\nFailed to load test harness. Are you missing a dependency on flutter_test?\n');
          } else if (line.startsWith(observatoryString)) {
            printTrace('Shell: $line');
            try {
              final Uri uri = Uri.parse(line.substring(observatoryString.length));
              if (reportObservatoryUri != null) {
                reportObservatoryUri(uri);
              }
            } catch (error) {
              printError('Could not parse shell observatory port message: $error');
            }
          } else if (line != null) {
            printStatus('Shell: $line');
          }
        },
        onError: (dynamic error) {
          printError('shell console stream for process pid ${process.pid} experienced an unexpected error: $error');
        },
        cancelOnError: true,
      );
    }
  }

  String _getErrorMessage(String what, String testPath, String shellPath) {
    return '$what\nTest: $testPath\nShell: $shellPath\n\n';
  }

  String _getExitCodeMessage(int exitCode, String when) {
    switch (exitCode) {
      case 1:
        return 'Shell subprocess cleanly reported an error $when. Check the logs above for an error message.';
      case 0:
        return 'Shell subprocess ended cleanly $when. Did main() call exit()?';
      case -0x0f: // ProcessSignal.SIGTERM
        return 'Shell subprocess crashed with SIGTERM ($exitCode) $when.';
      case -0x0b: // ProcessSignal.SIGSEGV
        return 'Shell subprocess crashed with segmentation fault $when.';
      case -0x06: // ProcessSignal.SIGABRT
        return 'Shell subprocess crashed with SIGABRT ($exitCode) $when.';
      case -0x02: // ProcessSignal.SIGINT
        return 'Shell subprocess terminated by ^C (SIGINT, $exitCode) $when.';
      default:
        return 'Shell subprocess crashed with unexpected exit code $exitCode $when.';
    }
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
        if (futureResults.last is _AsyncError) {
          _done.completeError(futureResults.last.error, futureResults.last.stack);
        } else {
          assert(futureResults.last == null);
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
  void addError(dynamic errorEvent, [StackTrace stackTrace]) => _parent.addError(errorEvent, stackTrace);
  @override
  Future<dynamic> addStream(Stream<S> stream) => _parent.addStream(stream);
}

@immutable
class _AsyncError {
  const _AsyncError(this.error, this.stack);
  final dynamic error;
  final StackTrace stack;
}
