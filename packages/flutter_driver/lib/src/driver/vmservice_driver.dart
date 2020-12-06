// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart' as f;
import 'package:fuchsia_remote_debug_protocol/fuchsia_remote_debug_protocol.dart' as fuchsia;
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:vm_service_client/vm_service_client.dart';
import 'package:webdriver/async_io.dart' as async_io;
import 'package:web_socket_channel/io.dart';

import '../../flutter_driver.dart';
import '../common/error.dart';
import '../common/frame_sync.dart';
import '../common/fuchsia_compat.dart';
import '../common/health.dart';
import '../common/message.dart';
import 'common.dart';
import 'driver.dart';
import 'timeline.dart';

/// An implementation of the Flutter Driver over the vmservice protocol.
class VMServiceFlutterDriver extends FlutterDriver {
  /// Creates a driver that uses a connection provided by the given
  /// [serviceClient], [_peer] and [appIsolate].
  VMServiceFlutterDriver.connectedTo(
      this._serviceClient,
      this._peer,
      this._appIsolate, {
        bool printCommunication = false,
        bool logCommunicationToFile = true,
      }) : _printCommunication = printCommunication,
        _logCommunicationToFile = logCommunicationToFile,
        _driverId = _nextDriverId++;

  /// Connects to a Flutter application.
  ///
  /// See [FlutterDriver.connect] for more documentation.
  static Future<FlutterDriver> connect({
    String dartVmServiceUrl,
    bool printCommunication = false,
    bool logCommunicationToFile = true,
    int isolateNumber,
    Pattern fuchsiaModuleTarget,
    Map<String, dynamic> headers,
  }) async {
    // If running on a Fuchsia device, connect to the first isolate whose name
    // matches FUCHSIA_MODULE_TARGET.
    //
    // If the user has already supplied an isolate number/URL to the Dart VM
    // service, then this won't be run as it is unnecessary.
    if (Platform.isFuchsia && isolateNumber == null) {
      // TODO(awdavies): Use something other than print. On fuchsia
      // `stderr`/`stdout` appear to have issues working correctly.
      driverLog = (String source, String message) {
        print('$source: $message');
      };
      fuchsiaModuleTarget ??= Platform.environment['FUCHSIA_MODULE_TARGET'];
      if (fuchsiaModuleTarget == null) {
        throw DriverError(
            'No Fuchsia module target has been specified.\n'
                'Please make sure to specify the FUCHSIA_MODULE_TARGET '
                'environment variable.'
        );
      }
      final fuchsia.FuchsiaRemoteConnection fuchsiaConnection =
      await FuchsiaCompat.connect();
      final List<fuchsia.IsolateRef> refs =
      await fuchsiaConnection.getMainIsolatesByPattern(fuchsiaModuleTarget);
      final fuchsia.IsolateRef ref = refs.first;
      isolateNumber = ref.number;
      dartVmServiceUrl = ref.dartVm.uri.toString();
      await fuchsiaConnection.stop();
      FuchsiaCompat.cleanup();
    }

    dartVmServiceUrl ??= Platform.environment['VM_SERVICE_URL'];

    if (dartVmServiceUrl == null) {
      throw DriverError(
          'Could not determine URL to connect to application.\n'
              'Either the VM_SERVICE_URL environment variable should be set, or an explicit '
              'URL should be provided to the FlutterDriver.connect() method.'
      );
    }

    // Connect to Dart VM services
    _log('Connecting to Flutter application at $dartVmServiceUrl');
    final VMServiceClientConnection connection =
    await vmServiceConnectFunction(dartVmServiceUrl, headers: headers);
    final VMServiceClient client = connection.client;
    final VM vm = await client.getVM();
    final VMIsolateRef isolateRef = isolateNumber ==
        null ? vm.isolates.first :
    vm.isolates.firstWhere(
            (VMIsolateRef isolate) => isolate.number == isolateNumber);
    _log('Isolate found with number: ${isolateRef.number}');

    VMIsolate isolate = await isolateRef.loadRunnable();

    // TODO(yjbanov): vm_service_client does not support "None" pause event yet.
    // It is currently reported as null, but we cannot rely on it because
    // eventually the event will be reported as a non-null object. For now,
    // list all the events we know about. Later we'll check for "None" event
    // explicitly.
    //
    // See: https://github.com/dart-lang/vm_service_client/issues/4
    if (isolate.pauseEvent is! VMPauseStartEvent &&
        isolate.pauseEvent is! VMPauseExitEvent &&
        isolate.pauseEvent is! VMPauseBreakpointEvent &&
        isolate.pauseEvent is! VMPauseExceptionEvent &&
        isolate.pauseEvent is! VMPauseInterruptedEvent &&
        isolate.pauseEvent is! VMResumeEvent) {
      isolate = await isolateRef.loadRunnable();
    }

    final VMServiceFlutterDriver driver = VMServiceFlutterDriver.connectedTo(
      client, connection.peer, isolate,
      printCommunication: printCommunication,
      logCommunicationToFile: logCommunicationToFile,
    );

    driver._dartVmReconnectUrl = dartVmServiceUrl;

    // Attempts to resume the isolate, but does not crash if it fails because
    // the isolate is already resumed. There could be a race with other tools,
    // such as a debugger, any of which could have resumed the isolate.
    Future<dynamic> resumeLeniently() {
      _log('Attempting to resume isolate');
      return isolate.resume().catchError((dynamic e) {
        const int vmMustBePausedCode = 101;
        if (e is rpc.RpcException && e.code == vmMustBePausedCode) {
          // No biggie; something else must have resumed the isolate
          _log(
              'Attempted to resume an already resumed isolate. This may happen '
                  'when we lose a race with another tool (usually a debugger) that '
                  'is connected to the same isolate.'
          );
        } else {
          // Failed to resume due to another reason. Fail hard.
          throw e;
        }
      });
    }

    /// Waits for a signal from the VM service that the extension is registered.
    ///
    /// Looks at the list of loaded extensions for the current [isolateRef], as
    /// well as the stream of added extensions.
    Future<void> waitForServiceExtension() async {
      final Future<void> extensionAlreadyAdded = isolateRef
        .loadRunnable()
        .then((VMIsolate isolate) async {
          if (isolate.extensionRpcs.contains(_flutterExtensionMethodName)) {
            return;
          }
          // Never complete. Rely on the stream listener to find the service
          // extension instead.
          return Completer<void>().future;
        });

      final Completer<void> extensionAdded = Completer<void>();
      StreamSubscription<String> isolateAddedSubscription;
      isolateAddedSubscription = isolate.onExtensionAdded.listen(
        (String extensionName) {
          if (extensionName == _flutterExtensionMethodName) {
            extensionAdded.complete();
            isolateAddedSubscription.cancel();
          }
        },
        onError: extensionAdded.completeError,
        cancelOnError: true);

      await Future.any(<Future<void>>[
        extensionAlreadyAdded,
        extensionAdded.future,
      ]);
    }

    /// Tells the Dart VM Service to notify us about "Isolate" events.
    ///
    /// This is a workaround for an issue in package:vm_service_client, which
    /// subscribes to the "Isolate" stream lazily upon subscription, which
    /// results in lost events.
    ///
    /// Details: https://github.com/dart-lang/vm_service_client/issues/17
    Future<void> enableIsolateStreams() async {
      await connection.peer.sendRequest('streamListen', <String, String>{
        'streamId': 'Isolate',
      });
    }

    // Attempt to resume isolate if it was paused
    if (isolate.pauseEvent is VMPauseStartEvent) {
      _log('Isolate is paused at start.');

      await resumeLeniently();
    } else if (isolate.pauseEvent is VMPauseExitEvent ||
        isolate.pauseEvent is VMPauseBreakpointEvent ||
        isolate.pauseEvent is VMPauseExceptionEvent ||
        isolate.pauseEvent is VMPauseInterruptedEvent) {
      // If the isolate is paused for any other reason, assume the extension is
      // already there.
      _log('Isolate is paused mid-flight.');
      await resumeLeniently();
    } else if (isolate.pauseEvent is VMResumeEvent) {
      _log('Isolate is not paused. Assuming application is ready.');
    } else {
      _log(
          'Unknown pause event type ${isolate.pauseEvent.runtimeType}. '
              'Assuming application is ready.'
      );
    }

    await enableIsolateStreams();

    // We will never receive the extension event if the user does not register
    // it. If that happens, show a message but continue waiting.
    await _warnIfSlow<void>(
      future: waitForServiceExtension(),
      timeout: kUnusuallyLongTimeout,
      message: 'Flutter Driver extension is taking a long time to become available. '
          'Ensure your test app (often "lib/main.dart") imports '
          '"package:flutter_driver/driver_extension.dart" and '
          'calls enableFlutterDriverExtension() as the first call in main().',
    );

    final Health health = await driver.checkHealth();
    if (health.status != HealthStatus.ok) {
      await client.close();
      throw DriverError('Flutter application health check failed.');
    }

    _log('Connected to Flutter application.');
    return driver;
  }

