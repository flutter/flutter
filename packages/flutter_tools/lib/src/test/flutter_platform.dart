// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:path/path.dart' as path;
import 'package:stream_channel/stream_channel.dart';

import 'package:test/src/backend/test_platform.dart'; // ignore: implementation_imports
import 'package:test/src/runner/plugin/platform.dart'; // ignore: implementation_imports
import 'package:test/src/runner/plugin/hack_register_platform.dart' as hack; // ignore: implementation_imports

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import 'coverage_collector.dart';

const Duration _kTestStartupTimeout = const Duration(seconds: 5);
final InternetAddress _kHost = InternetAddress.LOOPBACK_IP_V4;

void installHook({ String shellPath }) {
  hack.registerPlatformPlugin(<TestPlatform>[TestPlatform.vm], () => new FlutterPlatform(shellPath: shellPath));
}

enum _InitialResult { crashed, timedOut, connected }
enum _TestResult { crashed, harnessBailed, completed }
typedef Future<Null> _Finalizer();

class FlutterPlatform extends PlatformPlugin {
  FlutterPlatform({ this.shellPath }) {
    assert(shellPath != null);
  }

  final String shellPath;

  // Each time loadChannel() is called, we spin up a local WebSocket server,
  // then spin up the engine in a subprocess. We pass the engine a Dart file
  // that connects to our WebSocket server, then we proxy JSON messages from
  // the test harness to the engine and back again. If at any time the engine
  // crashes, we inject an error into that stream. When the process closes,
  // we clean everything up.

  @override
  StreamChannel<dynamic> loadChannel(String testPath, TestPlatform platform) {
    final StreamChannelController<dynamic> controller = new StreamChannelController<dynamic>(allowForeignErrors: false);
    _startTest(testPath, controller.local);
    return controller.foreign;
  }

  Future<Null> _startTest(String testPath, StreamChannel<dynamic> controller) async {
    printTrace('starting test: $testPath');

    final List<_Finalizer> finalizers = <_Finalizer>[];
    bool subprocessActive = false;
    bool controllerSinkClosed = false;
    try {
      controller.sink.done.then((_) { controllerSinkClosed = true; });

      // Prepare our WebSocket server to talk to the engine subproces.
      HttpServer server = await HttpServer.bind(_kHost, 0);
      finalizers.add(() async { await server.close(force: true); });
      Completer<WebSocket> webSocket = new Completer<WebSocket>();
      server.listen((HttpRequest request) {
        webSocket.complete(WebSocketTransformer.upgrade(request));
      });

      // Prepare a temporary directory to store the Dart file that will talk to us.
      Directory temporaryDirectory = fs.systemTempDirectory.createTempSync('dart_test_listener');
      finalizers.add(() async { temporaryDirectory.deleteSync(recursive: true); });

      // Prepare the Dart file that will talk to us and start the test.
      File listenerFile = fs.file('${temporaryDirectory.path}/listener.dart');
      listenerFile.createSync();
      listenerFile.writeAsStringSync(_generateTestMain(
        testUrl: path.toUri(path.absolute(testPath)).toString(),
        encodedWebsocketUrl: Uri.encodeComponent("ws://${_kHost.address}:${server.port}"),
      ));

      // If we are collecting coverage data, then set that up now.
      int observatoryPort;
      if (CoverageCollector.instance.enabled) {
        // TODO(ianh): the random number on the next line is a landmine that will eventually
        // cause a hard-to-find bug...
        observatoryPort = CoverageCollector.instance.observatoryPort ?? new math.Random().nextInt(30000) + 2000;
        await CoverageCollector.instance.finishPendingJobs();
      }

      // Start the engine subprocess.
      Process process = await _startProcess(
        shellPath,
        listenerFile.path,
        packages: PackageMap.globalPackagesPath,
        observatoryPort: observatoryPort,
      );
      subprocessActive = true;
      finalizers.add(() async {
        if (subprocessActive)
          process.kill();
        int exitCode = await process.exitCode;
        subprocessActive = false;
        if (!controllerSinkClosed && exitCode != 0) {
          String message = _getErrorMessage(_getExitCodeMessage(exitCode, 'after tests finished'), testPath, shellPath);
          controller.sink.addError(new Exception(message));
        }
      });

      // Pipe stdout and stderr from the subprocess to our printStatus console.
      _pipeStandardStreamsToConsole(process);

      // At this point, three things can happen next:
      // The engine could crash, in which case process.exitCode will complete.
      // The engine could connect to us, in which case webSocket.future will complete.
      // The local test harness could get bored of us.

      _InitialResult initialResult = await Future.any(<Future<_InitialResult>>[
        process.exitCode.then<_InitialResult>((int exitCode) { return _InitialResult.crashed; }),
        new Future<_InitialResult>.delayed(_kTestStartupTimeout, () { return _InitialResult.timedOut; }),
        webSocket.future.then<_InitialResult>((WebSocket webSocket) { return _InitialResult.connected; }),
      ]);

      switch (initialResult) {
        case _InitialResult.crashed:
          int exitCode = await process.exitCode;
          String message = _getErrorMessage(_getExitCodeMessage(exitCode, 'before connecting to test harness'), testPath, shellPath);
          controller.sink.addError(new Exception(message));
          controller.sink.close();
          await controller.sink.done;
          break;
        case _InitialResult.timedOut:
          String message = _getErrorMessage('Test never connected to test harness.', testPath, shellPath);
          controller.sink.addError(new Exception(message));
          controller.sink.close();
          await controller.sink.done;
          break;
        case _InitialResult.connected:
          WebSocket testSocket = await webSocket.future;

          Completer<Null> harnessDone = new Completer<Null>();
          StreamSubscription<dynamic> harnessToTest = controller.stream.listen(
            (dynamic event) { testSocket.add(JSON.encode(event)); },
            onDone: () { harnessDone.complete(); },
          );

          Completer<Null> testDone = new Completer<Null>();
          StreamSubscription<dynamic> testToHarness = testSocket.listen(
            (dynamic event) {
              assert(event is String); // we shouldn't ever get binary messages
              controller.sink.add(JSON.decode(event));
            },
            onDone: () { testDone.complete(); },
          );

          _TestResult testResult = await Future.any(<Future<_TestResult>>[
            process.exitCode.then<_TestResult>((int exitCode) { return _TestResult.crashed; }),
            testDone.future.then<_TestResult>((Null _) { return _TestResult.completed; }),
            harnessDone.future.then<_TestResult>((Null _) { return _TestResult.harnessBailed; }),
          ]);

          harnessToTest.cancel();
          testToHarness.cancel();

          assert(!controllerSinkClosed);
          switch (testResult) {
            case _TestResult.crashed:
              int exitCode = await process.exitCode;
              subprocessActive = false;
              String message = _getErrorMessage(_getExitCodeMessage(exitCode, 'before test harness closed its WebSocket'), testPath, shellPath);
              controller.sink.addError(new Exception(message));
              controller.sink.close();
              await controller.sink.done;
              break;
            case _TestResult.completed:
              break;
            case _TestResult.harnessBailed:
              break;
          }
          break;
      }

      CoverageCollector.instance.collectCoverage(
        host: _kHost.address,
        port: observatoryPort,
        processToKill: process, // This kills the subprocess whether coverage is enabled or not.
      );
      subprocessActive = false;
    } catch (e, stack) {
      if (!controllerSinkClosed) {
        controller.sink.addError(e, stack);
      } else {
        printError('unhandled error during test:\n$e\n$stack');
      }
    } finally {
      for (_Finalizer finalizer in finalizers)
        await finalizer();
      if (!controllerSinkClosed) {
        controller.sink.close();
        await controller.sink.done;
      }
    }
    assert(!subprocessActive);
    assert(controllerSinkClosed);
    printTrace('ending test: $testPath');
  }

