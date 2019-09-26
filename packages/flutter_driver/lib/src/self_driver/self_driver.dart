// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding, SemanticsHandle;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:web_socket_channel/io.dart';

import '../../driver_extension.dart';

import '../common/error.dart';

import '../driver/driver.dart' show TimelineStream;
import '../driver/timeline.dart';

export '../driver/driver.dart' show TimelineStream;

// This should be deduplicated.
const List<TimelineStream> _defaultStreams = <TimelineStream>[TimelineStream.all];

/// How long to wait before showing a message saying that
/// things seem to be taking a long time.
@visibleForTesting
const Duration kUnusuallyLongTimeout = Duration(seconds: 5);

// This should be deduplicated.
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

// This should be deduplicated.
final Logger _log = Logger('FlutterSelfDriver');

// This should be deduplicated.
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

/// Drives a Flutter Application running in the same process.
class FlutterSelfDriver {
  /// Creates a driver that uses a connection provided by the given [_peer]
  /// and [_prover].
  @visibleForTesting
  FlutterSelfDriver(this._peer, this._prober);

  // These should be deduplicated.
  static const String _setVMTimelineFlagsMethodName = 'setVMTimelineFlags';
  static const String _getVMTimelineMethodName = 'getVMTimeline';
  static const String _clearVMTimelineMethodName = 'clearVMTimeline';
  static const String _collectAllGarbageMethodName = '_collectAllGarbage';

  /// Connects to this Flutter application.
  static Future<FlutterSelfDriver> connect() async {
    final rpc.Peer peer = await _connectToObservatory();
    enableFlutterDriverExtension();
    final WidgetController prober = LiveWidgetController(WidgetsBinding.instance);
    return FlutterSelfDriver(peer, prober);
  }

  /// Connects to the observatory of this Flutter application.
  static Future<rpc.Peer> _connectToObservatory() async {
    final Uri observatoryUri = (await Service.getInfo()).serverUri;
    final List<String> pathSegments = <String>[];
    // If there's an authentication code (default), we need to add it to our path.
    if (observatoryUri.pathSegments.isNotEmpty) {
      pathSegments.add(observatoryUri.pathSegments.first);
    }
    pathSegments.add('ws');
    final Uri websocketUri =
        observatoryUri.replace(scheme: 'ws', pathSegments: pathSegments);
    final WebSocket webSocket = await WebSocket.connect(websocketUri.toString());
    final rpc.Peer peer = rpc.Peer(IOWebSocketChannel(webSocket)
        .cast(), onUnhandledError: _unhandledJsonRpcError)
      ..listen();
    return peer;
  }

  /// JSON-RPC client useful for sending raw JSON requests.
  final rpc.Peer _peer;

  /// The prober for this Flutter application.
  final WidgetController _prober;

  /// With [_frameSync] enabled, Flutter Driver will wait to perform an action
  /// until there are no pending frames in the app under test.
  bool _frameSync = true;

