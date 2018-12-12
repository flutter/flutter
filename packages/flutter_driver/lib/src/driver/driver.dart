// Copyright 2016 The Chromium Authors. All rights reserved.
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

import '../common/error.dart';
import '../common/find.dart';
import '../common/frame_sync.dart';
import '../common/fuchsia_compat.dart';
import '../common/gesture.dart';
import '../common/health.dart';
import '../common/message.dart';
import '../common/render_tree.dart';
import '../common/request_data.dart';
import '../common/semantics.dart';
import '../common/text.dart';
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

/// Multiplies the timeout values used when establishing a connection to the
/// Flutter app under test and obtain an instance of [FlutterDriver].
///
/// This multiplier applies automatically when using the default implementation
/// of the [vmServiceConnectFunction].
///
/// See also:
///
///  * [FlutterDriver.timeoutMultiplier], which multiplies all command timeouts by this number.
double connectionTimeoutMultiplier = _kDefaultTimeoutMultiplier;

const double _kDefaultTimeoutMultiplier = 1.0;

/// Default timeout for short-running RPCs.
Duration _shortTimeout(double multiplier) => const Duration(seconds: 5) * multiplier;

/// Default timeout for awaiting an Isolate to become runnable.
Duration _isolateLoadRunnableTimeout(double multiplier) => const Duration(minutes: 1) * multiplier;

/// Time to delay before driving a Fuchsia module.
Duration _fuchsiaDriveDelay(double multiplier) => const Duration(milliseconds: 500) * multiplier;

/// Default timeout for long-running RPCs.
Duration _longTimeout(double multiplier) => _shortTimeout(multiplier) * 6;

/// Additional amount of time we give the command to finish or timeout remotely
/// before timing out locally.
Duration _rpcGraceTime(double multiplier) => _shortTimeout(multiplier) ~/ 2;