  String _generateTestMain({
    String testUrl,
    String encodedWebsocketUrl,
  }) {
    return '''
import 'dart:convert';
import '../base/io.dart';

import 'package:stream_channel/stream_channel.dart';
import 'package:test/src/runner/plugin/remote_platform_helpers.dart';
import 'package:test/src/runner/vm/catch_isolate_errors.dart';

import '$testUrl' as test;

void main() {
  String server = Uri.decodeComponent('$encodedWebsocketUrl');
  StreamChannel channel = serializeSuite(() {
    catchIsolateErrors();
    return test.main;
  });
  WebSocket.connect(server).then((WebSocket socket) {
    socket.map(JSON.decode).pipe(channel.sink);
    socket.addStream(channel.stream.map(JSON.encode));
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

    StringBuffer sb = new StringBuffer();
    sb.writeln('<fontconfig>');
    sb.writeln('  <dir>${cache.getCacheArtifacts().path}</dir>');
    sb.writeln('  <cachedir>/var/cache/fontconfig</cachedir>');
    sb.writeln('</fontconfig>');

    Directory fontsDir = fs.systemTempDirectory.createTempSync('flutter_fonts');
    _cachedFontConfig = fs.file('${fontsDir.path}/fonts.conf');
    _cachedFontConfig.createSync();
    _cachedFontConfig.writeAsStringSync(sb.toString());
    return _cachedFontConfig;
  }


  Future<Process> _startProcess(String executable, String testPath, { String packages, int observatoryPort }) {
    assert(executable != null); // Please provide the path to the shell in the SKY_SHELL environment variable.
    List<String> arguments = <String>[];
    if (observatoryPort != null) {
      arguments.add('--observatory-port=$observatoryPort');
    } else {
      arguments.add('--disable-observatory');
    }
    arguments.addAll(<String>[
      '--enable-dart-profiling',
      '--non-interactive',
      '--enable-checked-mode',
      '--packages=$packages',
      testPath,
    ]);
    printTrace('$executable ${arguments.join(' ')}');
    Map<String, String> environment = <String, String>{
      'FLUTTER_TEST': 'true',
      'FONTCONFIG_FILE': _fontConfigFile.path,
    };
    return processManager.start(executable, arguments, environment: environment);
  }

  void _pipeStandardStreamsToConsole(Process process) {
    for (Stream<List<int>> stream in
        <Stream<List<int>>>[process.stderr, process.stdout]) {
      stream.transform(UTF8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          if (line != null)
            printStatus('Shell: $line');
        });
    }
  }

  String _getErrorMessage(String what, String testPath, String shellPath) {
    return '$what\nTest: $testPath\nShell: $shellPath\n\n';
  }

  String _getExitCodeMessage(int exitCode, String when) {
    switch (exitCode) {
      case 0:
        return 'Shell subprocess ended cleanly $when. Did main() call exit()?';
      case -0x0f: // ProcessSignal.SIGTERM
        return 'Shell subprocess crashed with SIGTERM ($exitCode) $when.';
      case -0x0b: // ProcessSignal.SIGSEGV
        return 'Shell subprocess crashed with segmentation fault $when.';
      case -0x06: // ProcessSignal.SIGABRT
        return 'Shell subprocess crashed with SIGABRT ($exitCode) $when.';
      default:
        return 'Shell subprocess crashed with unexpected exit code $exitCode $when.';
    }
  }
}
