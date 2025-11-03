// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io; // flutter_ignore: dart_io_import

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/tester/flutter_tester.dart';
import 'package:flutter_tools/src/web/web_device.dart' show GoogleChromeDevice, WebServerDevice;
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../src/common.dart';
import 'test_utils.dart';

// Set this to true for debugging to get verbose logs written to stdout.
// The logs include the following:
//   <=stdout= data that the flutter tool running in --verbose mode wrote to stdout.
//   <=stderr= data that the flutter tool running in --verbose mode wrote to stderr.
//   =stdin=> data that the test sent to the flutter tool over stdin.
//   =vm=> data that was sent over the VM service channel to the app running on the test device.
//   <=vm= data that was sent from the app on the test device over the VM service channel.
//   Messages regarding what the test is doing.
// If this is false, then only critical errors and logs when things appear to be
// taking a long time are printed to the console.
const _printDebugOutputToStdOut = false;

final startTime = DateTime.now();

const defaultTimeout = Duration(seconds: 5);
const appStartTimeout = Duration(seconds: 120);
const quitTimeout = Duration(seconds: 10);

abstract final class FlutterTestDriver {
  FlutterTestDriver(this._projectFolder, {String? logPrefix})
    : _logPrefix = logPrefix != null ? '$logPrefix: ' : '';

  final Directory _projectFolder;
  final String _logPrefix;
  Process? _process;
  int? _processPid;
  final _stdout = StreamController<String>.broadcast();
  final _stderr = StreamController<String>.broadcast();
  final _allMessages = StreamController<String>.broadcast();
  final _errorBuffer = StringBuffer();
  String? _lastResponse;
  Uri? _vmServiceWsUri;
  Uri? _devToolsUri;
  Uri? _dtdUri;
  int? _attachPort;
  var _hasExited = false;

  VmService? _vmService;
  String get lastErrorInfo => _errorBuffer.toString();
  Stream<String> get stdout => _stdout.stream;
  Stream<String> get stderr => _stderr.stream;
  int? get vmServicePort => _vmServiceWsUri?.port;
  bool get hasExited => _hasExited;
  Uri? get vmServiceWsUri => _vmServiceWsUri;
  Uri? get devToolsUri => _devToolsUri;
  Uri? get dtdUri => _dtdUri;

  /// Completes with the full method name for the 'reloadSources' service once
  /// it's registered (e.g., `s0.reloadSources`).
  late final Future<String> reloadSourcesService;

  /// Completes with the full method name for the 'hotRestart' service once
  /// it's registered (e.g., `s0.hotRestart`).
  late final Future<String> hotRestartService;

  /// Completes with the full method name for the 'flutterVersion' service once
  /// it's registered (e.g., `s0.hotRestart`).
  late final Future<String> flutterVersionService;

  /// Completes with the full method name for the 'flutterMemoryInfo' service once
  /// it's registered (e.g., `s0.hotRestart`).
  late final Future<String> flutterMemoryInfoService;

  var lastTime = '';
  void debugPrint(String message, {String topic = ''}) {
    const maxLength = 2500;
    final truncatedMessage = message.length > maxLength
        ? '${message.substring(0, maxLength)}...'
        : message;
    final line = '${topic.padRight(10)} $truncatedMessage';
    _allMessages.add(line);
    final int timeInSeconds = DateTime.now().difference(startTime).inSeconds;
    var time = '${timeInSeconds.toString().padLeft(5)}s ';
    if (time == lastTime) {
      time = ' ' * time.length;
    } else {
      lastTime = time;
    }
    if (_printDebugOutputToStdOut) {
      // This is the one place in this file that can call print. It is gated by
      // _printDebugOutputToStdOut which should not be set to true in CI; it is
      // intended only for use in local debugging.
      // ignore: avoid_print
      print('$time$_logPrefix$line');
    } else {
      printOnFailure('$time$_logPrefix$line');
    }
  }

