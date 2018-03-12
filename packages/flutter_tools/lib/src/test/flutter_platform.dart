// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'package:test/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test/src/backend/suite_platform.dart'; // ignore: implementation_imports
import 'package:test/src/runner/plugin/platform.dart'; // ignore: implementation_imports
import 'package:test/src/runner/plugin/hack_register_platform.dart' as hack; // ignore: implementation_imports

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../compile.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import 'watcher.dart';

/// The timeout we give the test process to connect to the test harness
/// once the process has entered its main method.
const Duration _kTestStartupTimeout = const Duration(minutes: 1);

/// The timeout we give the test process to start executing Dart code. When the
/// CPU is under severe load, this can take a while, but it's not indicative of
/// any problem with Flutter, so we give it a large timeout.
const Duration _kTestProcessTimeout = const Duration(minutes: 5);

/// Message logged by the test process to signal that its main method has begun
/// execution.
///
/// The test harness responds by starting the [_kTestStartupTimeout] countdown.
/// The CPU may be throttled, which can cause a long delay in between when the
/// process is spawned and when dart code execution begins; we don't want to
/// hold that against the test.
const String _kStartTimeoutTimerMessage = 'sky_shell test process has entered main method';

/// The address at which our WebSocket server resides and at which the sky_shell
/// processes will host the Observatory server.
final Map<InternetAddressType, InternetAddress> _kHosts = <InternetAddressType, InternetAddress>{
  InternetAddressType.IP_V4: InternetAddress.LOOPBACK_IP_V4,
  InternetAddressType.IP_V6: InternetAddress.LOOPBACK_IP_V6,
};

/// Configure the `test` package to work with Flutter.
///
/// On systems where each [_FlutterPlatform] is only used to run one test suite
/// (that is, one Dart file with a `*_test.dart` file name and a single `void
/// main()`), you can set an observatory port explicitly.
void installHook({
  @required String shellPath,
  TestWatcher watcher,
  bool enableObservatory: false,
  bool machine: false,
  bool startPaused: false,
  bool previewDart2: false,
  int port: 0,
  String precompiledDillPath,
  bool trackWidgetCreation: false,
  int observatoryPort,
  InternetAddressType serverType: InternetAddressType.IP_V4,
}) {
  if (startPaused || observatoryPort != null)
    assert(enableObservatory);
  hack.registerPlatformPlugin(
    <Runtime>[Runtime.vm],
    () => new _FlutterPlatform(
      shellPath: shellPath,
      watcher: watcher,
      machine: machine,
      enableObservatory: enableObservatory,
      startPaused: startPaused,
      explicitObservatoryPort: observatoryPort,
      host: _kHosts[serverType],
      previewDart2: previewDart2,
      port: port,
      precompiledDillPath: precompiledDillPath,
      trackWidgetCreation: trackWidgetCreation,
    ),
  );
}

enum _InitialResult { crashed, timedOut, connected }
enum _TestResult { crashed, harnessBailed, testBailed }
typedef Future<Null> _Finalizer();

class _CompilationRequest {
  String path;
  Completer<String> result;

  _CompilationRequest(this.path, this.result);
}

// This class is a wrapper around compiler that allows multiple isolates to
// enqueue compilation requests, but ensures only one compilation at a time.
class _Compiler {
  _Compiler(bool trackWidgetCreation) {
    // Compiler maintains and updates single incremental dill file.
    // Incremental compilation requests done for each test copy that file away
    // for independent execution.
    final Directory outputDillDirectory = fs.systemTempDirectory
        .createTempSync('output_dill');
    final File outputDill = outputDillDirectory.childFile('output.dill');

    compilerController.stream.listen((_CompilationRequest request) async {
      final bool isEmpty = compilationQueue.isEmpty;
      compilationQueue.add(request);
      // Only trigger processing if queue was empty - i.e. no other requests
      // are currently being processed. This effectively enforces "one
      // compilation request at a time".
      if (isEmpty) {
        while (compilationQueue.isNotEmpty) {
          final _CompilationRequest request = compilationQueue.first;
          printTrace('Compiling ${request.path}');
          final String outputPath = await compiler.recompile(request.path,
            <String>[request.path],
            outputPath: outputDill.path,
          );
          // Copy output dill next to the source file.
          final File kernelReadyToRun = await fs.file(outputPath).copy(
              request.path + '.dill');
          compiler.accept();
          compiler.reset();
          request.result.complete(kernelReadyToRun.path);
          // Only remove now when we finished processing the element
          compilationQueue.removeAt(0);
        }
      }
    }, onDone: () {
      outputDillDirectory.deleteSync(recursive: true);
    });

    compiler = new ResidentCompiler(
        artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
        packagesPath: PackageMap.globalPackagesPath,
        trackWidgetCreation: trackWidgetCreation);
  }

