// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart' as f;
import 'package:fuchsia_remote_debug_protocol/fuchsia_remote_debug_protocol.dart' as fuchsia;
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:vm_service_client/vm_service_client.dart';
import 'package:web_socket_channel/io.dart';

import '../common/diagnostics_tree.dart';
import '../common/error.dart';
import '../common/find.dart';
import '../common/frame_sync.dart';
import '../common/fuchsia_compat.dart';
import '../common/geometry.dart';
import '../common/gesture.dart';
import '../common/health.dart';
import '../common/message.dart';
import '../common/render_tree.dart';
import '../common/request_data.dart';
import '../common/semantics.dart';
import '../common/text.dart';
import '../common/wait.dart';
import 'common.dart';
import 'timeline.dart';

/// Timeline stream identifier.
enum TimelineStream {
  /// A meta-identifier that instructs the Dart VM to record all streams.
  all,

  /// Marks events related to calls made via Dart's C API.
  api,

  /// Marks events from the Dart VM's JIT compiler.
  compiler,

  /// Marks events emitted using the `dart:developer` API.
  dart,

  /// Marks events from the Dart VM debugger.
  debugger,

  /// Marks events emitted using the `dart_tools_api.h` C API.
  embedder,

  /// Marks events from the garbage collector.
  gc,

  /// Marks events related to message passing between Dart isolates.
  isolate,

  /// Marks internal VM events.
  vm,
}

const List<TimelineStream> _defaultStreams = <TimelineStream>[TimelineStream.all];

/// How long to wait before showing a message saying that
/// things seem to be taking a long time.
@visibleForTesting
const Duration kUnusuallyLongTimeout = Duration(seconds: 5);

/// The amount of time we wait prior to making the next attempt to connect to
/// the VM service.
const Duration _kPauseBetweenReconnectAttempts = Duration(seconds: 1);