  @mustCallSuper
  Future<void> _setupProcess(
    List<String> arguments, {
    String? script,
    bool withDebugger = false,
    bool verbose = false,
  }) async {
    if (_process != null && !_hasExited) {
      throw StateError('Cannot start another process while the previous runs');
    }

    if (withDebugger) {
      arguments.add('--start-paused');
    }
    if (verbose || _printDebugOutputToStdOut) {
      arguments.add('--verbose');
    }
    if (script != null) {
      arguments.add(script);
    }
    debugPrint('Spawning flutter $arguments in ${_projectFolder.path}');

    const ProcessManager processManager = LocalProcessManager();
    _process = await processManager.start(
      <String>[flutterBin].followedBy(arguments).toList(),
      workingDirectory: _projectFolder.path,
      // The web environment variable has the same effect as `flutter config --enable-web`.
      environment: <String, String>{'FLUTTER_TEST': 'true', 'FLUTTER_WEB': 'true'},
    );

    // This class doesn't use the result of the future. It's made available
    // via a getter for external uses.
    unawaited(
      _process!.exitCode.then((int code) {
        debugPrint('Process exited ($code)');
        // The timing of this signal is important to the implementation of the
        // "quit" method, so only change how this is implemented by careful
        // testing of tests that use FlutterTestDriver.
        _hasExited = true;
      }),
    );
    transformToLines(_process!.stdout).listen(_stdout.add);
    transformToLines(_process!.stderr).listen(_stderr.add);

    // Capture stderr to a buffer so we can show it all if any requests fail.
    _stderr.stream.listen(_errorBuffer.writeln);

    // This is just debug printing to aid running/debugging tests locally.
    _stdout.stream.listen((String message) => debugPrint(message, topic: '<=stdout='));
    _stderr.stream.listen((String message) => debugPrint(message, topic: '<=stderr='));
  }

  /// Completes when process exits with the given exit code.
  ///
  /// If the process has never been started, complets with `null`.
  Future<int?> get done async => _process?.exitCode;

  Future<void> connectToVmService({bool pauseOnExceptions = false}) async {
    _vmService = await vmServiceConnectUri('$_vmServiceWsUri');
    _vmService!.onSend.listen((String s) => debugPrint(s, topic: '=vm=>'));
    _vmService!.onReceive.listen((String s) => debugPrint(s, topic: '<=vm='));

    final isolateStarted = Completer<void>();
    _vmService!.onIsolateEvent.listen((Event event) {
      if (event.kind == EventKind.kIsolateStart) {
        if (!isolateStarted.isCompleted) {
          isolateStarted.complete();
        }
      } else if (event.kind == EventKind.kIsolateExit && event.isolate?.id == _flutterIsolateId) {
        // Hot restarts cause all the isolates to exit, so we need to refresh
        // our idea of what the Flutter isolate ID is.
        _flutterIsolateId = null;
      }
    });

    reloadSourcesService = subscribeToServiceRegisteredEvent('reloadSources');
    hotRestartService = subscribeToServiceRegisteredEvent('hotRestart');
    flutterVersionService = subscribeToServiceRegisteredEvent('flutterVersion');
    flutterMemoryInfoService = subscribeToServiceRegisteredEvent('flutterMemoryInfo');

    await Future.wait(<Future<Success>>[
      _vmService!.streamListen(EventStreams.kIsolate),
      _vmService!.streamListen(EventStreams.kDebug),
      _vmService!.streamListen(EventStreams.kService),
    ]);

    if ((await _vmService!.getVM()).isolates?.isEmpty ?? true) {
      await isolateStarted.future;
    }
    await waitForPause();
    if (pauseOnExceptions) {
      await _vmService!.setIsolatePauseMode(
        await _getFlutterIsolateId(),
        exceptionPauseMode: ExceptionPauseMode.kUnhandled,
      );
    }
  }

  Future<Response> callServiceExtension(
    String extension, {
    Map<String, Object?> args = const <String, Object>{},
  }) async {
    final int port = _attachPort ?? vmServicePort!;
    final VmService vmService = await vmServiceConnectUri('ws://localhost:$port/ws');
    final Isolate isolate = await waitForExtension(vmService, extension);
    return vmService.callServiceExtension(extension, isolateId: isolate.id, args: args);
  }

  /// Quits the currently running process.
  @nonVirtual
  Future<void> quit() async {
    final int result = await _killGracefully();
    if (result != 0) {
      debugPrint('Expected process to terminate gracefully, got exit code $result.');
    }

    // The _hasExited signal could be on the microtask queue. Waiting for a
    // Future(...) queues an event similar to Timer.run(Duration.zero), which
    // guarantees the current queue has elapsed before moving on.
    await Future<void>(() {});
    if (!_hasExited) {
      throw StateError('Process did not exit');
    }
  }

  @nonVirtual
  Future<int> _killGracefully() async {
    if (_processPid == null) {
      return -1;
    }
    // If we try to kill the process while it's paused, we'll end up terminating
    // it forcefully and it won't terminate child processes, so we need to ensure
    // it's running before terminating.
    await resume()
        .timeout(defaultTimeout)
        .then(
          (Isolate? isolate) => isolate,
          onError: (Object e) {
            debugPrint('Ignoring failure to resume during shutdown');
            return null;
          },
        );

    debugPrint('Sending SIGTERM to $_processPid..');
    io.Process.killPid(_processPid!);
    return _process!.exitCode.timeout(quitTimeout, onTimeout: _killForcefully);
  }

