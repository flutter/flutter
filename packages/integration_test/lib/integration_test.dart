// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter_driver/flutter_driver.dart';
/// @docImport 'package:flutter_driver/flutter_driver.dart' as flutter_driver;
///
/// @docImport 'integration_test_driver_extended.dart';
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show HttpClient, SocketException, WebSocket;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'common.dart';
import 'src/callback.dart' as driver_actions;
import 'src/channel.dart';
import 'src/extension.dart';

export 'src/vm_service_golden_client.dart';

const String _success = 'success';

/// Whether results should be reported to the native side over the method
/// channel.
///
/// This is enabled by default for use by native test frameworks like Android
/// instrumentation or XCTest. When running with the Flutter Tool through
/// `flutter test integration_test` though, it will be disabled as the Flutter
/// tool will be responsible for collection of test results.
const bool _shouldReportResultsToNative = bool.fromEnvironment(
  'INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE',
  defaultValue: true,
);

/// A subclass of [LiveTestWidgetsFlutterBinding] that reports tests results
/// on a channel to adapt them to native instrumentation test format.
class IntegrationTestWidgetsFlutterBinding extends LiveTestWidgetsFlutterBinding
    implements IntegrationTestResults {
  /// Sets up a listener to report that the tests are finished when everything is
  /// torn down.
  IntegrationTestWidgetsFlutterBinding() {
    tearDownAll(() async {
      if (!_allTestsPassed.isCompleted) {
        _allTestsPassed.complete(failureMethodsDetails.isEmpty);
      }
      callbackManager.cleanup();

      // TODO(jiahaog): Print the message directing users to run with
      // `flutter test` when Web is supported.
      if (!_shouldReportResultsToNative || kIsWeb) {
        return;
      }

      try {
        await integrationTestChannel.invokeMethod<void>('allTestsFinished', <String, dynamic>{
          'results': results.map<String, dynamic>((String name, Object result) {
            if (result is Failure) {
              return MapEntry<String, dynamic>(name, result.details);
            }
            return MapEntry<String, Object>(name, result);
          }),
        });
      } on MissingPluginException {
        debugPrint(r'''
Warning: integration_test plugin was not detected.

If you're running the tests with `flutter drive`, please make sure your tests
are in the `integration_test/` directory of your package and use
`flutter test $path_to_test` to run it instead.

If you're running the tests with Android instrumentation or XCTest, this means
that you are not capturing test results properly! See the following link for
how to set up the integration_test plugin:

https://docs.flutter.dev/testing/integration-tests
''');
      }
    });

    final TestExceptionReporter oldTestExceptionReporter = reportTestException;
    reportTestException = (FlutterErrorDetails details, String testDescription) {
      results[testDescription] = Failure(testDescription, details.toString());
      oldTestExceptionReporter(details, testDescription);
    };
  }

  @override
  bool get overrideHttpClient => false;

  @override
  bool get registerTestTextInput => false;

  Size? _surfaceSize;

  // This flag is used to print warning messages when tracking performance
  // under debug mode.
  static bool _firstRun = false;

  @override
  Future<void> setSurfaceSize(Size? size) {
    return TestAsyncUtils.guard<void>(() async {
      assert(inTest);
      if (_surfaceSize == size) {
        return;
      }
      _surfaceSize = size;
      handleMetricsChanged();
    });
  }

  @override
  ViewConfiguration createViewConfigurationFor(RenderView renderView) {
    final FlutterView view = renderView.flutterView;
    final Size? surfaceSize = view == platformDispatcher.implicitView ? _surfaceSize : null;
    return TestViewConfiguration.fromView(
      size: surfaceSize ?? view.physicalSize / view.devicePixelRatio,
      view: view,
    );
  }

  @override
  Completer<bool> get allTestsPassed => _allTestsPassed;
  final Completer<bool> _allTestsPassed = Completer<bool>();

  @override
  List<Failure> get failureMethodsDetails => results.values.whereType<Failure>().toList();

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
  }

  /// The singleton instance of this object.
  ///
  /// Provides access to the features exposed by this class. The binding must
  /// be initialized before using this getter; this is typically done by calling
  /// [IntegrationTestWidgetsFlutterBinding.ensureInitialized].
  static IntegrationTestWidgetsFlutterBinding get instance => BindingBase.checkInstance(_instance);
  static IntegrationTestWidgetsFlutterBinding? _instance;

  /// Returns an instance of the [IntegrationTestWidgetsFlutterBinding], creating and
  /// initializing it if necessary.
  ///
  /// See also:
  ///
  ///  * [WidgetsFlutterBinding.ensureInitialized], the equivalent in the widgets framework.
  static IntegrationTestWidgetsFlutterBinding ensureInitialized() {
    if (_instance == null) {
      IntegrationTestWidgetsFlutterBinding();
    }
    return _instance!;
  }

  /// Test results that will be populated after the tests have completed.
  ///
  /// Keys are the test descriptions, and values are either [_success] or
  /// a [Failure].
  @visibleForTesting
  Map<String, Object> results = <String, Object>{};

  /// The extra data for the reported result.
  ///
  /// The values in `reportData` must be json-serializable objects or `null`.
  /// If it's `null`, no extra data is attached to the result.
  ///
  /// The default value is `null`.
  @override
  Map<String, dynamic>? reportData;

  /// Manages callbacks received from driver side and commands send to driver
  /// side.
  final CallbackManager callbackManager = driver_actions.callbackManager;

  /// Takes a screenshot.
  ///
  /// On Android, you need to call `convertFlutterSurfaceToImage()`, and
  /// pump a frame before taking a screenshot.
  Future<List<int>> takeScreenshot(String screenshotName, [Map<String, Object?>? args]) async {
    reportData ??= <String, dynamic>{};
    reportData!['screenshots'] ??= <dynamic>[];
    final Map<String, dynamic> data = await callbackManager.takeScreenshot(screenshotName, args);
    assert(data.containsKey('bytes'));

    (reportData!['screenshots']! as List<dynamic>).add(data);
    return data['bytes']! as List<int>;
  }

  /// Web only. Performs [actions] in order as a single real browser pointer
  /// sequence using WebDriver, and completes once the browser has dispatched
  /// every event in the sequence.
  ///
  /// Each [WebDriverPointerAction.move] position in [actions] is a logical
  /// position in [view], such as the one returned by [WidgetTester.getCenter].
  /// If [view] is null, the implicit view is used. During a move with a
  /// non-zero `duration`, the browser dispatches intermediate `pointermove`
  /// events along the way. See [WebDriverPointerAction.move].
  ///
  /// Mouse buttons pressed with [WebDriverPointerAction.down] remain pressed
  /// across calls until released with [WebDriverPointerAction.up], so a test
  /// can split a drag across multiple calls to assert on intermediate state.
  ///
  /// ```dart
  /// final Offset start = tester.getCenter(find.byKey(dragHandleKey));
  /// final Offset end = start + const Offset(200, 0);
  /// await binding.webDriverPointerActions(<WebDriverPointerAction>[
  ///   WebDriverPointerAction.move(start.dx, start.dy),
  ///   const WebDriverPointerAction.down(),
  ///   WebDriverPointerAction.move(
  ///     end.dx,
  ///     end.dy,
  ///     duration: const Duration(milliseconds: 300),
  ///   ),
  ///   const WebDriverPointerAction.up(),
  /// ]);
  /// ```
  ///
  /// Unlike [WidgetTester] gesture helpers, which dispatch synthetic pointer
  /// events directly to Flutter's gesture system, the pointer sequence goes
  /// through the browser's own hit testing and event dispatch. This makes it
  /// possible to test interactions with platform views such as
  /// [HtmlElementView], for example an `<iframe>`'s mouse listeners, which
  /// synthetic Flutter pointer events never reach. DOM listeners run before
  /// the returned future completes, so their effects can be asserted
  /// immediately after awaiting this method.
  ///
  /// {@template flutter.integration_test.webDriverPointerActions.devicePointerEvents}
  /// This method does not modify [shouldPropagateDevicePointerEvents].
  /// Browser pointer events arrive in the test binding as
  /// [TestBindingEventSource.device] events, which the binding ignores by
  /// default. To assert on Flutter widgets reacting to them (for example a
  /// [GestureDetector], a [MouseRegion], or a button's `onPressed`), set
  /// [shouldPropagateDevicePointerEvents] to true before calling this method,
  /// and [WidgetTester.pump] afterwards to process the resulting frame.
  ///
  /// When semantics are enabled, the browser may hit test the semantics DOM
  /// node of a widget instead of the Flutter view, and the widget may then
  /// react through a semantics action regardless of
  /// [shouldPropagateDevicePointerEvents]. To test raw pointer delivery, run
  /// the test with semantics disabled (for example, `semanticsEnabled: false`
  /// in [testWidgets]).
  /// {@endtemplate}
  ///
  /// Only works on the web when tests are run via the `flutter drive` command
  /// with a driver that uses [integrationDriver] from
  /// `integration_test_driver_extended.dart`. Completes with an
  /// [UnsupportedError] on other platforms, an [ArgumentError] if [actions] is
  /// empty, any move coordinate or resulting viewport coordinate is not finite,
  /// or any duration is negative, a [StateError] if [view] is null and there
  /// is no implicit view, or an error if the driver fails to perform the
  /// actions.
  Future<void> webDriverPointerActions(
    List<WebDriverPointerAction> actions, {
    FlutterView? view,
  }) async {
    if (actions.isEmpty) {
      throw ArgumentError.value(actions, 'actions', 'must not be empty');
    }
    for (final action in actions) {
      if (action.type == WebDriverPointerActionType.move &&
          (!action.x!.isFinite || !action.y!.isFinite)) {
        throw ArgumentError.value(
          action,
          'actions',
          'move coordinates must be finite positions in the view',
        );
      }
      if (action.duration != null && action.duration!.isNegative) {
        throw ArgumentError.value(action, 'actions', 'duration must not be negative');
      }
    }
    final FlutterView? targetView = view ?? platformDispatcher.implicitView;
    if (targetView == null) {
      throw StateError(
        'webDriverPointerActions requires a view, but no view was provided and there is no implicit view.',
      );
    }
    final Offset origin = driver_actions.viewportOrigin(targetView);
    final viewportActions = <WebDriverPointerAction>[
      for (final WebDriverPointerAction action in actions)
        if (action.type == WebDriverPointerActionType.move)
          _toViewportMove(action, origin)
        else
          action,
    ];
    await callbackManager.pointerActions(viewportActions);
  }

  static WebDriverPointerAction _toViewportMove(WebDriverPointerAction action, Offset origin) {
    final double x = action.x! + origin.dx;
    final double y = action.y! + origin.dy;
    // Non-finite coordinates cannot be encoded for the driver and would leave
    // the command waiting for a reply forever.
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError.value(action, 'actions', 'resulting viewport position must be finite');
    }
    return WebDriverPointerAction.move(x, y, duration: action.duration!);
  }

  /// Web only. Performs a real browser pointer click at [position] using
  /// WebDriver, and completes once the browser has dispatched the click.
  ///
  /// [position] is a logical position in [view], such as the one returned by
  /// [WidgetTester.getCenter]. If [view] is null, the implicit view is used.
  ///
  /// This is a convenience wrapper around [webDriverPointerActions] that moves
  /// to [position] and presses and releases [WebDriverMouseButton.primary].
  /// For hovers, drags, or secondary-button clicks, call
  /// [webDriverPointerActions] directly.
  ///
  /// Unlike [WidgetTester.tap], which dispatches synthetic pointer events
  /// directly to Flutter's gesture system, the click goes through the
  /// browser's own hit testing and event dispatch. This makes it possible to
  /// test interactions with platform views such as [HtmlElementView], for
  /// example an `<iframe>`'s click listeners, which synthetic Flutter pointer
  /// events never reach. DOM listeners run before the returned future
  /// completes, so their effects can be asserted immediately after awaiting
  /// this method.
  ///
  /// {@macro flutter.integration_test.webDriverPointerActions.devicePointerEvents}
  ///
  /// Only works on the web when tests are run via the `flutter drive` command
  /// with a driver that uses [integrationDriver] from
  /// `integration_test_driver_extended.dart`. Completes with an
  /// [UnsupportedError] on other platforms, an [ArgumentError] if [position]
  /// or the resulting viewport position is not finite, a [StateError] if [view]
  /// is null and there is no implicit view, or an error if the driver fails
  /// to perform the click.
  Future<void> webDriverClick(Offset position, {FlutterView? view}) {
    return webDriverPointerActions(<WebDriverPointerAction>[
      WebDriverPointerAction.move(position.dx, position.dy),
      const WebDriverPointerAction.down(),
      const WebDriverPointerAction.up(),
    ], view: view);
  }

  /// Android only. Converts the Flutter surface to an image view.
  /// Be aware that if you are conducting a perf test, you may not want to call
  /// this method since the this is an expensive operation that affects the
  /// rendering of a Flutter app.
  ///
  /// Once the screenshot is taken, call `revertFlutterImage()` to restore
  /// the original Flutter surface.
  Future<void> convertFlutterSurfaceToImage() async {
    await callbackManager.convertFlutterSurfaceToImage();
  }

  /// The callback function to response the driver side input.
  @visibleForTesting
  Future<Map<String, dynamic>> callback(Map<String, String> params) async {
    return callbackManager.callback(params, this /* as IntegrationTestResults */);
  }

  // Emulates the Flutter driver extension, returning 'pass' or 'fail'.
  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    if (kIsWeb) {
      registerWebServiceExtension(callback);
    }

    registerServiceExtension(name: 'driver', callback: callback);
  }

  @override
  Future<void> runTest(
    Future<void> Function() testBody,
    VoidCallback invariantTester, {
    String description = '',
    @Deprecated(
      'This parameter has no effect. Use the `timeout` parameter on `testWidgets` instead. '
      'This feature was deprecated after v2.6.0-1.0.pre.',
    )
    Duration? timeout,
  }) async {
    await super.runTest(testBody, invariantTester, description: description);
    results[description] ??= _success;
  }

  // Do not paint a description label because it could show up in screenshots
  // of the integration test.
  @override
  void setLabel(String value) {}

  vm.VmService? _vmService;

  /// Initialize the [vm.VmService] settings for the timeline.
  @visibleForTesting
  Future<void> enableTimeline({
    List<String> streams = const <String>['all'],
    @visibleForTesting vm.VmService? vmService,
    @visibleForTesting HttpClient? httpClient,
  }) async {
    assert(streams.isNotEmpty);
    if (vmService != null) {
      _vmService = vmService;
    }
    if (_vmService == null) {
      final developer.ServiceProtocolInfo info = await developer.Service.getInfo();
      assert(info.serverUri != null);
      final address = 'ws://localhost:${info.serverUri!.port}${info.serverUri!.path}ws';
      try {
        _vmService = await _vmServiceConnectUri(address, httpClient: httpClient);
      } on SocketException catch (e, s) {
        throw StateError(
          'Failed to connect to VM Service at $address.\n'
          'This may happen if DDS is enabled. If this test was launched via '
          '`flutter drive`, try adding `--no-dds`.\n'
          'The original exception was:\n'
          '$e\n$s',
        );
      }
    }
    await _vmService!.setVMTimelineFlags(streams);
  }

  /// Runs [action] and returns a [vm.Timeline] trace for it.
  ///
  /// Waits for the `Future` returned by [action] to complete prior to stopping
  /// the trace.
  ///
  /// The `streams` parameter limits the recorded timeline event streams to only
  /// the ones listed. By default, all streams are recorded.
  /// See `timeline_streams` in
  /// [Dart-SDK/runtime/vm/timeline.cc](https://github.com/dart-lang/sdk/blob/main/runtime/vm/timeline.cc)
  ///
  /// If [retainPriorEvents] is true, retains events recorded prior to calling
  /// [action]. Otherwise, prior events are cleared before calling [action]. By
  /// default, prior events are cleared.
  Future<vm.Timeline> traceTimeline(
    Future<dynamic> Function() action, {
    List<String> streams = const <String>['all'],
    bool retainPriorEvents = false,
  }) async {
    await enableTimeline(streams: streams);
    if (retainPriorEvents) {
      await action();
      return _vmService!.getVMTimeline();
    }

    await _vmService!.clearVMTimeline();
    final vm.Timestamp startTime = await _vmService!.getVMTimelineMicros();
    await action();
    final vm.Timestamp endTime = await _vmService!.getVMTimelineMicros();
    return _vmService!.getVMTimeline(
      timeOriginMicros: startTime.timestamp,
      timeExtentMicros: endTime.timestamp,
    );
  }

  /// This is a convenience method that calls [traceTimeline] and sends the
  /// result back to the host for the [flutter_driver] style tests.
  ///
  /// This records the timeline during `action` and adds the result to
  /// [reportData] with `reportKey`. The [reportData] contains extra information
  /// from the test other than test success/fail. It will be passed back to the
  /// host and be processed by the [ResponseDataCallback] defined in
  /// [integrationDriver]. By default it will be written to
  /// `build/integration_response_data.json` with the key `timeline`.
  ///
  /// For tests with multiple calls of this method, `reportKey` needs to be a
  /// unique key, otherwise the later result will override earlier one. Tests
  /// that call this multiple times must also provide a custom
  /// [ResponseDataCallback] to decide where and how to write the output
  /// timelines. For example,
  ///
  /// ```dart
  /// import 'package:integration_test/integration_test_driver.dart';
  ///
  /// Future<void> main() {
  ///   return integrationDriver(
  ///     responseDataCallback: (Map<String, dynamic>? data) async {
  ///       if (data != null) {
  ///         for (final MapEntry<String, dynamic> entry in data.entries) {
  ///           print('Writing ${entry.key} to the disk.');
  ///           await writeResponseData(
  ///             entry.value as Map<String, dynamic>,
  ///             testOutputFilename: entry.key,
  ///           );
  ///         }
  ///       }
  ///     },
  ///   );
  /// }
  /// ```
  ///
  /// The `streams` and `retainPriorEvents` parameters are passed as-is to
  /// [traceTimeline].
  Future<void> traceAction(
    Future<dynamic> Function() action, {
    List<String> streams = const <String>['all'],
    bool retainPriorEvents = false,
    String reportKey = 'timeline',
  }) async {
    final vm.Timeline timeline = await traceTimeline(
      action,
      streams: streams,
      retainPriorEvents: retainPriorEvents,
    );
    reportData ??= <String, dynamic>{};
    reportData![reportKey] = timeline.toJson();
  }

  Future<_GarbageCollectionInfo> _runAndGetGCInfo(Future<void> Function() action) async {
    if (kIsWeb) {
      await action();
      return const _GarbageCollectionInfo();
    }

    final vm.Timeline timeline = await traceTimeline(action, streams: <String>['GC']);

    final int oldGenGCCount = timeline.traceEvents!.where((vm.TimelineEvent event) {
      return event.json!['cat'] == 'GC' && event.json!['name'] == 'CollectOldGeneration';
    }).length;
    final int newGenGCCount = timeline.traceEvents!.where((vm.TimelineEvent event) {
      return event.json!['cat'] == 'GC' && event.json!['name'] == 'CollectNewGeneration';
    }).length;
    return _GarbageCollectionInfo(oldCount: oldGenGCCount, newCount: newGenGCCount);
  }

  /// Watches the [FrameTiming] during `action` and report it to the binding
  /// with key `reportKey`.
  ///
  /// This can be used to implement performance tests previously using
  /// [traceAction] and [TimelineSummary] from [flutter_driver]
  Future<void> watchPerformance(
    Future<void> Function() action, {
    String reportKey = 'performance',
  }) async {
    assert(() {
      if (_firstRun) {
        debugPrint(kDebugWarning);
        _firstRun = false;
      }
      return true;
    }());

    // The engine could batch FrameTimings and send them only once per second.
    // Delay for a sufficient time so either old FrameTimings are flushed and not
    // interfering our measurements here, or new FrameTimings are all reported.
    // TODO(CareF): remove this when flush FrameTiming is readily in engine.
    //              See https://github.com/flutter/flutter/issues/64808
    //              and https://github.com/flutter/flutter/issues/67593
    final frameTimings = <FrameTiming>[];
    Future<void> delayForFrameTimings() async {
      var count = 0;
      while (frameTimings.isEmpty) {
        count++;
        await Future<void>.delayed(const Duration(seconds: 2));
        if (count > 20) {
          debugPrint('delayForFrameTimings is taking longer than expected...');
        }
      }
    }

    await Future<void>.delayed(const Duration(seconds: 2)); // flush old FrameTimings
    final TimingsCallback watcher = frameTimings.addAll;
    addTimingsCallback(watcher);
    final _GarbageCollectionInfo gcInfo = await _runAndGetGCInfo(action);

    await delayForFrameTimings(); // make sure all FrameTimings are reported
    removeTimingsCallback(watcher);

    final frameTimes = FrameTimingSummarizer(
      frameTimings,
      newGenGCCount: gcInfo.newCount,
      oldGenGCCount: gcInfo.oldCount,
    );
    reportData ??= <String, dynamic>{};
    reportData![reportKey] = frameTimes.summary;
  }

  @override
  Timeout defaultTestTimeout = Timeout.none;

  @override
  void reportExceptionNoticed(FlutterErrorDetails exception) {
    // This method is called to log errors as they happen, and they will also
    // be eventually logged again at the end of the tests. The superclass
    // behavior is specific to the "live" execution semantics of
    // [LiveTestWidgetsFlutterBinding] so users don't have to wait until tests
    // finish to see the stack traces.
    //
    // Disable this because Integration Tests follow the semantics of
    // [AutomatedTestWidgetsFlutterBinding] that does not log the stack traces
    // live, and avoids the doubly logged stack trace.
    // TODO(jiahaog): Integration test binding should not inherit from
    // `LiveTestWidgetsFlutterBinding` https://github.com/flutter/flutter/issues/81534
  }
}

@immutable
class _GarbageCollectionInfo {
  const _GarbageCollectionInfo({this.oldCount = -1, this.newCount = -1});

  final int oldCount;
  final int newCount;
}

// Connect to the given uri and return a new [VmService] instance.
//
// Copied from vm_service_io so that we can pass a custom [HttpClient] for
// testing. Currently, the WebSocket API reuses an HttpClient that
// is created before the test can change the HttpOverrides.
Future<vm.VmService> _vmServiceConnectUri(String wsUri, {HttpClient? httpClient}) async {
  final WebSocket socket = await WebSocket.connect(wsUri, customClient: httpClient);
  final controller = StreamController<dynamic>();
  final streamClosedCompleter = Completer<void>();

  socket.listen(
    (dynamic data) => controller.add(data),
    onDone: () => streamClosedCompleter.complete(),
  );

  return vm.VmService(
    controller.stream,
    (String message) => socket.add(message),
    disposeHandler: () => socket.close(),
    streamClosed: streamClosedCompleter.future,
  );
}