  static int _nextDriverId = 0;

  static const String _flutterExtensionMethodName = 'ext.flutter.driver';
  static const String _setVMTimelineFlagsMethodName = 'setVMTimelineFlags';
  static const String _getVMTimelineMethodName = 'getVMTimeline';
  static const String _clearVMTimelineMethodName = 'clearVMTimeline';
  static const String _collectAllGarbageMethodName = '_collectAllGarbage';

  // The additional blank line in the beginning is for _log.
  static const String _kDebugWarning = '''

┏╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┓
┇ ⚠    THIS BENCHMARK IS BEING RUN IN DEBUG MODE     ⚠  ┇
┡╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┦
│                                                       │
│  Numbers obtained from a benchmark while asserts are  │
│  enabled will not accurately reflect the performance  │
│  that will be experienced by end users using release  ╎
│  builds. Benchmarks should be run using this command  ┆
│  line:  flutter drive --profile test_perf.dart        ┊
│                                                       ┊
└─────────────────────────────────────────────────╌┄┈  🐢
''';
  /// The unique ID of this driver instance.
  final int _driverId;

  /// Client connected to the Dart VM running the Flutter application.
  ///
  /// You can use [VMServiceClient] to check VM version, flags and get
  /// notified when a new isolate has been instantiated. That could be
  /// useful if your application spawns multiple isolates that you
  /// would like to instrument.
  final VMServiceClient _serviceClient;