  Future<int> _killForcefully() {
    debugPrint('Sending SIGKILL to $_processPid..');
    ProcessSignal.sigkill.send(_processPid!);
    return _process!.exitCode;
  }

  String? _flutterIsolateId;
  Future<String> _getFlutterIsolateId() async {
    // Currently these tests only have a single isolate. If this
    // ceases to be the case, this code will need changing.
    if (_flutterIsolateId == null) {
      final VM vm = await _vmService!.getVM();
      _flutterIsolateId = vm.isolates!.single.id;
    }
    return _flutterIsolateId!;
  }

  Future<Isolate> getFlutterIsolate() async {
    final Isolate isolate = await _vmService!.getIsolate(await _getFlutterIsolateId());
    return isolate;
  }

  /// Add a breakpoint and wait for it to trip the program execution.
  ///
  /// Only call this when you are absolutely sure that the program under test
  /// will hit the breakpoint _in the future_.
  ///
  /// In particular, do not call this if the program is currently racing to pass
  /// the line of code you are breaking on. Pretend that calling this will take
  /// an hour before setting the breakpoint. Would the code still eventually hit
  /// the breakpoint and stop?
  Future<void> breakAt(Uri uri, int line) async {
    final String isolateId = await _getFlutterIsolateId();
    final Future<Event> event = subscribeToPauseEvent(isolateId);
    await addBreakpoint(uri, line);
    await waitForPauseEvent(isolateId, event);
  }

  Future<void> addBreakpoint(Uri uri, int line) async {
    debugPrint('Sending breakpoint for: $uri:$line');
    await _vmService!.addBreakpointWithScriptUri(
      await _getFlutterIsolateId(),
      uri.toString(),
      line,
    );
  }

  Future<Event> subscribeToPauseEvent(String isolateId) =>
      subscribeToDebugEvent('Pause', isolateId);
  Future<Event> subscribeToResumeEvent(String isolateId) =>
      subscribeToDebugEvent('Resume', isolateId);

  Future<Isolate> waitForPauseEvent(String isolateId, Future<Event> event) =>
      waitForDebugEvent('Pause', isolateId, event);
  Future<Isolate> waitForResumeEvent(String isolateId, Future<Event> event) =>
      waitForDebugEvent('Resume', isolateId, event);

  Future<Isolate> waitForPause() async =>
      subscribeAndWaitForDebugEvent('Pause', await _getFlutterIsolateId());
  Future<Isolate> waitForResume() async =>
      subscribeAndWaitForDebugEvent('Resume', await _getFlutterIsolateId());

  Future<Isolate> subscribeAndWaitForDebugEvent(String kind, String isolateId) {
    final Future<Event> event = subscribeToDebugEvent(kind, isolateId);
    return waitForDebugEvent(kind, isolateId, event);
  }

  /// Subscribes to debug events containing [kind].
  ///
  /// Returns a future that completes when the [kind] event is received.
  ///
  /// This method should be called before the command that triggers
  /// the event to subscribe to the event in time, for example:
  ///
  /// ```dart
  /// var event = subscribeToDebugEvent('Pause', id); // Subscribe to 'pause' events.
  /// ...                                             // Code that pauses the app.
  /// await waitForDebugEvent('Pause', id, event);    // Isolate is paused now.
  /// ```
  Future<Event> subscribeToDebugEvent(String kind, String isolateId) {
    debugPrint('Start listening for $kind events');

    return _vmService!.onDebugEvent.where((Event event) {
      return event.isolate?.id == isolateId && (event.kind?.startsWith(kind) ?? false);
    }).first;
  }

  Future<String> subscribeToServiceRegisteredEvent(String service) {
    debugPrint("Start listening for service  '$service' to be registered");
    return _vmService!.onServiceEvent
        .where((Event event) {
          return event.service == service;
        })
        .first
        .then((e) => e.method!);
  }

  /// Wait for the [event] if needed.
  ///
  /// Return immediately if the isolate is already in the desired state.
  Future<Isolate> waitForDebugEvent(String kind, String isolateId, Future<Event> event) {
    return _timeoutWithMessages<Isolate>(() async {
      // But also check if the isolate was already at the state we need (only after we've
      // set up the subscription) to avoid races. If it already in the desired state, we
      // don't need to wait for the event.
      final VmService vmService = _vmService!;
      final Isolate isolate = await vmService.getIsolate(isolateId);
      if (isolate.pauseEvent?.kind?.startsWith(kind) ?? false) {
        debugPrint('Isolate was already at "$kind" (${isolate.pauseEvent!.kind}).');
        event.ignore();
      } else {
        debugPrint('Waiting for "$kind" event to arrive...');
        await event;
      }

      return vmService.getIsolate(isolateId);
    }, task: 'Waiting for isolate to $kind');
  }