  final StreamController<_CompilationRequest> compilerController =
      new StreamController<_CompilationRequest>();
  final List<_CompilationRequest> compilationQueue = <_CompilationRequest>[];
  ResidentCompiler compiler;

  Future<String> compile(String mainDart) {
    final Completer<String> completer = new Completer<String>();
    compilerController.add(new _CompilationRequest(mainDart, completer));
    return completer.future;
  }
}

class _FlutterPlatform extends PlatformPlugin {
  _FlutterPlatform({
    @required this.shellPath,
    this.watcher,
    this.enableObservatory,
    this.machine,
    this.startPaused,
    this.explicitObservatoryPort,
    this.host,
    this.previewDart2,
    this.port,
    this.precompiledDillPath,
    this.trackWidgetCreation,
  }) : assert(shellPath != null);

  final String shellPath;
  final TestWatcher watcher;
  final bool enableObservatory;
  final bool machine;
  final bool startPaused;
  final int explicitObservatoryPort;
  final InternetAddress host;
  final bool previewDart2;
  final int port;
  final String precompiledDillPath;
  final bool trackWidgetCreation;

  _Compiler compiler;

  // Each time loadChannel() is called, we spin up a local WebSocket server,
  // then spin up the engine in a subprocess. We pass the engine a Dart file
  // that connects to our WebSocket server, then we proxy JSON messages from
  // the test harness to the engine and back again. If at any time the engine
  // crashes, we inject an error into that stream. When the process closes,
  // we clean everything up.

  int _testCount = 0;

  @override
  StreamChannel<dynamic> loadChannel(String testPath, SuitePlatform platform) {
    if (_testCount > 0) {
      // Fail if there will be a port conflict.
      if (explicitObservatoryPort != null)
        throwToolExit('installHook() was called with an observatory port or debugger mode enabled, but then more than one test suite was run.');
      // Fail if we're passing in a precompiled entry-point.
      if (precompiledDillPath != null)
        throwToolExit('installHook() was called with a precompiled test entry-point, but then more than one test suite was run.');
    }
    final int ourTestCount = _testCount;
    _testCount += 1;
    final StreamController<dynamic> localController = new StreamController<dynamic>();
    final StreamController<dynamic> remoteController = new StreamController<dynamic>();
    final Completer<Null> testCompleteCompleter = new Completer<Null>();
    final _FlutterPlatformStreamSinkWrapper<dynamic> remoteSink = new _FlutterPlatformStreamSinkWrapper<dynamic>(
      remoteController.sink,
      testCompleteCompleter.future,
    );
    final StreamChannel<dynamic> localChannel = new StreamChannel<dynamic>.withGuarantees(
      remoteController.stream,
      localController.sink,
    );
    final StreamChannel<dynamic> remoteChannel = new StreamChannel<dynamic>.withGuarantees(
      localController.stream,
      remoteSink,
    );
    testCompleteCompleter.complete(_startTest(testPath, localChannel, ourTestCount));
    return remoteChannel;
  }