  /// JSON-RPC client useful for sending raw JSON requests.
  rpc.Peer _peer;

  String _dartVmReconnectUrl;

  Future<void> _restorePeerConnectionIfNeeded() async {
    if (!_peer.isClosed || _dartVmReconnectUrl == null) {
      return;
    }

    _log(
        'Peer connection is closed! Trying to restore the connection...'
    );

    final String webSocketUrl = _getWebSocketUrl(_dartVmReconnectUrl);
    final WebSocket ws = await WebSocket.connect(webSocketUrl);
    ws.done.whenComplete(() => _checkCloseCode(ws));
    _peer = rpc.Peer(
      IOWebSocketChannel(ws).cast(),
      onUnhandledError: _unhandledJsonRpcError,
    )..listen();
  }

  @override
  VMIsolate get appIsolate => _appIsolate;

  @override
  VMServiceClient get serviceClient => _serviceClient;

  @override
  async_io.WebDriver get webDriver => throw UnsupportedError('VMServiceFlutterDriver does not support webDriver');

  /// The main isolate hosting the Flutter application.
  ///
  /// If you used the [registerExtension] API to instrument your application,
  /// you can use this [VMIsolate] to call these extension methods via
  /// [invokeExtension].
  final VMIsolate _appIsolate;

  /// Whether to print communication between host and app to `stdout`.
  final bool _printCommunication;

  /// Whether to log communication between host and app to `flutter_driver_commands.log`.
  final bool _logCommunicationToFile;

  @override
  Future<void> enableAccessibility() async {
    throw UnsupportedError('VMServiceFlutterDriver does not support enableAccessibility');
  }