  Future<Isolate?> resume({bool waitForNextPause = false}) => _resume(null, waitForNextPause);
  Future<Isolate?> stepOver({bool waitForNextPause = true}) =>
      _resume(StepOption.kOver, waitForNextPause);
  Future<Isolate?> stepOverAsync({bool waitForNextPause = true}) =>
      _resume(StepOption.kOverAsyncSuspension, waitForNextPause);
  Future<Isolate?> stepInto({bool waitForNextPause = true}) =>
      _resume(StepOption.kInto, waitForNextPause);
  Future<Isolate?> stepOut({bool waitForNextPause = true}) =>
      _resume(StepOption.kOut, waitForNextPause);

  Future<bool> isAtAsyncSuspension() async {
    final Isolate isolate = await getFlutterIsolate();
    return isolate.pauseEvent?.atAsyncSuspension ?? false;
  }

  Future<Isolate?> stepOverOrOverAsyncSuspension({bool waitForNextPause = true}) async {
    if (await isAtAsyncSuspension()) {
      return stepOverAsync(waitForNextPause: waitForNextPause);
    }
    return stepOver(waitForNextPause: waitForNextPause);
  }

  Future<Isolate?> _resume(String? step, bool waitForNextPause) async {
    final String isolateId = await _getFlutterIsolateId();

    final Future<Event> resume = subscribeToResumeEvent(isolateId);
    final Future<Event> pause = subscribeToPauseEvent(isolateId);

    await _timeoutWithMessages<Object?>(
      () async => _vmService!.resume(isolateId, step: step),
      task: 'Resuming isolate (step=$step)',
    );
    await waitForResumeEvent(isolateId, resume);
    return waitForNextPause ? waitForPauseEvent(isolateId, pause) : null;
  }

  Future<ObjRef> evaluateInFrame(String expression) async {
    return _timeoutWithMessages<ObjRef>(
      () async =>
          await _vmService!.evaluateInFrame(await _getFlutterIsolateId(), 0, expression) as ObjRef,
      task: 'Evaluating expression ($expression)',
    );
  }

  Future<ObjRef> evaluate(String targetId, String expression) async {
    return _timeoutWithMessages<ObjRef>(
      () async =>
          await _vmService!.evaluate(await _getFlutterIsolateId(), targetId, expression) as ObjRef,
      task: 'Evaluating expression ($expression for $targetId)',
    );
  }

  Future<Frame> getTopStackFrame() async {
    final String flutterIsolateId = await _getFlutterIsolateId();
    final Stack stack = await _vmService!.getStack(flutterIsolateId);
    final List<Frame>? frames = stack.frames;
    if (frames == null || frames.isEmpty) {
      throw Exception('Stack is empty');
    }
    return frames.first;
  }

  Future<SourcePosition?> getSourceLocation() async {
    final String flutterIsolateId = await _getFlutterIsolateId();
    final Frame frame = await getTopStackFrame();
    final script =
        await _vmService!.getObject(flutterIsolateId, frame.location!.script!.id!) as Script;
    return _lookupTokenPos(script.tokenPosTable!, frame.location!.tokenPos!);
  }

  SourcePosition? _lookupTokenPos(List<List<int>> table, int tokenPos) {
    for (final row in table) {
      final int lineNumber = row[0];
      var index = 1;

      for (index = 1; index < row.length - 1; index += 2) {
        if (row[index] == tokenPos) {
          return SourcePosition(lineNumber, row[index + 1]);
        }
      }
    }

    return null;
  }