  Future<Null> _startTest(
    String testPath,
    StreamChannel<dynamic> controller,
    int ourTestCount) async {
    printTrace('test $ourTestCount: starting test $testPath');

    dynamic outOfBandError; // error that we couldn't send to the harness that we need to send via our future

    final List<_Finalizer> finalizers = <_Finalizer>[];
    bool subprocessActive = false;
    bool controllerSinkClosed = false;
    try {
      // Callback can't throw since it's just setting a variable.
      controller.sink.done.whenComplete(() { controllerSinkClosed = true; }); // ignore: unawaited_futures

      // Prepare our WebSocket server to talk to the engine subproces.
      final HttpServer server = await HttpServer.bind(host, port);
      finalizers.add(() async {
        printTrace('test $ourTestCount: shutting down test harness socket server');
        await server.close(force: true);
      });
      final Completer<WebSocket> webSocket = new Completer<WebSocket>();
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

      printTrace('test $ourTestCount: starting shell process${previewDart2? " in preview-dart-2 mode":""}');

      // [precompiledDillPath] can be set only if [previewDart2] is [true].
      assert(precompiledDillPath == null || previewDart2);
      // If a kernel file is given, then use that to launch the test.
      // Otherwise create a "listener" dart that invokes actual test.
      String mainDart = precompiledDillPath != null
          ? precompiledDillPath
          : _createListenerDart(finalizers, ourTestCount, testPath, server);

      if (previewDart2 && precompiledDillPath == null) {
        // Lazily instantiate compiler so it is built only if it is actually used.
        compiler ??= new _Compiler(trackWidgetCreation);
        mainDart = await compiler.compile(mainDart);

        if (mainDart == null) {
          controller.sink.addError(
              _getErrorMessage('Compilation failed', testPath, shellPath));
          return null;
        }
      }

      final Process process = await _startProcess(
        shellPath,
        mainDart,
        packages: PackageMap.globalPackagesPath,
        enableObservatory: enableObservatory,
        startPaused: startPaused,
        bundlePath: _getBundlePath(finalizers, ourTestCount),
        observatoryPort: explicitObservatoryPort,
      );
      subprocessActive = true;
      finalizers.add(() async {
        if (subprocessActive) {
          printTrace('test $ourTestCount: ensuring end-of-process for shell');
          process.kill();
          final int exitCode = await process.exitCode;
          subprocessActive = false;
          if (!controllerSinkClosed && exitCode != -15) { // ProcessSignal.SIGTERM
            // We expect SIGTERM (15) because we tried to terminate it.
            // It's negative because signals are returned as negative exit codes.
            final String message = _getErrorMessage(_getExitCodeMessage(exitCode, 'after tests finished'), testPath, shellPath);
            controller.sink.addError(message);
          }
        }
      });

      final Completer<Null> timeout = new Completer<Null>();

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
          if (watcher != null) {
            watcher.onStartedProcess(new ProcessEvent(ourTestCount, process, detectedUri));
          }
          processObservatoryUri = detectedUri;
        },
        startTimeoutTimer: () {
          new Future<_InitialResult>.delayed(_kTestStartupTimeout).then((_) => timeout.complete());
        },
      );

      // At this point, three things can happen next:
      // The engine could crash, in which case process.exitCode will complete.
      // The engine could connect to us, in which case webSocket.future will complete.
      // The local test harness could get bored of us.

      printTrace('test $ourTestCount: awaiting initial result for pid ${process.pid}');
      final _InitialResult initialResult = await Future.any(<Future<_InitialResult>>[
        process.exitCode.then<_InitialResult>((int exitCode) => _InitialResult.crashed),
        timeout.future.then<_InitialResult>((Null _) => _InitialResult.timedOut),
        new Future<_InitialResult>.delayed(_kTestProcessTimeout, () => _InitialResult.timedOut),
        webSocket.future.then<_InitialResult>((WebSocket webSocket) => _InitialResult.connected),
      ]);