  @override
  Future<Map<String, dynamic>> sendCommand(Command command) async {
    Map<String, dynamic> response;
    try {
      final Map<String, String> serialized = command.serialize();
      _logCommunication('>>> $serialized');
      final Future<Map<String, dynamic>> future = _appIsolate.invokeExtension(
        _flutterExtensionMethodName,
        serialized,
      ).then<Map<String, dynamic>>((Object value) => value as Map<String, dynamic>);
      response = await _warnIfSlow<Map<String, dynamic>>(
        future: future,
        timeout: command.timeout ?? kUnusuallyLongTimeout,
        message: '${command.kind} message is taking a long time to complete...',
      );
      _logCommunication('<<< $response');
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to fulfill ${command.runtimeType} due to remote error',
        error,
        stackTrace,
      );
    }
    if (response['isError'] as bool)
      throw DriverError('Error in Flutter application: ${response['response']}');
    return response['response'] as Map<String, dynamic>;
  }

  void _logCommunication(String message) {
    if (_printCommunication)
      _log(message);
    if (_logCommunicationToFile) {
      final f.File file = fs.file(p.join(testOutputsDirectory, 'flutter_driver_commands_$_driverId.log'));
      file.createSync(recursive: true); // no-op if file exists
      file.writeAsStringSync('${DateTime.now()} $message\n', mode: f.FileMode.append, flush: true);
    }
  }

  @override
  Future<List<int>> screenshot() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final Map<String, dynamic> result = await _peer.sendRequest('_flutter.screenshot') as Map<String, dynamic>;
    return base64.decode(result['screenshot'] as String);
  }

  @override
  Future<List<Map<String, dynamic>>> getVmFlags() async {
    await _restorePeerConnectionIfNeeded();
    final Map<String, dynamic> result = await _peer.sendRequest('getFlagList') as Map<String, dynamic>;
    return result != null
        ? (result['flags'] as List<dynamic>).cast<Map<String,dynamic>>()
        : const <Map<String, dynamic>>[];
  }

  Future<Map<String, Object>> _getVMTimelineMicros() async {
    return await _peer.sendRequest('getVMTimelineMicros') as Map<String, dynamic>;
  }

  @override
  Future<void> startTracing({
    List<TimelineStream> streams = const <TimelineStream>[TimelineStream.all],
    Duration timeout = kUnusuallyLongTimeout,
  }) async {
    assert(streams != null && streams.isNotEmpty);
    assert(timeout != null);
    try {
      await _warnIfSlow<void>(
        future: _peer.sendRequest(_setVMTimelineFlagsMethodName, <String, String>{
          'recordedStreams': _timelineStreamsToString(streams),
        }),
        timeout: timeout,
        message: 'VM is taking an unusually long time to respond to being told to start tracing...',
      );
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to start tracing due to remote error',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<Timeline> stopTracingAndDownloadTimeline({
    Duration timeout = kUnusuallyLongTimeout,
    int startTime,
    int endTime,
  }) async {
    assert(timeout != null);
    assert((startTime == null && endTime == null) ||
           (startTime != null && endTime != null));

    try {
      await _warnIfSlow<void>(
        future: _peer.sendRequest(_setVMTimelineFlagsMethodName, <String, String>{'recordedStreams': '[]'}),
        timeout: timeout,
        message: 'VM is taking an unusually long time to respond to being told to stop tracing...',
      );
      if (startTime == null) {
        return Timeline.fromJson(await _peer.sendRequest(_getVMTimelineMethodName) as Map<String, dynamic>);
      }
      const int kSecondInMicros = 1000000;
      int currentStart = startTime;
      int currentEnd = startTime + kSecondInMicros; // 1 second of timeline
      final List<Map<String, Object>> chunks = <Map<String, Object>>[];
      do {
        final Map<String, Object> chunk = await _peer.sendRequest(_getVMTimelineMethodName, <String, Object>{
          'timeOriginMicros': currentStart,
          // The range is inclusive, avoid double counting on the chance something
          // aligns on the boundary.
          'timeExtentMicros': kSecondInMicros - 1,
        }) as Map<String, dynamic>;
        chunks.add(chunk);
        currentStart = currentEnd;
        currentEnd += kSecondInMicros;
      } while (currentStart < endTime);
      return Timeline.fromJson(<String, Object>{
        'traceEvents': <Object> [
          for (Map<String, Object> chunk in chunks)
            ...chunk['traceEvents'] as List<Object>,
        ],
      });
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to stop tracing due to remote error',
        error,
        stackTrace,
      );
    }
  }

  Future<bool> _isPrecompiledMode() async {
    final List<Map<String, dynamic>> flags = await getVmFlags();
    for(final Map<String, dynamic> flag in flags) {
      if (flag['name'] == 'precompiled_mode') {
        return flag['valueAsString'] == 'true';
      }
    }
    return false;
  }

  @override
  Future<Timeline> traceAction(
      Future<dynamic> action(), {
        List<TimelineStream> streams = const <TimelineStream>[TimelineStream.all],
        bool retainPriorEvents = false,
      }) async {
    if (retainPriorEvents) {
      await startTracing(streams: streams);
      await action();

      if (!(await _isPrecompiledMode())) {
        _log(_kDebugWarning);
      }

      return stopTracingAndDownloadTimeline();
    }

    await clearTimeline();

    final Map<String, Object> startTimestamp = await _getVMTimelineMicros();
    await startTracing(streams: streams);
    await action();
    final Map<String, Object> endTimestamp = await _getVMTimelineMicros();

    if (!(await _isPrecompiledMode())) {
      _log(_kDebugWarning);
    }

    return stopTracingAndDownloadTimeline(
      startTime: startTimestamp['timestamp'] as int,
      endTime: endTimestamp['timestamp'] as int,
    );
  }

  @override
  Future<void> clearTimeline({
    Duration timeout = kUnusuallyLongTimeout,
  }) async {
    assert(timeout != null);
    try {
      await _warnIfSlow<void>(
        future: _peer.sendRequest(_clearVMTimelineMethodName, <String, String>{}),
        timeout: timeout,
        message: 'VM is taking an unusually long time to respond to being told to clear its timeline buffer...',
      );
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to clear event timeline due to remote error',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<T> runUnsynchronized<T>(Future<T> action(), { Duration timeout }) async {
    await sendCommand(SetFrameSync(false, timeout: timeout));
    T result;
    try {
      result = await action();
    } finally {
      await sendCommand(SetFrameSync(true, timeout: timeout));
    }
    return result;
  }

  @override
  Future<void> forceGC() async {
    try {
      await _peer
          .sendRequest(_collectAllGarbageMethodName, <String, String>{
        'isolateId': 'isolates/${_appIsolate.numberAsString}',
      });
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to force a GC due to remote error',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> close() async {
    // Don't leak vm_service_client-specific objects, if any
    await _serviceClient.close();
    await _peer.close();
  }
}


/// The connection function used by [FlutterDriver.connect].
///
/// Overwrite this function if you require a custom method for connecting to
/// the VM service.
VMServiceConnectFunction vmServiceConnectFunction = _waitAndConnect;

/// Restores [vmServiceConnectFunction] to its default value.
void restoreVmServiceConnectFunction() {
  vmServiceConnectFunction = _waitAndConnect;
}

/// The JSON RPC 2 spec says that a notification from a client must not respond
/// to the client. It's possible the client sent a notification as a "ping", but
/// the service isn't set up yet to respond.
///
/// For example, if the client sends a notification message to the server for
/// 'streamNotify', but the server has not finished loading, it will throw an
/// exception. Since the message is a notification, the server follows the
/// specification and does not send a response back, but is left with an
/// unhandled exception. That exception is safe for us to ignore - the client
/// is signaling that it will try again later if it doesn't get what it wants
/// here by sending a notification.
// This may be ignoring too many exceptions. It would be best to rewrite
// the client code to not use notifications so that it gets error replies back
// and can decide what to do from there.
// TODO(dnfield): https://github.com/flutter/flutter/issues/31813
bool _ignoreRpcError(dynamic error) {
  if (error is rpc.RpcException) {
    final rpc.RpcException exception = error;
    return exception.data == null || exception.data['id'] == null;
  } else if (error is String && error.startsWith('JSON-RPC error -32601')) {
    return true;
  }
  return false;
}

void _unhandledJsonRpcError(dynamic error, dynamic stack) {
  if (_ignoreRpcError(error)) {
    return;
  }
  _log('Unhandled RPC error:\n$error\n$stack');
  // TODO(dnfield): https://github.com/flutter/flutter/issues/31813
  // assert(false);
}

String _getWebSocketUrl(String url) {
  Uri uri = Uri.parse(url);
  final List<String> pathSegments = <String>[
    // If there's an authentication code (default), we need to add it to our path.
    if (uri.pathSegments.isNotEmpty) uri.pathSegments.first,
    'ws',
  ];
  if (uri.scheme == 'http')
    uri = uri.replace(scheme: 'ws', pathSegments: pathSegments);
  return uri.toString();
}

void _checkCloseCode(WebSocket ws) {
  if (ws.closeCode != 1000 && ws.closeCode != null) {
    _log('$ws is closed with an unexpected code ${ws.closeCode}');
  }
}

/// Waits for a real Dart VM service to become available, then connects using
/// the [VMServiceClient].
Future<VMServiceClientConnection> _waitAndConnect(
    String url, {Map<String, dynamic> headers}) async {
  final String webSocketUrl = _getWebSocketUrl(url);
  int attempts = 0;
  while (true) {
    WebSocket ws1;
    WebSocket ws2;
    try {
      ws1 = await WebSocket.connect(webSocketUrl, headers: headers);
      ws2 = await WebSocket.connect(webSocketUrl, headers: headers);

      ws1.done.whenComplete(() => _checkCloseCode(ws1));
      ws2.done.whenComplete(() => _checkCloseCode(ws2));

      return VMServiceClientConnection(
        VMServiceClient(IOWebSocketChannel(ws1).cast()),
        rpc.Peer(
          IOWebSocketChannel(ws2).cast(),
          onUnhandledError: _unhandledJsonRpcError,
        )..listen(),
      );
    } catch (e) {
      await ws1?.close();
      await ws2?.close();
      if (attempts > 5)
        _log('It is taking an unusually long time to connect to the VM...');
      attempts += 1;
      await Future<void>.delayed(_kPauseBetweenReconnectAttempts);
    }
  }
}


/// The amount of time we wait prior to making the next attempt to connect to
/// the VM service.
const Duration _kPauseBetweenReconnectAttempts = Duration(seconds: 1);

// See `timeline_streams` in
// https://github.com/dart-lang/sdk/blob/master/runtime/vm/timeline.cc
String _timelineStreamsToString(List<TimelineStream> streams) {
  final String contents = streams.map<String>((TimelineStream stream) {
    switch (stream) {
      case TimelineStream.all: return 'all';
      case TimelineStream.api: return 'API';
      case TimelineStream.compiler: return 'Compiler';
      case TimelineStream.compilerVerbose: return 'CompilerVerbose';
      case TimelineStream.dart: return 'Dart';
      case TimelineStream.debugger: return 'Debugger';
      case TimelineStream.embedder: return 'Embedder';
      case TimelineStream.gc: return 'GC';
      case TimelineStream.isolate: return 'Isolate';
      case TimelineStream.vm: return 'VM';
      default:
        throw 'Unknown timeline stream $stream';
    }
  }).join(', ');
  return '[$contents]';
}

void _log(String message) {
  driverLog('VMServiceFlutterDriver', message);
}
Future<T> _warnIfSlow<T>({
  @required Future<T> future,
  @required Duration timeout,
  @required String message,
}) {
  assert(future != null);
  assert(timeout != null);
  assert(message != null);
  future
    .timeout(timeout, onTimeout: () {
      _log(message);
      return null;
    })
    // Don't duplicate errors if [future] completes with an error.
    .catchError((dynamic e) => null);

  return future;
}

/// Encapsulates connection information to an instance of a Flutter application.
@visibleForTesting
class VMServiceClientConnection {
  /// Creates an instance of this class given a [client] and a [peer].
  VMServiceClientConnection(this.client, this.peer);

  /// Use this for structured access to the VM service's public APIs.
  final VMServiceClient client;

  /// Use this to make arbitrary raw JSON-RPC calls.
  ///
  /// This object allows reaching into private VM service APIs. Use with
  /// caution.
  final rpc.Peer peer;
}

/// A function that connects to a Dart VM service
/// with [headers] given the [url].
typedef VMServiceConnectFunction =
  Future<VMServiceClientConnection> Function(
    String url, {Map<String, dynamic> headers});