  Future<Map<String, Object?>> _waitFor({
    String? event,
    int? id,
    Duration timeout = defaultTimeout,
    bool ignoreAppStopEvent = false,
  }) async {
    assert(event != null || id != null);
    assert(event == null || id == null);
    final interestingOccurrence = event != null ? '$event event' : 'response to request $id';
    final response = Completer<Map<String, Object?>>();
    StreamSubscription<String>? subscription;
    subscription = _stdout.stream.listen((String line) async {
      final Map<String, Object?>? json = parseFlutterResponse(line);
      _lastResponse = line;
      if (json == null) {
        return;
      }
      if ((event != null && json['event'] == event) || (id != null && json['id'] == id)) {
        await subscription?.cancel();
        debugPrint('OK ($interestingOccurrence)');
        response.complete(json);
      } else if (!ignoreAppStopEvent && json['event'] == 'app.stop') {
        await subscription?.cancel();
        final error = StringBuffer();
        error.write(
          'Received app.stop event while waiting for $interestingOccurrence\n\n$_errorBuffer',
        );
        final Object? jsonParams = json['params'];
        if (jsonParams case {'error': final Object errorObject}) {
          error.write('$errorObject\n\n');
        }
        if (jsonParams case {'trace': final Object trace}) {
          error.write('$trace\n\n');
        }
        response.completeError(Exception(error.toString()));
      }
    });

    return _timeoutWithMessages(
      () => response.future,
      timeout: timeout,
      task: 'Expecting $interestingOccurrence',
    ).whenComplete(subscription.cancel);
  }

  Future<T> _timeoutWithMessages<T>(
    Future<T> Function() callback, {
    required String task,
    Duration timeout = defaultTimeout,
  }) {
    if (_printDebugOutputToStdOut) {
      debugPrint('$task...');
      final longWarning = Timer(timeout, () => debugPrint('$task is taking longer than usual...'));
      return callback().whenComplete(longWarning.cancel);
    }

    // We're not showing all output to the screen, so let's capture the output
    // that we would have printed if we were, and output it if we take longer
    // than the timeout or if we get an error.
    final messages = StringBuffer('$task\n');
    final start = DateTime.now();
    var timeoutExpired = false;
    void logMessage(String logLine) {
      final int ms = DateTime.now().difference(start).inMilliseconds;
      final formattedLine = '[+ ${ms.toString().padLeft(5)}] $logLine';
      messages.writeln(formattedLine);
    }

    final StreamSubscription<String> subscription = _allMessages.stream.listen(logMessage);

    final longWarning = Timer(timeout, () {
      debugPrint(messages.toString());
      timeoutExpired = true;
      debugPrint('$task is taking longer than usual...');
    });
    final Future<T> future = callback().whenComplete(longWarning.cancel);

    return future
        .then(
          (T t) => t,
          onError: (Object error) {
            if (!timeoutExpired) {
              timeoutExpired = true;
              debugPrint(messages.toString());
            }
            throw error; // ignore: only_throw_errors
          },
        )
        .whenComplete(() => subscription.cancel());
  }
}

final class FlutterRunTestDriver extends FlutterTestDriver {
  FlutterRunTestDriver(super.projectFolder, {super.logPrefix, this.spawnDdsInstance = true});

  String? _currentRunningAppId;
  String? _currentRunningDeviceId;
  String? _currentRunningMode;

  String? get currentRunningDeviceId => _currentRunningDeviceId;
  String? get currentRunningMode => _currentRunningMode;

  Future<void> run({
    bool withDebugger = false,
    bool startPaused = false,
    bool pauseOnExceptions = false,
    String device = FlutterTesterDevices.kTesterDeviceId,
    bool expressionEvaluation = true,
    bool structuredErrors = false,
    bool noDevtools = false,
    bool verbose = false,
    bool wasm = false,
    int? ddsPort,
    String? script,
    List<String>? additionalCommandArgs,
  }) async {
    List<String> deviceArgs;
    switch (device) {
      case GoogleChromeDevice.kChromeDeviceId:
        deviceArgs = <String>[
          GoogleChromeDevice.kChromeDeviceId,
          '--web-run-headless',
          '--no-web-resources-cdn',
          if (!expressionEvaluation) '--no-web-enable-expression-evaluation',
        ];
      default:
        deviceArgs = <String>[device];
    }

    await _setupProcess(
      <String>[
        'run',
        if (device != GoogleChromeDevice.kChromeDeviceId) '--disable-service-auth-codes',
        '--machine',
        if (!spawnDdsInstance) '--no-dds',
        if (ddsPort != null) '--dds-port=$ddsPort',
        if (noDevtools) '--no-devtools',
        if (wasm) '--wasm',
        ...getLocalEngineArguments(),
        '-d',
        ...deviceArgs,
        if (structuredErrors) '--dart-define=flutter.inspector.structuredErrors=true',
        ...?additionalCommandArgs,
      ],
      withDebugger: withDebugger,
      withDevtools: !noDevtools,
      startPaused: startPaused,
      waitForDebugPort: device != WebServerDevice.kWebServerDeviceId && !wasm,
      waitForDtdAndDevTools:
          device != WebServerDevice.kWebServerDeviceId &&
          device != GoogleChromeDevice.kChromeDeviceId &&
          !noDevtools &&
          spawnDdsInstance,
      pauseOnExceptions: pauseOnExceptions,
      script: script,
      verbose: verbose,
    );
  }