// See https://github.com/dart-lang/sdk/blob/master/runtime/vm/timeline.cc#L32
String _timelineStreamsToString(List<TimelineStream> streams) {
  final String contents = streams.map<String>((TimelineStream stream) {
    switch (stream) {
      case TimelineStream.all: return 'all';
      case TimelineStream.api: return 'API';
      case TimelineStream.compiler: return 'Compiler';
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

final Logger _log = Logger('FlutterDriver');

Future<T> _warnIfSlow<T>({
  @required Future<T> future,
  @required Duration timeout,
  @required String message,
}) {
  assert(future != null);
  assert(timeout != null);
  assert(message != null);
  return future..timeout(timeout, onTimeout: () { _log.warning(message); return null; });
}

/// A convenient accessor to frequently used finders.
///
/// Examples:
///
///     driver.tap(find.text('Save'));
///     driver.scroll(find.byValueKey(42));
const CommonFinders find = CommonFinders._();

/// Computes a value.
///
/// If computation is asynchronous, the function may return a [Future].
///
/// See also [FlutterDriver.waitFor].
typedef EvaluatorFunction = dynamic Function();

/// Drives a Flutter Application running in another process.
class FlutterDriver {
  /// Creates a driver that uses a connection provided by the given
  /// [serviceClient], [_peer] and [appIsolate].
  @visibleForTesting
  FlutterDriver.connectedTo(
    this.serviceClient,
    this._peer,
    this.appIsolate, {
    bool printCommunication = false,
    bool logCommunicationToFile = true,
  }) : _printCommunication = printCommunication,
       _logCommunicationToFile = logCommunicationToFile,
       _driverId = _nextDriverId++;

  static const String _flutterExtensionMethodName = 'ext.flutter.driver';
  static const String _setVMTimelineFlagsMethodName = 'setVMTimelineFlags';
  static const String _getVMTimelineMethodName = 'getVMTimeline';
  static const String _clearVMTimelineMethodName = 'clearVMTimeline';
  static const String _collectAllGarbageMethodName = '_collectAllGarbage';

  static int _nextDriverId = 0;

  // The additional blank line in the beginning is for _log.warning.
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

  /// Connects to a Flutter application.
  ///
  /// Resumes the application if it is currently paused (e.g. at a breakpoint).
  ///
  /// `dartVmServiceUrl` is the URL to Dart observatory (a.k.a. VM service). If
  /// not specified, the URL specified by the `VM_SERVICE_URL` environment
  /// variable is used. One or the other must be specified.
  ///
  /// `printCommunication` determines whether the command communication between
  /// the test and the app should be printed to stdout.
  ///
  /// `logCommunicationToFile` determines whether the command communication
  /// between the test and the app should be logged to `flutter_driver_commands.log`.
  ///
  /// `isolateNumber` determines the specific isolate to connect to.
  /// If this is left as `null`, will connect to the first isolate found
  /// running on `dartVmServiceUrl`.
  ///
  /// `fuchsiaModuleTarget` specifies the pattern for determining which mod to
  /// control. When running on a Fuchsia device, either this or the environment
  /// variable `FUCHSIA_MODULE_TARGET` must be set (the environment variable is
  /// treated as a substring pattern). This field will be ignored if
  /// `isolateNumber` is set, as this is already enough information to connect
  /// to an isolate.
  ///
  /// The return value is a future. This method never times out, though it may
  /// fail (completing with an error). A timeout can be applied by the caller
  /// using [Future.timeout] if necessary.
  static Future<FlutterDriver> connect({
    String dartVmServiceUrl,
    bool printCommunication = false,
    bool logCommunicationToFile = true,
    int isolateNumber,
    Pattern fuchsiaModuleTarget,
  }) async {
    // If running on a Fuchsia device, connect to the first isolate whose name
    // matches FUCHSIA_MODULE_TARGET.
    //
    // If the user has already supplied an isolate number/URL to the Dart VM
    // service, then this won't be run as it is unnecessary.
    if (Platform.isFuchsia && isolateNumber == null) {
      // TODO(awdavies): Use something other than print. On fuchsia
      // `stderr`/`stdout` appear to have issues working correctly.
      flutterDriverLog.listen(print);
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
    _log.info('Connecting to Flutter application at $dartVmServiceUrl');
    final VMServiceClientConnection connection =
        await vmServiceConnectFunction(dartVmServiceUrl);
    final VMServiceClient client = connection.client;
    final VM vm = await client.getVM();
    final VMIsolateRef isolateRef = isolateNumber ==
        null ? vm.isolates.first :
               vm.isolates.firstWhere(
                   (VMIsolateRef isolate) => isolate.number == isolateNumber);
    _log.trace('Isolate found with number: ${isolateRef.number}');

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

    final FlutterDriver driver = FlutterDriver.connectedTo(
      client, connection.peer, isolate,
      printCommunication: printCommunication,
      logCommunicationToFile: logCommunicationToFile,
    );

    driver._dartVmReconnectUrl = dartVmServiceUrl;

    // Attempts to resume the isolate, but does not crash if it fails because
    // the isolate is already resumed. There could be a race with other tools,
    // such as a debugger, any of which could have resumed the isolate.
    Future<dynamic> resumeLeniently() {
      _log.trace('Attempting to resume isolate');
      return isolate.resume().catchError((dynamic e) {
        const int vmMustBePausedCode = 101;
        if (e is rpc.RpcException && e.code == vmMustBePausedCode) {
          // No biggie; something else must have resumed the isolate
          _log.warning(
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
    /// Returns [_flutterExtensionMethodName]
    Future<String> waitForServiceExtension() {
      return isolate.onExtensionAdded.firstWhere((String extension) {
        return extension == _flutterExtensionMethodName;
      });
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
      _log.trace('Isolate is paused at start.');

      // If the isolate is paused at the start, e.g. via the --start-paused
      // option, then the VM service extension is not registered yet. Wait for
      // it to be registered.
      await enableIsolateStreams();
      final Future<String> whenServiceExtensionReady = waitForServiceExtension();
      final Future<dynamic> whenResumed = resumeLeniently();
      await whenResumed;

      _log.trace('Waiting for service extension');
      // We will never receive the extension event if the user does not
      // register it. If that happens, show a message but continue waiting.
      await _warnIfSlow<String>(
        future: whenServiceExtensionReady,
        timeout: kUnusuallyLongTimeout,
        message: 'Flutter Driver extension is taking a long time to become available. '
                 'Ensure your test app (often "lib/main.dart") imports '
                 '"package:flutter_driver/driver_extension.dart" and '
                 'calls enableFlutterDriverExtension() as the first call in main().',
      );
    } else if (isolate.pauseEvent is VMPauseExitEvent ||
               isolate.pauseEvent is VMPauseBreakpointEvent ||
               isolate.pauseEvent is VMPauseExceptionEvent ||
               isolate.pauseEvent is VMPauseInterruptedEvent) {
      // If the isolate is paused for any other reason, assume the extension is
      // already there.
      _log.trace('Isolate is paused mid-flight.');
      await resumeLeniently();
    } else if (isolate.pauseEvent is VMResumeEvent) {
      _log.trace('Isolate is not paused. Assuming application is ready.');
    } else {
      _log.warning(
        'Unknown pause event type ${isolate.pauseEvent.runtimeType}. '
        'Assuming application is ready.'
      );
    }

    // Invoked checkHealth and try to fix delays in the registration of Service
    // extensions
    Future<Health> checkHealth() async {
      try {
        // At this point the service extension must be installed. Verify it.
        return await driver.checkHealth();
      } on rpc.RpcException catch (e) {
        if (e.code != error_code.METHOD_NOT_FOUND) {
          rethrow;
        }
        _log.trace(
          'Check Health failed, try to wait for the service extensions to be'
          'registered.'
        );
        await enableIsolateStreams();
        await waitForServiceExtension();
        return driver.checkHealth();
      }
    }

    final Health health = await checkHealth();
    if (health.status != HealthStatus.ok) {
      await client.close();
      throw DriverError('Flutter application health check failed.');
    }

    _log.info('Connected to Flutter application.');
    return driver;
  }

  /// The unique ID of this driver instance.
  final int _driverId;

  /// Client connected to the Dart VM running the Flutter application
  ///
  /// You can use [VMServiceClient] to check VM version, flags and get
  /// notified when a new isolate has been instantiated. That could be
  /// useful if your application spawns multiple isolates that you
  /// would like to instrument.
  final VMServiceClient serviceClient;

  /// JSON-RPC client useful for sending raw JSON requests.
  rpc.Peer _peer;

  String _dartVmReconnectUrl;

  Future<void> _restorePeerConnectionIfNeeded() async {
    if (!_peer.isClosed || _dartVmReconnectUrl == null) {
      return;
    }

    _log.warning(
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

  /// The main isolate hosting the Flutter application.
  ///
  /// If you used the [registerExtension] API to instrument your application,
  /// you can use this [VMIsolate] to call these extension methods via
  /// [invokeExtension].
  final VMIsolate appIsolate;

  /// Whether to print communication between host and app to `stdout`.
  final bool _printCommunication;

  /// Whether to log communication between host and app to `flutter_driver_commands.log`.
  final bool _logCommunicationToFile;

  Future<Map<String, dynamic>> _sendCommand(Command command) async {
    Map<String, dynamic> response;
    try {
      final Map<String, String> serialized = command.serialize();
      _logCommunication('>>> $serialized');
      final Future<Map<String, dynamic>> future = appIsolate.invokeExtension(
        _flutterExtensionMethodName,
        serialized,
      ).then<Map<String, dynamic>>((Object value) => value);
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
    if (response['isError'])
      throw DriverError('Error in Flutter application: ${response['response']}');
    return response['response'];
  }

  void _logCommunication(String message) {
    if (_printCommunication)
      _log.info(message);
    if (_logCommunicationToFile) {
      final f.File file = fs.file(p.join(testOutputsDirectory, 'flutter_driver_commands_$_driverId.log'));
      file.createSync(recursive: true); // no-op if file exists
      file.writeAsStringSync('${DateTime.now()} $message\n', mode: f.FileMode.append, flush: true);
    }
  }

  /// Checks the status of the Flutter Driver extension.
  Future<Health> checkHealth({ Duration timeout }) async {
    return Health.fromJson(await _sendCommand(GetHealth(timeout: timeout)));
  }

  /// Returns a dump of the render tree.
  Future<RenderTree> getRenderTree({ Duration timeout }) async {
    return RenderTree.fromJson(await _sendCommand(GetRenderTree(timeout: timeout)));
  }

  /// Taps at the center of the widget located by [finder].
  Future<void> tap(SerializableFinder finder, { Duration timeout }) async {
    await _sendCommand(Tap(finder, timeout: timeout));
  }

  /// Waits until [finder] locates the target.
  Future<void> waitFor(SerializableFinder finder, { Duration timeout }) async {
    await _sendCommand(WaitFor(finder, timeout: timeout));
  }

  /// Waits until [finder] can no longer locate the target.
  Future<void> waitForAbsent(SerializableFinder finder, { Duration timeout }) async {
    await _sendCommand(WaitForAbsent(finder, timeout: timeout));
  }

  /// Waits until the given [waitCondition] is satisfied.
  Future<void> waitForCondition(SerializableWaitCondition waitCondition, {Duration timeout}) async {
    await _sendCommand(WaitForCondition(waitCondition, timeout: timeout));
  }

  /// Waits until there are no more transient callbacks in the queue.
  ///
  /// Use this method when you need to wait for the moment when the application
  /// becomes "stable", for example, prior to taking a [screenshot].
  Future<void> waitUntilNoTransientCallbacks({ Duration timeout }) async {
    await _sendCommand(WaitForCondition(const NoTransientCallbacks(), timeout: timeout));
  }

  /// Waits until the next [Window.onReportTimings] is called.
  ///
  /// Use this method to wait for the first frame to be rasterized during the
  /// app launch.
  Future<void> waitUntilFirstFrameRasterized() async {
    await _sendCommand(const WaitForCondition(FirstFrameRasterized()));
  }

  Future<DriverOffset> _getOffset(SerializableFinder finder, OffsetType type, { Duration timeout }) async {
    final GetOffset command = GetOffset(finder, type, timeout: timeout);
    final GetOffsetResult result = GetOffsetResult.fromJson(await _sendCommand(command));
    return DriverOffset(result.dx, result.dy);
  }

  /// Returns the point at the top left of the widget identified by `finder`.
  ///
  /// The offset is expressed in logical pixels and can be translated to
  /// device pixels via [Window.devicePixelRatio].
  Future<DriverOffset> getTopLeft(SerializableFinder finder, { Duration timeout }) async {
    return _getOffset(finder, OffsetType.topLeft, timeout: timeout);
  }

  /// Returns the point at the top right of the widget identified by `finder`.
  ///
  /// The offset is expressed in logical pixels and can be translated to
  /// device pixels via [Window.devicePixelRatio].
  Future<DriverOffset> getTopRight(SerializableFinder finder, { Duration timeout }) async {
    return _getOffset(finder, OffsetType.topRight, timeout: timeout);
  }

  /// Returns the point at the bottom left of the widget identified by `finder`.
  ///
  /// The offset is expressed in logical pixels and can be translated to
  /// device pixels via [Window.devicePixelRatio].
  Future<DriverOffset> getBottomLeft(SerializableFinder finder, { Duration timeout }) async {
    return _getOffset(finder, OffsetType.bottomLeft, timeout: timeout);
  }

  /// Returns the point at the bottom right of the widget identified by `finder`.
  ///
  /// The offset is expressed in logical pixels and can be translated to
  /// device pixels via [Window.devicePixelRatio].
  Future<DriverOffset> getBottomRight(SerializableFinder finder, { Duration timeout }) async {
    return _getOffset(finder, OffsetType.bottomRight, timeout: timeout);
  }

  /// Returns the point at the center of the widget identified by `finder`.
  ///
  /// The offset is expressed in logical pixels and can be translated to
  /// device pixels via [Window.devicePixelRatio].
  Future<DriverOffset> getCenter(SerializableFinder finder, { Duration timeout }) async {
    return _getOffset(finder, OffsetType.center, timeout: timeout);
  }

  /// Returns a JSON map of the [DiagnosticsNode] that is associated with the
  /// [RenderObject] identified by `finder`.
  ///
  /// The `subtreeDepth` argument controls how many layers of children will be
  /// included in the result. It defaults to zero, which means that no children
  /// of the [RenderObject] identified by `finder` will be part of the result.
  ///
  /// The `includeProperties` argument controls whether properties of the
  /// [DiagnosticsNode]s will be included in the result. It defaults to true.
  ///
  /// [RenderObject]s are responsible for positioning, layout, and painting on
  /// the screen, based on the configuration from a [Widget]. Callers that need
  /// information about size or position should use this method.
  ///
  /// A widget may indirectly create multiple [RenderObject]s, which each
  /// implement some aspect of the widget configuration. A 1:1 relationship
  /// should not be assumed.
  ///
  /// See also:
  ///
  ///  * [getWidgetDiagnostics], which gets the [DiagnosticsNode] of a [Widget].
  Future<Map<String, Object>> getRenderObjectDiagnostics(
      SerializableFinder finder, {
      int subtreeDepth = 0,
      bool includeProperties = true,
      Duration timeout,
  }) async {
    return _sendCommand(GetDiagnosticsTree(
      finder,
      DiagnosticsType.renderObject,
      subtreeDepth: subtreeDepth,
      includeProperties: includeProperties,
      timeout: timeout,
    ));
  }

  /// Returns a JSON map of the [DiagnosticsNode] that is associated with the
  /// [Widget] identified by `finder`.
  ///
  /// The `subtreeDepth` argument controls how many layers of children will be
  /// included in the result. It defaults to zero, which means that no children
  /// of the [Widget] identified by `finder` will be part of the result.
  ///
  /// The `includeProperties` argument controls whether properties of the
  /// [DiagnosticsNode]s will be included in the result. It defaults to true.
  ///
  /// [Widget]s describe configuration for the rendering tree. Individual
  /// widgets may create multiple [RenderObject]s to actually layout and paint
  /// the desired configuration.
  ///
  /// See also:
  ///
  ///  * [getRenderObjectDiagnostics], which gets the [DiagnosticsNode] of a
  ///    [RenderObject].
  Future<Map<String, Object>> getWidgetDiagnostics(
    SerializableFinder finder, {
    int subtreeDepth = 0,
    bool includeProperties = true,
    Duration timeout,
  }) async {
    return _sendCommand(GetDiagnosticsTree(
      finder,
      DiagnosticsType.renderObject,
      subtreeDepth: subtreeDepth,
      includeProperties: includeProperties,
      timeout: timeout,
    ));
  }

  /// Tell the driver to perform a scrolling action.
  ///
  /// A scrolling action begins with a "pointer down" event, which commonly maps
  /// to finger press on the touch screen or mouse button press. A series of
  /// "pointer move" events follow. The action is completed by a "pointer up"
  /// event.
  ///
  /// [dx] and [dy] specify the total offset for the entire scrolling action.
  ///
  /// [duration] specifies the length of the action.
  ///
  /// The move events are generated at a given [frequency] in Hz (or events per
  /// second). It defaults to 60Hz.
  Future<void> scroll(SerializableFinder finder, double dx, double dy, Duration duration, { int frequency = 60, Duration timeout }) async {
    await _sendCommand(Scroll(finder, dx, dy, duration, frequency, timeout: timeout));
  }

  /// Scrolls the Scrollable ancestor of the widget located by [finder]
  /// until the widget is completely visible.
  ///
  /// If the widget located by [finder] is contained by a scrolling widget
  /// that lazily creates its children, like [ListView] or [CustomScrollView],
  /// then this method may fail because [finder] doesn't actually exist.
  /// The [scrollUntilVisible] method can be used in this case.
  Future<void> scrollIntoView(SerializableFinder finder, { double alignment = 0.0, Duration timeout }) async {
    await _sendCommand(ScrollIntoView(finder, alignment: alignment, timeout: timeout));
  }

  /// Repeatedly [scroll] the widget located by [scrollable] by [dxScroll] and
  /// [dyScroll] until [item] is visible, and then use [scrollIntoView] to
  /// ensure the item's final position matches [alignment].
  ///
  /// The [scrollable] must locate the scrolling widget that contains [item].
  /// Typically `find.byType('ListView')` or `find.byType('CustomScrollView')`.
  ///
  /// At least one of [dxScroll] and [dyScroll] must be non-zero.
  ///
  /// If [item] is below the currently visible items, then specify a negative
  /// value for [dyScroll] that's a small enough increment to expose [item]
  /// without potentially scrolling it up and completely out of view. Similarly
  /// if [item] is above, then specify a positive value for [dyScroll].
  ///
  /// If [item] is to the right of the currently visible items, then
  /// specify a negative value for [dxScroll] that's a small enough increment to
  /// expose [item] without potentially scrolling it up and completely out of
  /// view. Similarly if [item] is to the left, then specify a positive value
  /// for [dyScroll].
  ///
  /// The [timeout] value should be long enough to accommodate as many scrolls
  /// as needed to bring an item into view. The default is to not time out.
  Future<void> scrollUntilVisible(
    SerializableFinder scrollable,
    SerializableFinder item, {
    double alignment = 0.0,
    double dxScroll = 0.0,
    double dyScroll = 0.0,
    Duration timeout,
  }) async {
    assert(scrollable != null);
    assert(item != null);
    assert(alignment != null);
    assert(dxScroll != null);
    assert(dyScroll != null);
    assert(dxScroll != 0.0 || dyScroll != 0.0);

    // Kick off an (unawaited) waitFor that will complete when the item we're
    // looking for finally scrolls onscreen. We add an initial pause to give it
    // the chance to complete if the item is already onscreen; if not, scroll
    // repeatedly until we either find the item or time out.
    bool isVisible = false;
    waitFor(item, timeout: timeout).then<void>((_) { isVisible = true; });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    while (!isVisible) {
      await scroll(scrollable, dxScroll, dyScroll, const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    return scrollIntoView(item, alignment: alignment);
  }

  /// Returns the text in the `Text` widget located by [finder].
  Future<String> getText(SerializableFinder finder, { Duration timeout }) async {
    return GetTextResult.fromJson(await _sendCommand(GetText(finder, timeout: timeout))).text;
  }

  /// Enters `text` into the currently focused text input, such as the
  /// [EditableText] widget.
  ///
  /// This method does not use the operating system keyboard to enter text.
  /// Instead it emulates text entry by sending events identical to those sent
  /// by the operating system keyboard (the "TextInputClient.updateEditingState"
  /// method channel call).
  ///
  /// Generally the behavior is dependent on the implementation of the widget
  /// receiving the input. Usually, editable widgets, such as [EditableText] and
  /// those built on top of it would replace the currently entered text with the
  /// provided `text`.
  ///
  /// It is assumed that the widget receiving text input is focused prior to
  /// calling this method. Typically, a test would activate a widget, e.g. using
  /// [tap], then call this method.
  ///
  /// For this method to work, text emulation must be enabled (see
  /// [setTextEntryEmulation]). Text emulation is enabled by default.
  ///
  /// Example:
  ///
  /// ```dart
  /// test('enters text in a text field', () async {
  ///   var textField = find.byValueKey('enter-text-field');
  ///   await driver.tap(textField);  // acquire focus
  ///   await driver.enterText('Hello!');  // enter text
  ///   await driver.waitFor(find.text('Hello!'));  // verify text appears on UI
  ///   await driver.enterText('World!');  // enter another piece of text
  ///   await driver.waitFor(find.text('World!'));  // verify new text appears
  /// });
  /// ```
  Future<void> enterText(String text, { Duration timeout }) async {
    await _sendCommand(EnterText(text, timeout: timeout));
  }

  /// Configures text entry emulation.
  ///
  /// If `enabled` is true, enables text entry emulation via [enterText]. If
  /// `enabled` is false, disables it. By default text entry emulation is
  /// enabled.
  ///
  /// When disabled, [enterText] will fail with a [DriverError]. When an
  /// [EditableText] is focused, the operating system's configured keyboard
  /// method is invoked, such as an on-screen keyboard on a phone or a tablet.
  ///
  /// When enabled, the operating system's configured keyboard will not be
  /// invoked when the widget is focused, as the [SystemChannels.textInput]
  /// channel will be mocked out.
  Future<void> setTextEntryEmulation({ @required bool enabled, Duration timeout }) async {
    assert(enabled != null);
    await _sendCommand(SetTextEntryEmulation(enabled, timeout: timeout));
  }

  /// Sends a string and returns a string.
  ///
  /// This enables generic communication between the driver and the application.
  /// It's expected that the application has registered a [DataHandler]
  /// callback in [enableFlutterDriverExtension] that can successfully handle
  /// these requests.
  Future<String> requestData(String message, { Duration timeout }) async {
    return RequestDataResult.fromJson(await _sendCommand(RequestData(message, timeout: timeout))).message;
  }

  /// Turns semantics on or off in the Flutter app under test.
  ///
  /// Returns true when the call actually changed the state from on to off or
  /// vice versa.
  Future<bool> setSemantics(bool enabled, { Duration timeout }) async {
    final SetSemanticsResult result = SetSemanticsResult.fromJson(await _sendCommand(SetSemantics(enabled, timeout: timeout)));
    return result.changedState;
  }

  /// Retrieves the semantics node id for the object returned by `finder`, or
  /// the nearest ancestor with a semantics node.
  ///
  /// Throws an error if `finder` returns multiple elements or a semantics
  /// node is not found.
  ///
  /// Semantics must be enabled to use this method, either using a platform
  /// specific shell command or [setSemantics].
  Future<int> getSemanticsId(SerializableFinder finder, { Duration timeout }) async {
    final Map<String, dynamic> jsonResponse = await _sendCommand(GetSemanticsId(finder, timeout: timeout));
    final GetSemanticsIdResult result = GetSemanticsIdResult.fromJson(jsonResponse);
    return result.id;
  }

  /// Take a screenshot.
  ///
  /// The image will be returned as a PNG.
  Future<List<int>> screenshot() async {
    // HACK: this artificial delay here is to deal with a race between the
    //       driver script and the GPU thread. The issue is that driver API
    //       synchronizes with the framework based on transient callbacks, which
    //       are out of sync with the GPU thread. Here's the timeline of events
    //       in ASCII art:
    //
    //       -------------------------------------------------------------------
    //       Without this delay:
    //       -------------------------------------------------------------------
    //       UI    : <-- build -->
    //       GPU   :               <-- rasterize -->
    //       Gap   :              | random |
    //       Driver:                        <-- screenshot -->
    //
    //       In the diagram above, the gap is the time between the last driver
    //       action taken, such as a `tap()`, and the subsequent call to
    //       `screenshot()`. The gap is random because it is determined by the
    //       unpredictable network communication between the driver process and
    //       the application. If this gap is too short, which it typically will
    //       be, the screenshot is taken before the GPU thread is done
    //       rasterizing the frame, so the screenshot of the previous frame is
    //       taken, which is wrong.
    //
    //       -------------------------------------------------------------------
    //       With this delay, if we're lucky:
    //       -------------------------------------------------------------------
    //       UI    : <-- build -->
    //       GPU   :               <-- rasterize -->
    //       Gap   :              |    2 seconds or more   |
    //       Driver:                                        <-- screenshot -->
    //
    //       The two-second gap should be long enough for the GPU thread to
    //       finish rasterizing the frame, but not longer than necessary to keep
    //       driver tests as fast a possible.
    //
    //       -------------------------------------------------------------------
    //       With this delay, if we're not lucky:
    //       -------------------------------------------------------------------
    //       UI    : <-- build -->
    //       GPU   :               <-- rasterize randomly slow today -->
    //       Gap   :              |    2 seconds or more   |
    //       Driver:                                        <-- screenshot -->
    //
    //       In practice, sometimes the device gets really busy for a while and
    //       even two seconds isn't enough, which means that this is still racy
    //       and a source of flakes.
    await Future<void>.delayed(const Duration(seconds: 2));

    final Map<String, dynamic> result = await _peer.sendRequest('_flutter.screenshot');
    return base64.decode(result['screenshot']);
  }

  /// Returns the Flags set in the Dart VM as JSON.
  ///
  /// See the complete documentation for [the `getFlagList` Dart VM service
  /// method][getFlagList].
  ///
  /// Example return value:
  ///
  ///     [
  ///       {
  ///         "name": "timeline_recorder",
  ///         "comment": "Select the timeline recorder used. Valid values: ring, endless, startup, and systrace.",
  ///         "modified": false,
  ///         "_flagType": "String",
  ///         "valueAsString": "ring"
  ///       },
  ///       ...
  ///     ]
  ///
  /// [getFlagList]: https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#getflaglist
  Future<List<Map<String, dynamic>>> getVmFlags() async {
    await _restorePeerConnectionIfNeeded();
    final Map<String, dynamic> result = await _peer.sendRequest('getFlagList');
    return result != null
        ? result['flags'].cast<Map<String,dynamic>>()
        : const <Map<String, dynamic>>[];
  }

  /// Starts recording performance traces.
  ///
  /// The `timeout` argument causes a warning to be displayed to the user if the
  /// operation exceeds the specified timeout; it does not actually cancel the
  /// operation.
  Future<void> startTracing({
    List<TimelineStream> streams = _defaultStreams,
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

  /// Stops recording performance traces and downloads the timeline.
  ///
  /// The `timeout` argument causes a warning to be displayed to the user if the
  /// operation exceeds the specified timeout; it does not actually cancel the
  /// operation.
  Future<Timeline> stopTracingAndDownloadTimeline({
    Duration timeout = kUnusuallyLongTimeout,
  }) async {
    assert(timeout != null);
    try {
      await _warnIfSlow<void>(
        future: _peer.sendRequest(_setVMTimelineFlagsMethodName, <String, String>{'recordedStreams': '[]'}),
        timeout: timeout,
        message: 'VM is taking an unusually long time to respond to being told to stop tracing...',
      );
      return Timeline.fromJson(await _peer.sendRequest(_getVMTimelineMethodName));
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
    for(Map<String, dynamic> flag in flags) {
      if (flag['name'] == 'precompiled_mode') {
        return flag['valueAsString'] == 'true';
      }
    }
    return false;
  }

  /// Runs [action] and outputs a performance trace for it.
  ///
  /// Waits for the `Future` returned by [action] to complete prior to stopping
  /// the trace.
  ///
  /// This is merely a convenience wrapper on top of [startTracing] and
  /// [stopTracingAndDownloadTimeline].
  ///
  /// [streams] limits the recorded timeline event streams to only the ones
  /// listed. By default, all streams are recorded.
  ///
  /// If [retainPriorEvents] is true, retains events recorded prior to calling
  /// [action]. Otherwise, prior events are cleared before calling [action]. By
  /// default, prior events are cleared.
  ///
  /// If this is run in debug mode, a warning message will be printed to suggest
  /// running the benchmark in profile mode instead.
  Future<Timeline> traceAction(
    Future<dynamic> action(), {
    List<TimelineStream> streams = _defaultStreams,
    bool retainPriorEvents = false,
  }) async {
    if (!retainPriorEvents) {
      await clearTimeline();
    }
    await startTracing(streams: streams);
    await action();

    if (!(await _isPrecompiledMode())) {
      _log.warning(_kDebugWarning);
    }
    return stopTracingAndDownloadTimeline();
  }

  /// Clears all timeline events recorded up until now.
  ///
  /// The `timeout` argument causes a warning to be displayed to the user if the
  /// operation exceeds the specified timeout; it does not actually cancel the
  /// operation.
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

  /// [action] will be executed with the frame sync mechanism disabled.
  ///
  /// By default, Flutter Driver waits until there is no pending frame scheduled
  /// in the app under test before executing an action. This mechanism is called
  /// "frame sync". It greatly reduces flakiness because Flutter Driver will not
  /// execute an action while the app under test is undergoing a transition.
  ///
  /// Having said that, sometimes it is necessary to disable the frame sync
  /// mechanism (e.g. if there is an ongoing animation in the app, it will
  /// never reach a state where there are no pending frames scheduled and the
  /// action will time out). For these cases, the sync mechanism can be disabled
  /// by wrapping the actions to be performed by this [runUnsynchronized] method.
  ///
  /// With frame sync disabled, its the responsibility of the test author to
  /// ensure that no action is performed while the app is undergoing a
  /// transition to avoid flakiness.
  Future<T> runUnsynchronized<T>(Future<T> action(), { Duration timeout }) async {
    await _sendCommand(SetFrameSync(false, timeout: timeout));
    T result;
    try {
      result = await action();
    } finally {
      await _sendCommand(SetFrameSync(true, timeout: timeout));
    }
    return result;
  }

  /// Force a garbage collection run in the VM.
  Future<void> forceGC() async {
    try {
      await _peer
          .sendRequest(_collectAllGarbageMethodName, <String, String>{
            'isolateId': 'isolates/${appIsolate.numberAsString}',
          });
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to force a GC due to remote error',
        error,
        stackTrace,
      );
    }
  }

  /// Closes the underlying connection to the VM service.
  ///
  /// Returns a [Future] that fires once the connection has been closed.
  Future<void> close() async {
    // Don't leak vm_service_client-specific objects, if any
    await serviceClient.close();
    await _peer.close();
  }
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

/// A function that connects to a Dart VM service given the [url].
typedef VMServiceConnectFunction = Future<VMServiceClientConnection> Function(String url);

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
  _log.trace('Unhandled RPC error:\n$error\n$stack');
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
    _log.warning('$ws is closed with an unexpected code ${ws.closeCode}');
  }
}

/// Waits for a real Dart VM service to become available, then connects using
/// the [VMServiceClient].
Future<VMServiceClientConnection> _waitAndConnect(String url) async {
  final String webSocketUrl = _getWebSocketUrl(url);
  int attempts = 0;
  while (true) {
    WebSocket ws1;
    WebSocket ws2;
    try {
      ws1 = await WebSocket.connect(webSocketUrl);
      ws2 = await WebSocket.connect(webSocketUrl);

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
        _log.warning('It is taking an unusually long time to connect to the VM...');
      attempts += 1;
      await Future<void>.delayed(_kPauseBetweenReconnectAttempts);
    }
  }
}

/// Provides convenient accessors to frequently used finders.
class CommonFinders {
  const CommonFinders._();

  /// Finds [Text] and [EditableText] widgets containing string equal to [text].
  SerializableFinder text(String text) => ByText(text);

  /// Finds widgets by [key]. Only [String] and [int] values can be used.
  SerializableFinder byValueKey(dynamic key) => ByValueKey(key);

  /// Finds widgets with a tooltip with the given [message].
  SerializableFinder byTooltip(String message) => ByTooltipMessage(message);

  /// Finds widgets with the given semantics [label].
  SerializableFinder bySemanticsLabel(Pattern label) => BySemanticsLabel(label);

  /// Finds widgets whose class name matches the given string.
  SerializableFinder byType(String type) => ByType(type);

  /// Finds the back button on a Material or Cupertino page's scaffold.
  SerializableFinder pageBack() => const PageBack();

  /// Finds the widget that is an ancestor of the `of` parameter and that
  /// matches the `matching` parameter.
  ///
  /// If the `matchRoot` argument is true then the widget specified by `of` will
  /// be considered for a match. The argument defaults to false.
  ///
  /// If `firstMatchOnly` is true then only the first ancestor matching
  /// `matching` will be returned. Defaults to false.
  SerializableFinder ancestor({
    @required SerializableFinder of,
    @required SerializableFinder matching,
    bool matchRoot = false,
    bool firstMatchOnly = false,
  }) => Ancestor(of: of, matching: matching, matchRoot: matchRoot, firstMatchOnly: firstMatchOnly);

  /// Finds the widget that is an descendant of the `of` parameter and that
  /// matches the `matching` parameter.
  ///
  /// If the `matchRoot` argument is true then the widget specified by `of` will
  /// be considered for a match. The argument defaults to false.
  ///
  /// If `firstMatchOnly` is true then only the first descendant matching
  /// `matching` will be returned. Defaults to false.
  SerializableFinder descendant({
    @required SerializableFinder of,
    @required SerializableFinder matching,
    bool matchRoot = false,
    bool firstMatchOnly = false,
  }) => Descendant(of: of, matching: matching, matchRoot: matchRoot, firstMatchOnly: firstMatchOnly);
}

/// An immutable 2D floating-point offset used by Flutter Driver.
class DriverOffset {
  /// Creates an offset.
  const DriverOffset(this.dx, this.dy);

  /// The x component of the offset.
  final double dx;

  /// The y component of the offset.
  final double dy;

  @override
  String toString() => '$runtimeType($dx, $dy)';

  @override
  bool operator ==(dynamic other) {
    if (other is! DriverOffset)
      return false;
    final DriverOffset typedOther = other;
    return dx == typedOther.dx && dy == typedOther.dy;
  }

  @override
  int get hashCode => dx.hashCode + dy.hashCode;
}