/// The amount of time we wait prior to making the next attempt to connect to
/// the VM service.
Duration _pauseBetweenReconnectAttempts(double multiplier) => _shortTimeout(multiplier) ~/ 5;

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
  /// [_serviceClient], [_peer] and [_appIsolate].
  @visibleForTesting
  FlutterDriver.connectedTo(
    this._serviceClient,
    this._peer,
    this._appIsolate, {
    bool printCommunication = false,
    bool logCommunicationToFile = true,
    this.timeoutMultiplier = _kDefaultTimeoutMultiplier,
  }) : _printCommunication = printCommunication,
       _logCommunicationToFile = logCommunicationToFile,
       _driverId = _nextDriverId++;

  static const String _flutterExtensionMethodName = 'ext.flutter.driver';
  static const String _setVMTimelineFlagsMethodName = '_setVMTimelineFlags';
  static const String _getVMTimelineMethodName = '_getVMTimeline';
  static const String _clearVMTimelineMethodName = '_clearVMTimeline';
  static const String _collectAllGarbageMethodName = '_collectAllGarbage';

  static int _nextDriverId = 0;

  /// Connects to a Flutter application.
  ///
  /// Resumes the application if it is currently paused (e.g. at a breakpoint).
  ///
  /// [dartVmServiceUrl] is the URL to Dart observatory (a.k.a. VM service). If
  /// not specified, the URL specified by the `VM_SERVICE_URL` environment
  /// variable is used. One or the other must be specified.
  ///
  /// [printCommunication] determines whether the command communication between
  /// the test and the app should be printed to stdout.
  ///
  /// [logCommunicationToFile] determines whether the command communication
  /// between the test and the app should be logged to `flutter_driver_commands.log`.
  ///
  /// [FlutterDriver] multiplies all command timeouts by [timeoutMultiplier].
  ///
  /// [isolateNumber] (optional) determines the specific isolate to connect to.
  /// If this is left as `null`, will connect to the first isolate found
  /// running on [dartVmServiceUrl].
  ///
  /// [isolateReadyTimeout] determines how long after we connect to the VM
  /// service we will wait for the first isolate to become runnable. Explicitly
  /// specified non-null values are not affected by [timeoutMultiplier].
  ///
  /// [fuchsiaModuleTarget] (optional) If running on a Fuchsia Device, either
  /// this or the environment variable `FUCHSIA_MODULE_TARGET` must be set. This
  /// field will be ignored if [isolateNumber] is set, as this is already
  /// enough information to connect to an Isolate.
  static Future<FlutterDriver> connect({
    String dartVmServiceUrl,
    bool printCommunication = false,
    bool logCommunicationToFile = true,
    double timeoutMultiplier = _kDefaultTimeoutMultiplier,
    int isolateNumber,
    Duration isolateReadyTimeout,
    Pattern fuchsiaModuleTarget,
  }) async {
    isolateReadyTimeout ??= _isolateLoadRunnableTimeout(timeoutMultiplier);
    // If running on a Fuchsia device, connect to the first Isolate whose name
    // matches FUCHSIA_MODULE_TARGET.
    //
    // If the user has already supplied an isolate number/URL to the Dart VM
    // service, then this won't be run as it is unnecessary.
    if (Platform.isFuchsia && isolateNumber == null) {
      fuchsiaModuleTarget ??= Platform.environment['FUCHSIA_MODULE_TARGET'];
      if (fuchsiaModuleTarget == null) {
        throw DriverError('No Fuchsia module target has been specified.\n'
            'Please make sure to specify the FUCHSIA_MODULE_TARGET\n'
            'environment variable.');
      }
      final fuchsia.FuchsiaRemoteConnection fuchsiaConnection =
          await FuchsiaCompat.connect();
      final List<fuchsia.IsolateRef> refs =
          await fuchsiaConnection.getMainIsolatesByPattern(fuchsiaModuleTarget);
      final fuchsia.IsolateRef ref = refs.first;
      await Future<void>.delayed(_fuchsiaDriveDelay(timeoutMultiplier));
      isolateNumber = ref.number;
      dartVmServiceUrl = ref.dartVm.uri.toString();
      await fuchsiaConnection.stop();
      FuchsiaCompat.cleanup();

      // TODO(awdavies): Use something other than print. On fuchsia
      // `stderr`/`stdout` appear to have issues working correctly.
      flutterDriverLog.listen(print);
    }

    dartVmServiceUrl ??= Platform.environment['VM_SERVICE_URL'];

    if (dartVmServiceUrl == null) {
      throw DriverError(
          'Could not determine URL to connect to application.\n'
          'Either the VM_SERVICE_URL environment variable should be set, or an explicit\n'
          'URL should be provided to the FlutterDriver.connect() method.');
    }

    // Connect to Dart VM services
    _log.info('Connecting to Flutter application at $dartVmServiceUrl');
    connectionTimeoutMultiplier = timeoutMultiplier;
    final VMServiceClientConnection connection =
        await vmServiceConnectFunction(dartVmServiceUrl);
    final VMServiceClient client = connection.client;
    final VM vm = await client.getVM();
    final VMIsolateRef isolateRef = isolateNumber ==
        null ? vm.isolates.first :
               vm.isolates.firstWhere(
                   (VMIsolateRef isolate) => isolate.number == isolateNumber);
    _log.trace('Isolate found with number: ${isolateRef.number}');

    VMIsolate isolate = await isolateRef
        .loadRunnable()
        .timeout(isolateReadyTimeout, onTimeout: () {
      throw TimeoutException(
          'Timeout while waiting for the isolate to become runnable');
    });

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
      await Future<void>.delayed(_shortTimeout(timeoutMultiplier) ~/ 10);
      isolate = await isolateRef.loadRunnable();
    }

    final FlutterDriver driver = FlutterDriver.connectedTo(
      client, connection.peer, isolate,
      printCommunication: printCommunication,
      logCommunicationToFile: logCommunicationToFile,
      timeoutMultiplier: timeoutMultiplier,
    );

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
      final Future<dynamic> whenServiceExtensionReady = waitForServiceExtension();
      final Future<dynamic> whenResumed = resumeLeniently();
      await whenResumed;

      try {
        _log.trace('Waiting for service extension');
        // We will never receive the extension event if the user does not
        // register it. If that happens time out.
        await whenServiceExtensionReady.timeout(_longTimeout(timeoutMultiplier) * 2);
      } on TimeoutException catch (_) {
        throw DriverError(
          'Timed out waiting for Flutter Driver extension to become available. '
          'Ensure your test app (often: lib/main.dart) imports '
          '"package:flutter_driver/driver_extension.dart" and '
          'calls enableFlutterDriverExtension() as the first call in main().'
        );
      }
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
        await waitForServiceExtension().timeout(_longTimeout(timeoutMultiplier) * 2);
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
  final VMServiceClient _serviceClient;

  /// JSON-RPC client useful for sending raw JSON requests.
  final rpc.Peer _peer;

  /// The main isolate hosting the Flutter application
  final VMIsolate _appIsolate;

  /// Whether to print communication between host and app to `stdout`.
  final bool _printCommunication;

  /// Whether to log communication between host and app to `flutter_driver_commands.log`.
  final bool _logCommunicationToFile;

  /// [FlutterDriver] multiplies all command timeouts by this number.
  ///
  /// The right amount of time a driver command should be given to complete
  /// depends on various environmental factors, such as the speed of the
  /// device or the emulator, connection speed and latency, and others. Use
  /// this multiplier to tailor the timeouts to your environment.
  final double timeoutMultiplier;

  Future<Map<String, dynamic>> _sendCommand(Command command) async {
    Map<String, dynamic> response;
    try {
      final Map<String, String> serialized = command.serialize();
      _logCommunication('>>> $serialized');
      response = await _appIsolate
          .invokeExtension(_flutterExtensionMethodName, serialized)
          .timeout(command.timeout + _rpcGraceTime(timeoutMultiplier));
      _logCommunication('<<< $response');
    } on TimeoutException catch (error, stackTrace) {
      throw DriverError(
        'Failed to fulfill ${command.runtimeType}: Flutter application not responding',
        error,
        stackTrace,
      );
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

  void _logCommunication(String message)  {
    if (_printCommunication)
      _log.info(message);
    if (_logCommunicationToFile) {
      final f.File file = fs.file(p.join(testOutputsDirectory, 'flutter_driver_commands_$_driverId.log'));
      file.createSync(recursive: true); // no-op if file exists
      file.writeAsStringSync('${DateTime.now()} $message\n', mode: f.FileMode.append, flush: true);
    }
  }

  /// Checks the status of the Flutter Driver extension.
  Future<Health> checkHealth({Duration timeout}) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    return Health.fromJson(await _sendCommand(GetHealth(timeout: timeout)));
  }

  /// Returns a dump of the render tree.
  Future<RenderTree> getRenderTree({Duration timeout}) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    return RenderTree.fromJson(await _sendCommand(GetRenderTree(timeout: timeout)));
  }

  /// Taps at the center of the widget located by [finder].
  Future<void> tap(SerializableFinder finder, {Duration timeout}) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    await _sendCommand(Tap(finder, timeout: timeout));
  }

  /// Waits until [finder] locates the target.
  Future<void> waitFor(SerializableFinder finder, {Duration timeout}) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    await _sendCommand(WaitFor(finder, timeout: timeout));
  }

  /// Waits until [finder] can no longer locate the target.
  Future<void> waitForAbsent(SerializableFinder finder, {Duration timeout}) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    await _sendCommand(WaitForAbsent(finder, timeout: timeout));
  }

  /// Waits until there are no more transient callbacks in the queue.
  ///
  /// Use this method when you need to wait for the moment when the application
  /// becomes "stable", for example, prior to taking a [screenshot].
  Future<void> waitUntilNoTransientCallbacks({Duration timeout}) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    await _sendCommand(WaitUntilNoTransientCallbacks(timeout: timeout));
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
    timeout ??= _shortTimeout(timeoutMultiplier);
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
    timeout ??= _shortTimeout(timeoutMultiplier);
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
  /// as needed to bring an item into view. The default is 10 seconds.
  Future<void> scrollUntilVisible(SerializableFinder scrollable, SerializableFinder item, {
    double alignment = 0.0,
    double dxScroll = 0.0,
    double dyScroll = 0.0,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    assert(scrollable != null);
    assert(item != null);
    assert(alignment != null);
    assert(dxScroll != null);
    assert(dyScroll != null);
    assert(dxScroll != 0.0 || dyScroll != 0.0);
    assert(timeout != null);

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
    timeout ??= _shortTimeout(timeoutMultiplier);
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
  ///  var textField = find.byValueKey('enter-text-field');
  ///  await driver.tap(textField);  // acquire focus
  ///  await driver.enterText('Hello!');  // enter text
  ///  await driver.waitFor(find.text('Hello!'));  // verify text appears on UI
  ///  await driver.enterText('World!');  // enter another piece of text
  ///  await driver.waitFor(find.text('World!'));  // verify new text appears
  /// });
  /// ```
  Future<void> enterText(String text, { Duration timeout }) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
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
    timeout ??= _shortTimeout(timeoutMultiplier);
    await _sendCommand(SetTextEntryEmulation(enabled, timeout: timeout));
  }

  /// Sends a string and returns a string.
  ///
  /// This enables generic communication between the driver and the application.
  /// It's expected that the application has registered a [DataHandler]
  /// callback in [enableFlutterDriverExtension] that can successfully handle
  /// these requests.
  Future<String> requestData(String message, { Duration timeout }) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    return RequestDataResult.fromJson(await _sendCommand(RequestData(message, timeout: timeout))).message;
  }

  /// Turns semantics on or off in the Flutter app under test.
  ///
  /// Returns true when the call actually changed the state from on to off or
  /// vice versa.
  Future<bool> setSemantics(bool enabled, { Duration timeout }) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
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
    timeout ??= _shortTimeout(timeoutMultiplier);
    final Map<String, dynamic> jsonResponse = await _sendCommand(GetSemanticsId(finder, timeout: timeout));
    final GetSemanticsIdResult result = GetSemanticsIdResult.fromJson(jsonResponse);
    return result.id;
  }

  /// Take a screenshot.  The image will be returned as a PNG.
  Future<List<int>> screenshot({ Duration timeout }) async {
    timeout ??= _longTimeout(timeoutMultiplier);

    // HACK: this artificial delay here is to deal with a race between the
    //       driver script and the GPU thread. The issue is that driver API
    //       synchronizes with the framework based on transient callbacks, which
    //       are out of sync with the GPU thread. Here's the timeline of events
    //       in ASCII art:
    //
    //       -------------------------------------------------------------------
    //       Before this change:
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
    //       the application. If this gap is too short, the screenshot is taken
    //       before the GPU thread is done rasterizing the frame, so the
    //       screenshot of the previous frame is taken, which is wrong.
    //
    //       -------------------------------------------------------------------
    //       After this change:
    //       -------------------------------------------------------------------
    //       UI    : <-- build -->
    //       GPU   :               <-- rasterize -->
    //       Gap   :              |    2 seconds or more   |
    //       Driver:                                        <-- screenshot -->
    //
    //       The two-second gap should be long enough for the GPU thread to
    //       finish rasterizing the frame, but not longer than necessary to keep
    //       driver tests as fast a possible.
    await Future<void>.delayed(const Duration(seconds: 2));

    final Map<String, dynamic> result = await _peer.sendRequest('_flutter.screenshot').timeout(timeout);
    return base64.decode(result['screenshot']);
  }

  /// Returns the Flags set in the Dart VM as JSON.
  ///
  /// See the complete documentation for `getFlagList` Dart VM service method
  /// [here][getFlagList].
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
  Future<List<Map<String, dynamic>>> getVmFlags({ Duration timeout }) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    final Map<String, dynamic> result = await _peer.sendRequest('getFlagList').timeout(timeout);
    return result['flags'];
  }

  /// Starts recording performance traces.
  Future<void> startTracing({
    List<TimelineStream> streams = _defaultStreams,
    Duration timeout,
  }) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    assert(streams != null && streams.isNotEmpty);
    try {
      await _peer.sendRequest(_setVMTimelineFlagsMethodName, <String, String>{
        'recordedStreams': _timelineStreamsToString(streams)
      }).timeout(timeout);
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to start tracing due to remote error',
        error,
        stackTrace,
      );
    }
  }

  /// Stops recording performance traces and downloads the timeline.
  Future<Timeline> stopTracingAndDownloadTimeline({ Duration timeout }) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    try {
      await _peer
          .sendRequest(_setVMTimelineFlagsMethodName, <String, String>{'recordedStreams': '[]'})
          .timeout(timeout);
      return Timeline.fromJson(await _peer.sendRequest(_getVMTimelineMethodName));
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to stop tracing due to remote error',
        error,
        stackTrace,
      );
    }
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
    return stopTracingAndDownloadTimeline();
  }

  /// Clears all timeline events recorded up until now.
  Future<void> clearTimeline({ Duration timeout }) async {
    timeout ??= _shortTimeout(timeoutMultiplier);
    try {
      await _peer
          .sendRequest(_clearVMTimelineMethodName, <String, String>{})
          .timeout(timeout);
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
    timeout ??= _shortTimeout(timeoutMultiplier);
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

  /// Closes the underlying connection to the VM service.
  ///
  /// Returns a [Future] that fires once the connection has been closed.
  Future<void> close() async {
    // Don't leak vm_service_client-specific objects, if any
    await _serviceClient.close();
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
///
/// See also:
///
///  * [connectionTimeoutMultiplier], which controls the timeouts while
///    establishing a connection using the default connection function.
VMServiceConnectFunction vmServiceConnectFunction = _waitAndConnect;

/// Restores [vmServiceConnectFunction] to its default value.
void restoreVmServiceConnectFunction() {
  vmServiceConnectFunction = _waitAndConnect;
}

/// Waits for a real Dart VM service to become available, then connects using
/// the [VMServiceClient].
///
/// Times out after 30 seconds.
Future<VMServiceClientConnection> _waitAndConnect(String url) async {
  final Stopwatch timer = Stopwatch()..start();

  Future<VMServiceClientConnection> attemptConnection() async {
    Uri uri = Uri.parse(url);
    if (uri.scheme == 'http')
      uri = uri.replace(scheme: 'ws', path: '/ws');

    WebSocket ws1;
    WebSocket ws2;
    try {
      ws1 = await WebSocket.connect(uri.toString()).timeout(_shortTimeout(connectionTimeoutMultiplier));
      ws2 = await WebSocket.connect(uri.toString()).timeout(_shortTimeout(connectionTimeoutMultiplier));
      return VMServiceClientConnection(
        VMServiceClient(IOWebSocketChannel(ws1).cast()),
        rpc.Peer(IOWebSocketChannel(ws2).cast())..listen()
      );
    } catch (e) {
      await ws1?.close();
      await ws2?.close();

      if (timer.elapsed < _longTimeout(connectionTimeoutMultiplier) * 2) {
        _log.info('Waiting for application to start');
        await Future<void>.delayed(_pauseBetweenReconnectAttempts(connectionTimeoutMultiplier));
        return attemptConnection();
      } else {
        _log.critical(
          'Application has not started in 30 seconds. '
          'Giving up.'
        );
        rethrow;
      }
    }
  }

  return attemptConnection();
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

  /// Finds widgets whose class name matches the given string.
  SerializableFinder byType(String type) => ByType(type);

  /// Finds the back button on a Material or Cupertino page's scaffold.
  SerializableFinder pageBack() => PageBack();
}