  Future<void> attach(
    int port, {
    bool withDebugger = false,
    bool startPaused = false,
    bool pauseOnExceptions = false,
    List<String>? additionalCommandArgs,
  }) async {
    _attachPort = port;
    await _setupProcess(
      <String>[
        'attach',
        ...getLocalEngineArguments(),
        '--machine',
        if (!spawnDdsInstance) '--no-dds',
        '-d',
        'flutter-tester',
        '--debug-port',
        '$port',
        ...?additionalCommandArgs,
      ],
      withDebugger: withDebugger,
      startPaused: startPaused,
      pauseOnExceptions: pauseOnExceptions,
      attachPort: port,
    );
  }

  @override
  Future<void> _setupProcess(
    List<String> args, {
    String? script,
    bool withDebugger = false,
    bool withDevtools = false,
    bool startPaused = false,
    bool pauseOnExceptions = false,
    bool waitForDebugPort = false,
    bool waitForDtdAndDevTools = true,
    bool verbose = false,
    int? attachPort,
  }) async {
    assert(!startPaused || withDebugger);
    await super._setupProcess(args, script: script, withDebugger: withDebugger, verbose: verbose);

    final prematureExitGuard = Completer<void>();

    // If the process exits before all of the `await`s below are done, then it
    // exited prematurely. This causes the currently suspended `await` to
    // deadlock until the test times out. Instead, this causes the test to fail
    // fast.
    unawaited(
      _process?.exitCode.then((_) {
        if (!prematureExitGuard.isCompleted) {
          prematureExitGuard.completeError(
            Exception('Process exited prematurely: ${args.join(' ')}: $_errorBuffer'),
          );
        }
      }),
    );

    unawaited(() async {
      try {
        // Stash the PID so that we can terminate the VM more reliably than using
        // _process.kill() (`flutter` is a shell script so _process itself is a
        // shell, not the flutter tool's Dart process).
        final Map<String, Object?> connected = await _waitFor(event: 'daemon.connected');
        _processPid = (connected['params'] as Map<String, Object?>?)?['pid'] as int?;

        // Set this up now, but we don't wait it yet. We want to make sure we don't
        // miss it while waiting for debugPort below.
        final Future<Map<String, Object?>> start = _waitFor(
          event: 'app.start',
          timeout: appStartTimeout,
        );
        final Future<Map<String, Object?>> started = _waitFor(
          event: 'app.started',
          timeout: appStartTimeout,
        );
        final Future<void> devTools =
            _waitFor(
              event: 'app.devTools',
              timeout: appStartTimeout,
              ignoreAppStopEvent: true,
            ).then((event) async {
              _devToolsUri = Uri.parse(
                (event['params']! as Map<String, Object?>)['uri']! as String,
              );
            });
        final Future<void> dtd =
            _waitFor(event: 'app.dtd', timeout: appStartTimeout, ignoreAppStopEvent: true).then((
              event,
            ) {
              _dtdUri = Uri.parse((event['params']! as Map<String, Object?>)['uri']! as String);
            });

        late final Map<String, Object?> debugPort;
        if (waitForDebugPort || withDebugger || attachPort != null) {
          debugPort = await _waitFor(event: 'app.debugPort', timeout: appStartTimeout);
        }
        if (withDebugger && waitForDtdAndDevTools) {
          await Future.wait([devTools, dtd]);
        }
        if (withDebugger || attachPort != null) {
          final wsUriString = (debugPort['params']! as Map<String, Object?>)['wsUri']! as String;
          _vmServiceWsUri = Uri.parse(wsUriString);
          if (withDebugger) {
            await connectToVmService(pauseOnExceptions: pauseOnExceptions);
            if (!startPaused) {
              await started;
              await resume();
            }
          }
        }

        // In order to call service extensions from test runners started with
        // attach, we need to store the port that the test runner was attached
        // to.
        if (_vmServiceWsUri == null && attachPort != null) {
          _attachPort = attachPort;
        }

        // Now await the start/started events; if it had already happened the future will
        // have already completed.
        final startParams = (await start)['params'] as Map<String, Object?>?;
        final startedParams = (await started)['params'] as Map<String, Object?>?;
        _currentRunningAppId = startedParams?['appId'] as String?;
        _currentRunningDeviceId = startParams?['deviceId'] as String?;
        _currentRunningMode = startParams?['mode'] as String?;
        prematureExitGuard.complete();
      } on Exception catch (error, stackTrace) {
        prematureExitGuard.completeError(Exception(error.toString()), stackTrace);
      }
    }());

    return prematureExitGuard.future;
  }