  // Waits until at the end of a frame the provided [condition] is [true].
  Future<void> _waitUntilFrame(bool condition(), [Completer<void> completer]) {
    completer ??= Completer<void>();
    if (!condition()) {
      SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
        _waitUntilFrame(condition, completer);
      });
    } else {
      completer.complete();
    }
    return completer.future;
  }

  /// Runs `finder` repeatedly until it finds one or more [Element]s.
  Future<Finder> _waitForElement(Finder finder) async {
    if (_frameSync) {
      await _waitUntilFrame(
          () => SchedulerBinding.instance.transientCallbackCount == 0);
    }

    await _waitUntilFrame(() => finder.evaluate().isNotEmpty);

    if (_frameSync) {
      await _waitUntilFrame(
          () => SchedulerBinding.instance.transientCallbackCount == 0);
    }

    return finder;
  }

  /// Taps at the center of the widget located by [finder].
  Future<void> tap(Finder finder, { Duration timeout }) async {
    final Finder computedFinder = await _waitForElement(finder);
    await _prober.tap(computedFinder);
  }

  /// Waits until the next [Window.onReportTimings] is called.
  ///
  /// Use this method to wait for the first frame to be rasterized during the
  /// app launch.
  Future<void> waitUntilFirstFrameRasterized() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
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
  Future<void> scroll(Finder finder, double dx, double dy, Duration duration, { int frequency = 60, Duration timeout }) async {
    final Finder target = await _waitForElement(finder);
    final int totalMoves = duration.inMicroseconds * frequency ~/ Duration.microsecondsPerSecond;
    final Offset delta = Offset(dx, dy) / totalMoves.toDouble();
    final Duration pause = duration ~/ totalMoves;
    final Offset startLocation = _prober.getCenter(target);
    Offset currentLocation = startLocation;
    final TestPointer pointer = TestPointer(1);
    final HitTestResult hitTest = HitTestResult();

    _prober.binding.hitTest(hitTest, startLocation);
    _prober.binding.dispatchEvent(pointer.down(startLocation), hitTest);
    await Future<void>.value(); // so that down and move don't happen in the same microtask
    for (int moves = 0; moves < totalMoves; moves += 1) {
      currentLocation = currentLocation + delta;
      _prober.binding.dispatchEvent(pointer.move(currentLocation), hitTest);
      await Future<void>.delayed(pause);
    }
    _prober.binding.dispatchEvent(pointer.up(), hitTest);
  }

  /// Scrolls the Scrollable ancestor of the widget located by [finder]
  /// until the widget is completely visible.
  ///
  /// If the widget located by [finder] is contained by a scrolling widget
  /// that lazily creates its children, like [ListView] or [CustomScrollView],
  /// then this method may fail because [finder] doesn't actually exist.
  /// The [scrollUntilVisible] method can be used in this case.
  Future<void> scrollIntoView(Finder finder, { double alignment = 0.0, Duration timeout }) async {
    final Finder target = await _waitForElement(finder);
    await Scrollable.ensureVisible(target.evaluate().single, duration: const Duration(milliseconds: 100), alignment: alignment ?? 0.0);
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
    Finder scrollable,
    Finder item, {
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
    _waitForElement(item).then<void>((_) { isVisible = true; });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    while (!isVisible) {
      await scroll(scrollable, dxScroll, dyScroll, const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    return scrollIntoView(item, alignment: alignment);
  }

  SemanticsHandle _semantics;
  bool get _semanticsIsEnabled => RendererBinding.instance.pipelineOwner.semanticsOwner != null;

  /// Turns semantics on or off in the Flutter app under test.
  ///
  /// Returns true when the call actually changed the state from on to off or
  /// vice versa.
  Future<bool> setSemantics(bool enabled, { Duration timeout }) async {
    final bool semanticsWasEnabled = _semanticsIsEnabled;
    if (enabled && _semantics == null) {
      _semantics = RendererBinding.instance.pipelineOwner.ensureSemantics();
      if (!semanticsWasEnabled) {
        // wait for the first frame where semantics is enabled.
        final Completer<void> completer = Completer<void>();
        SchedulerBinding.instance.addPostFrameCallback((Duration d) {
          completer.complete();
        });
        await completer.future;
      }
    } else if (!enabled && _semantics != null) {
      _semantics.dispose();
      _semantics = null;
    }
    return semanticsWasEnabled != _semanticsIsEnabled;
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

    //if (!(await _isPrecompiledMode())) {
    //  _log.warning(_kDebugWarning);
    //}
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
    _frameSync = false;
    T result;
    try {
      result = await action();
    } finally {
      _frameSync = true;
    }
    return result;
  }

  /// Force a garbage collection run in the VM.
  Future<void> forceGC() async {
    try {
      await _peer
          .sendRequest(_collectAllGarbageMethodName, <String, String>{
            'isolateId': Service.getIsolateID(Isolate.current),
          });
    } catch (error, stackTrace) {
      throw DriverError(
        'Failed to force a GC due to remote error',
        error,
        stackTrace,
      );
    }
  }

  /// Creates a finder for the back button.
  Finder createPageBackFinder() {
    return find.byElementPredicate((Element element) {
      final Widget widget = element.widget;
      if (widget is Tooltip)
        return widget.message == 'Back';
      if (widget is CupertinoNavigationBarBackButton)
        return true;
      return false;
    }, description: 'Material or Cupertino back button');
  }
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