      switch (initialResult) {
        case _InitialResult.crashed:
          printTrace('test $ourTestCount: process with pid ${process.pid} crashed before connecting to test harness');
          final int exitCode = await process.exitCode;
          subprocessActive = false;
          final String message = _getErrorMessage(_getExitCodeMessage(exitCode, 'before connecting to test harness'), testPath, shellPath);
          controller.sink.addError(message);
          // Awaited for with 'sink.done' below.
          controller.sink.close(); // ignore: unawaited_futures
          printTrace('test $ourTestCount: waiting for controller sink to close');
          await controller.sink.done;
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
          break;
        case _InitialResult.connected:
          printTrace('test $ourTestCount: process with pid ${process.pid} connected to test harness');
          final WebSocket testSocket = await webSocket.future;

          final Completer<Null> harnessDone = new Completer<Null>();
          final StreamSubscription<dynamic> harnessToTest = controller.stream.listen(
            (dynamic event) { testSocket.add(json.encode(event)); },
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

          final Completer<Null> testDone = new Completer<Null>();
          final StreamSubscription<dynamic> testToHarness = testSocket.listen(
            (dynamic encodedEvent) {
              assert(encodedEvent is String); // we shouldn't ever get binary messages
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
          final _TestResult testResult = await Future.any(<Future<_TestResult>>[
            process.exitCode.then<_TestResult>((int exitCode) { return _TestResult.crashed; }),
            harnessDone.future.then<_TestResult>((Null _) { return _TestResult.harnessBailed; }),
            testDone.future.then<_TestResult>((Null _) { return _TestResult.testBailed; }),
          ]);

          await Future.wait(<Future<Null>>[
            harnessToTest.cancel(),
            testToHarness.cancel(),
          ]);

          switch (testResult) {
            case _TestResult.crashed:
              printTrace('test $ourTestCount: process with pid ${process.pid} crashed');
              final int exitCode = await process.exitCode;
              subprocessActive = false;
              final String message = _getErrorMessage(_getExitCodeMessage(exitCode, 'before test harness closed its WebSocket'), testPath, shellPath);
              controller.sink.addError(message);
              // Awaited for with 'sink.done' below.
              controller.sink.close(); // ignore: unawaited_futures
              printTrace('test $ourTestCount: waiting for controller sink to close');
              await controller.sink.done;
              break;
            case _TestResult.harnessBailed:
              printTrace('test $ourTestCount: process with pid ${process.pid} no longer needed by test harness');
              break;
            case _TestResult.testBailed:
              printTrace('test $ourTestCount: process with pid ${process.pid} no longer needs test harness');
              break;
          }
          break;
      }

      if (subprocessActive && watcher != null) {
        await watcher.onFinishedTests(
            new ProcessEvent(ourTestCount, process, processObservatoryUri));
      }
    } catch (error, stack) {
      printTrace('test $ourTestCount: error caught during test; ${controllerSinkClosed ? "reporting to console" : "sending to test framework"}');
      if (!controllerSinkClosed) {
        controller.sink.addError(error, stack);
      } else {
        printError('unhandled error during test:\n$testPath\n$error');
        outOfBandError ??= error;
      }
    } finally {
      printTrace('test $ourTestCount: cleaning up...');
      for (_Finalizer finalizer in finalizers) {
        try {
          await finalizer();
        } catch (error, stack) {
          printTrace('test $ourTestCount: error while cleaning up; ${controllerSinkClosed ? "reporting to console" : "sending to test framework"}');
          if (!controllerSinkClosed) {
            controller.sink.addError(error, stack);
          } else {
            printError('unhandled error during finalization of test:\n$testPath\n$error');
            outOfBandError ??= error;
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
      throw outOfBandError;
    }
    printTrace('test $ourTestCount: finished');
    return null;
  }

  String _createListenerDart(List<_Finalizer> finalizers, int ourTestCount,
      String testPath, HttpServer server) {
    // Prepare a temporary directory to store the Dart file that will talk to us.
    final Directory temporaryDirectory = fs.systemTempDirectory
        .createTempSync('dart_test_listener');
    finalizers.add(() async {
      printTrace('test $ourTestCount: deleting temporary directory');
      temporaryDirectory.deleteSync(recursive: true);
    });

    // Prepare the Dart file that will talk to us and start the test.
    final File listenerFile = fs.file('${temporaryDirectory.path}/listener.dart');
    listenerFile.createSync();
    listenerFile.writeAsStringSync(_generateTestMain(
      testUrl: fs.path.toUri(fs.path.absolute(testPath)).toString(),
      encodedWebsocketUrl: Uri.encodeComponent(_getWebSocketUrl(server))
    ));
    return listenerFile.path;
  }

  String _getBundlePath(List<_Finalizer> finalizers, int ourTestCount) {
    if (!previewDart2) {
      return null;
    }

    if (precompiledDillPath != null) {
      return artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath);
    }

    // bundlePath needs to point to a folder with `platform.dill` file.
    final Directory tempBundleDirectory = fs.systemTempDirectory
        .createTempSync('flutter_bundle_directory');
    finalizers.add(() async {
      printTrace(
          'test $ourTestCount: deleting temporary bundle directory');
      tempBundleDirectory.deleteSync(recursive: true);
    });

    // copy 'vm_platform_strong.dill' into 'platform.dill'
    final File vmPlatformStrongDill = fs.file(
      artifacts.getArtifactPath(Artifact.platformKernelDill),
    );
    final File platformDill = vmPlatformStrongDill.copySync(
      tempBundleDirectory
          .childFile('platform.dill')
          .path,
    );
    if (!platformDill.existsSync()) {
      printError('unexpected error copying platform kernel file');
    }

    return tempBundleDirectory.path;
  }

  String _getWebSocketUrl(HttpServer server) {
    return host.type == InternetAddressType.IP_V4
        ? 'ws://${host.address}:${server.port}'
        : 'ws://[${host.address}]:${server.port}';
  }

  String _generateTestMain({
    String testUrl,
    String encodedWebsocketUrl,
  }) {
    return '''
import 'dart:convert';
import 'dart:io'; // ignore: dart_io_import

// We import this library first in order to trigger an import error for
// package:test (rather than package:stream_channel) when the developer forgets
// to add a dependency on package:test.
import 'package:test/src/runner/plugin/remote_platform_helpers.dart';

import 'package:stream_channel/stream_channel.dart';
import 'package:test/src/runner/vm/catch_isolate_errors.dart';

import '$testUrl' as test;

void main() {
  print('$_kStartTimeoutTimerMessage');
  String server = Uri.decodeComponent('$encodedWebsocketUrl');
  StreamChannel channel = serializeSuite(() {
    catchIsolateErrors();
    return test.main;
  });
  WebSocket.connect(server).then((WebSocket socket) {
    socket.map((dynamic x) {
      assert(x is String);
      return json.decode(x);
    }).pipe(channel.sink);
    socket.addStream(channel.stream.map(json.encode));
  });
}
''';
  }

  File _cachedFontConfig;

  /// Returns a Fontconfig config file that limits font fallback to the
  /// artifact cache directory.
  File get _fontConfigFile {
    if (_cachedFontConfig != null)
      return _cachedFontConfig;

    final StringBuffer sb = new StringBuffer();
    sb.writeln('<fontconfig>');
    sb.writeln('  <dir>${cache.getCacheArtifacts().path}</dir>');
    sb.writeln('  <cachedir>/var/cache/fontconfig</cachedir>');
    sb.writeln('</fontconfig>');

    final Directory fontsDir = fs.systemTempDirectory.createTempSync('flutter_fonts');
    _cachedFontConfig = fs.file('${fontsDir.path}/fonts.conf');
    _cachedFontConfig.createSync();
    _cachedFontConfig.writeAsStringSync(sb.toString());
    return _cachedFontConfig;
  }

  Future<Process> _startProcess(
    String executable,
    String testPath, {
    String packages,
    String bundlePath,
    bool enableObservatory: false,
    bool startPaused: false,
    int observatoryPort,
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
      if (startPaused)
        command.add('--start-paused');
    } else {
      command.add('--disable-observatory');
    }
    if (host.type == InternetAddressType.IP_V6)
      command.add('--ipv6');
    if (bundlePath != null) {
      command.add('--flutter-assets-dir=$bundlePath');
    }
    command.add('--enable-checked-mode');
    command.addAll(<String>[
      '--enable-dart-profiling',
      '--non-interactive',
      '--use-test-fonts',
      // '--enable-txt', // enable this to test libtxt rendering
      '--packages=$packages',
      testPath,
    ]);
    printTrace(command.join(' '));
    final Map<String, String> environment = <String, String>{
      'FLUTTER_TEST': 'true',
      'FONTCONFIG_FILE': _fontConfigFile.path,
    };
    return processManager.start(command, environment: environment);
  }

  void _pipeStandardStreamsToConsole(
    Process process, {
    void startTimeoutTimer(),
    void reportObservatoryUri(Uri uri),
  }) {
    const String observatoryString = 'Observatory listening on ';

    for (Stream<List<int>> stream in
        <Stream<List<int>>>[process.stderr, process.stdout]) {
      stream.transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (String line) {
            if (line == _kStartTimeoutTimerMessage) {
              if (startTimeoutTimer != null)
                startTimeoutTimer();
            } else if (line.startsWith('error: Unable to read Dart source \'package:test/')) {
              printTrace('Shell: $line');
              printError('\n\nFailed to load test harness. Are you missing a dependency on flutter_test?\n');
            } else if (line.startsWith(observatoryString)) {
              printTrace('Shell: $line');
              try {
                final Uri uri = Uri.parse(line.substring(observatoryString.length));
                if (reportObservatoryUri != null)
                  reportObservatoryUri(uri);
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

class _FlutterPlatformStreamSinkWrapper<S> implements StreamSink<S> {
  _FlutterPlatformStreamSinkWrapper(this._parent, this._shellProcessClosed);
  final StreamSink<S> _parent;
  final Future<Null> _shellProcessClosed;

  @override
  Future<Null> get done => _done.future;
  final Completer<Null> _done = new Completer<Null>();

  @override
  Future<dynamic> close() {
   Future.wait<dynamic>(<Future<dynamic>>[
      _parent.close(),
      _shellProcessClosed,
    ]).then<Null>(
      (List<dynamic> value) {
        _done.complete();
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