  Future<void> hotRestart({bool pause = false, bool debounce = false}) =>
      _restart(fullRestart: true, pause: pause);
  Future<void> hotReload({bool debounce = false, int? debounceDurationOverrideMs}) =>
      _restart(debounce: debounce, debounceDurationOverrideMs: debounceDurationOverrideMs);

  Future<void> scheduleFrame() async {
    if (_currentRunningAppId == null) {
      throw Exception('App has not started yet');
    }
    await _sendRequest('app.callServiceExtension', <String, Object?>{
      'appId': _currentRunningAppId,
      'methodName': 'ext.ui.window.scheduleFrame',
    });
  }

  Future<void> _restart({
    bool fullRestart = false,
    bool pause = false,
    bool debounce = false,
    int? debounceDurationOverrideMs,
  }) async {
    if (_currentRunningAppId == null) {
      throw Exception('App has not started yet');
    }

    debugPrint(
      'Performing ${pause ? "paused " : ""}${fullRestart ? "hot restart" : "hot reload"}...',
    );
    final hotReloadResponse =
        await _sendRequest('app.restart', <String, Object?>{
              'appId': _currentRunningAppId,
              'fullRestart': fullRestart,
              'pause': pause,
              'debounce': debounce,
              'debounceDurationOverrideMs': debounceDurationOverrideMs,
            })
            as Map<String, Object?>?;
    debugPrint('${fullRestart ? "Hot restart" : "Hot reload"} complete.');

    if (hotReloadResponse == null || hotReloadResponse['code'] != 0) {
      _throwErrorResponse('Hot ${fullRestart ? 'restart' : 'reload'} request failed');
    }
  }

  Future<int> detach() async {
    final Process? process = _process;
    if (process == null) {
      return 0;
    }
    final VmService? vmService = _vmService;
    if (vmService != null) {
      debugPrint('Closing VM service...');
      await vmService.dispose();
    }
    if (_currentRunningAppId != null) {
      debugPrint('Detaching from app...');
      await Future.any<void>(<Future<void>>[
        process.exitCode,
        _sendRequest('app.detach', <String, Object?>{'appId': _currentRunningAppId}),
      ]).timeout(
        quitTimeout,
        onTimeout: () {
          debugPrint('app.detach did not return within $quitTimeout');
        },
      );
      _currentRunningAppId = null;
    }
    debugPrint('Waiting for process to end...');
    return process.exitCode.timeout(quitTimeout, onTimeout: _killGracefully);
  }

  Future<int> stop() async {
    final VmService? vmService = _vmService;
    if (vmService != null) {
      debugPrint('Closing VM service...');
      await vmService.dispose();
    }
    final Process? process = _process;
    if (_currentRunningAppId != null) {
      debugPrint('Stopping application...');
      await Future.any<void>(<Future<void>>[
        process!.exitCode,
        _sendRequest('app.stop', <String, Object?>{'appId': _currentRunningAppId}),
      ]).timeout(
        quitTimeout,
        onTimeout: () {
          debugPrint('app.stop did not return within $quitTimeout');
        },
      );
      _currentRunningAppId = null;
    }
    if (process != null) {
      debugPrint('Waiting for process to end...');
      return process.exitCode.timeout(quitTimeout, onTimeout: _killGracefully);
    }
    return 0;
  }

  var id = 1;
  Future<Object?> _sendRequest(String method, Object? params) async {
    final int requestId = id++;
    final request = <String, Object?>{'id': requestId, 'method': method, 'params': params};
    final String jsonEncoded = json.encode(<Map<String, Object?>>[request]);
    debugPrint(jsonEncoded, topic: '=stdin=>');

    // Set up the response future before we send the request to avoid any
    // races. If the method we're calling is app.stop then we tell _waitFor not
    // to throw if it sees an app.stop event before the response to this request.
    final Future<Map<String, Object?>> responseFuture = _waitFor(
      id: requestId,
      ignoreAppStopEvent: method == 'app.stop' || method == 'app.detach',
    );
    _process?.stdin.writeln(jsonEncoded);
    final Map<String, Object?> response = await responseFuture;

    if (response['error'] != null || response['result'] == null) {
      _throwErrorResponse('Unexpected error response');
    }

    return response['result'];
  }

  void _throwErrorResponse(String message) {
    throw Exception('$message\n\n$_lastResponse\n\n$_errorBuffer'.trim());
  }

  final bool spawnDdsInstance;
}

final class FlutterTestTestDriver extends FlutterTestDriver {
  FlutterTestTestDriver(super.projectFolder, {super.logPrefix});

  Future<void> test({
    String testFile = 'test/test.dart',
    String? deviceId,
    bool withDebugger = false,
    bool pauseOnExceptions = false,
    bool coverage = false,
    Future<void> Function()? beforeStart,
  }) async {
    await _setupProcess(
      <String>[
        'test',
        ...getLocalEngineArguments(),
        '--disable-service-auth-codes',
        '--machine',
        if (coverage) '--coverage',
        if (deviceId != null) ...<String>['-d', deviceId],
      ],
      script: testFile,
      withDebugger: withDebugger,
      pauseOnExceptions: pauseOnExceptions,
      beforeStart: beforeStart,
    );
  }

  @override
  Future<void> _setupProcess(
    List<String> args, {
    String? script,
    bool withDebugger = false,
    bool pauseOnExceptions = false,
    bool verbose = false,
    Future<void> Function()? beforeStart,
  }) async {
    await super._setupProcess(args, script: script, withDebugger: withDebugger, verbose: verbose);

    // Stash the PID so that we can terminate the VM more reliably than using
    // _proc.kill() (because _proc is a shell, because `flutter` is a shell
    // script).
    final Map<String, Object?>? version = await _waitForJson();
    _processPid = version?['pid'] as int?;

    if (withDebugger) {
      final startedProcessParams =
          (await _waitFor(event: 'test.startedProcess', timeout: appStartTimeout))['params']!
              as Map<String, Object?>;
      final vmServiceHttpString = startedProcessParams['vmServiceUri']! as String;
      _vmServiceWsUri = Uri.parse(vmServiceHttpString).replace(scheme: 'ws', path: '/ws');
      await connectToVmService(pauseOnExceptions: pauseOnExceptions);
      // Allow us to run code before we start, eg. to set up breakpoints.
      if (beforeStart != null) {
        await beforeStart();
      }
      await resume();
    }
  }

  Future<Map<String, Object?>?> _waitForJson({Duration timeout = defaultTimeout}) async {
    return _timeoutWithMessages<Map<String, Object?>?>(
      () => _stdout.stream
          .map<Map<String, Object?>?>(_parseJsonResponse)
          .firstWhere((Map<String, Object?>? output) => output != null),
      timeout: timeout,
      task: 'Waiting for JSON',
    );
  }

  Map<String, Object?>? _parseJsonResponse(String line) {
    try {
      return castStringKeyedMap(json.decode(line));
    } on Exception {
      // Not valid JSON, so likely some other output.
      return null;
    }
  }

  Future<void> waitForCompletion() async {
    final done = Completer<bool>();
    // Waiting for `{"success":true,"type":"done",...}` line indicating
    // end of test run.
    final StreamSubscription<String> subscription = _stdout.stream.listen((String line) async {
      final Map<String, Object?>? json = _parseJsonResponse(line);
      if (json != null && json['type'] != null && json['success'] != null) {
        done.complete(json['type'] == 'done' && json['success'] == true);
      }
    });

    await resume();

    final timeoutFuture = Future<void>.delayed(defaultTimeout);
    await Future.any<void>(<Future<void>>[done.future, timeoutFuture]);
    await subscription.cancel();
    if (!done.isCompleted) {
      await quit();
    }
  }
}

Stream<String> transformToLines(Stream<List<int>> byteStream) {
  return byteStream.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
}

Map<String, Object?>? parseFlutterResponse(String line) {
  if (line.startsWith('[') && line.endsWith(']') && line.length > 2) {
    try {
      final Map<String, Object?>? response = castStringKeyedMap(
        (json.decode(line) as List<Object?>)[0],
      );
      return response;
    } on FormatException {
      // Not valid JSON, so likely some other output that was surrounded by [brackets]
      return null;
    }
  }
  return null;
}

class SourcePosition {
  SourcePosition(this.line, this.column);

  final int line;
  final int column;
}

Future<Isolate> waitForExtension(VmService vmService, String extension) async {
  final completer = Completer<void>();
  try {
    await vmService.streamListen(EventStreams.kExtension);
  } on RPCError {
    // Do nothing, already subscribed.
  }
  vmService.onExtensionEvent.listen((Event event) {
    if (event.json?['extensionKind'] == 'Flutter.FrameworkInitialization') {
      completer.complete();
    }
  });
  final IsolateRef isolateRef = (await vmService.getVM()).isolates!.first;
  final Isolate isolate = await vmService.getIsolate(isolateRef.id!);
  if (isolate.extensionRPCs!.contains(extension)) {
    return isolate;
  }
  await completer.future;
  return isolate;
}
