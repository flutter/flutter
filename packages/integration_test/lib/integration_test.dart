// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart' as vm_io;

import '_callback_io.dart' if (dart.library.html) '_callback_web.dart' as driver_actions;
import '_extension_io.dart' if (dart.library.html) '_extension_web.dart';
import 'common.dart';

const String _success = 'success';

/// A subclass of [LiveTestWidgetsFlutterBinding] that reports tests results
/// on a channel to adapt them to native instrumentation test format.
class IntegrationTestWidgetsFlutterBinding extends LiveTestWidgetsFlutterBinding implements IntegrationTestResults {
  /// Sets up a listener to report that the tests are finished when everything is
  /// torn down.
  IntegrationTestWidgetsFlutterBinding() {
    // TODO(jackson): Report test results as they arrive
    tearDownAll(() async {
      try {
        // For web integration tests we are not using the
        // `plugins.flutter.io/integration_test`. Mark the tests as complete
        // before invoking the channel.
        if (kIsWeb) {
          if (!_allTestsPassed.isCompleted) {
            _allTestsPassed.complete(true);
          }
        }
        callbackManager.cleanup();
        await _channel.invokeMethod<void>(
          'allTestsFinished',
          <String, dynamic>{
            'results': results.map((String name, Object result) {
              if (result is Failure) {
                return MapEntry<String, dynamic>(name, result.details);
              }
              return MapEntry<String, Object>(name, result);
            })
          },
        );
      } on MissingPluginException {
        print('Warning: integration_test test plugin was not detected.');
      }
      if (!_allTestsPassed.isCompleted) {
        _allTestsPassed.complete(true);
      }
    });

    // TODO(jackson): Report the results individually instead of all at once
    // See https://github.com/flutter/flutter/issues/38985
    final TestExceptionReporter oldTestExceptionReporter = reportTestException;
    reportTestException =
        (FlutterErrorDetails details, String testDescription) {
      results[testDescription] = Failure(testDescription, details.toString());
      if (!_allTestsPassed.isCompleted) {
        _allTestsPassed.complete(false);
      }
      oldTestExceptionReporter(details, testDescription);
    };
  }

  @override
  bool get overrideHttpClient => false;

  @override
  bool get registerTestTextInput => false;

  Size _surfaceSize;

  // This flag is used to print warning messages when tracking performance
  // under debug mode.
  static bool _firstRun = false;

  /// Artificially changes the surface size to `size` on the Widget binding,
  /// then flushes microtasks.
  ///
  /// Set to null to use the default surface size.
  @override
  Future<void> setSurfaceSize(Size size) {
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
  ViewConfiguration createViewConfiguration() {
    final double devicePixelRatio = window.devicePixelRatio;
    final Size size = _surfaceSize ?? window.physicalSize / devicePixelRatio;
    return TestViewConfiguration(
      size: size,
      window: window,
    );
  }

  @override
  Completer<bool> get allTestsPassed => _allTestsPassed;
  final Completer<bool> _allTestsPassed = Completer<bool>();

  @override
  List<Failure> get failureMethodsDetails => _failures;

  /// Similar to [WidgetsFlutterBinding.ensureInitialized].
  ///
  /// Returns an instance of the [IntegrationTestWidgetsFlutterBinding], creating and
  /// initializing it if necessary.
  static WidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null) {
      IntegrationTestWidgetsFlutterBinding();
    }
    assert(WidgetsBinding.instance is IntegrationTestWidgetsFlutterBinding);
    return WidgetsBinding.instance;
  }

  static const MethodChannel _channel =
      MethodChannel('plugins.flutter.io/integration_test');

  /// Test results that will be populated after the tests have completed.
  ///
  /// Keys are the test descriptions, and values are either [_success] or
  /// a [Failure].
  @visibleForTesting
  Map<String, Object> results = <String, Object>{};

  List<Failure> get _failures => results.values.whereType<Failure>().toList();

  /// The extra data for the reported result.
  ///
  /// The values in `reportData` must be json-serializable objects or `null`.
  /// If it's `null`, no extra data is attached to the result.
  ///
  /// The default value is `null`.
  @override
  Map<String, dynamic> reportData;

  /// Manages callbacks received from driver side and commands send to driver
  /// side.
  final CallbackManager callbackManager = driver_actions.callbackManager;

  /// Taking a screenshot.
  ///
  /// Called by test methods. Implementation differs for each platform.
  Future<void> takeScreenshot(String screenshotName) async {
    await callbackManager.takeScreenshot(screenshotName);
  }

  /// The callback function to response the driver side input.
  @visibleForTesting
  Future<Map<String, dynamic>> callback(Map<String, String> params) async {
    return await callbackManager.callback(
        params, this /* as IntegrationTestResults */);
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
    Future<void> testBody(),
    VoidCallback invariantTester, {
    String description = '',
    Duration timeout,
  }) async {
    await super.runTest(
      testBody,
      invariantTester,
      description: description,
      timeout: timeout,
    );
    results[description] ??= _success;
  }

  vm.VmService _vmService;

  /// Initialize the [vm.VmService] settings for the timeline.
  @visibleForTesting
  Future<void> enableTimeline({
    List<String> streams = const <String>['all'],
    @visibleForTesting vm.VmService vmService,
  }) async {
    assert(streams != null);
    assert(streams.isNotEmpty);
    if (vmService != null) {
      _vmService = vmService;
    }
    if (_vmService == null) {
      final developer.ServiceProtocolInfo info =
          await developer.Service.getInfo();
      assert(info.serverUri != null);
      _vmService = await vm_io.vmServiceConnectUri(
        'ws://localhost:${info.serverUri.port}${info.serverUri.path}ws',
      );
    }
    await _vmService.setVMTimelineFlags(streams);
  }

  /// Runs [action] and returns a [vm.Timeline] trace for it.
  ///
  /// Waits for the `Future` returned by [action] to complete prior to stopping
  /// the trace.
  ///
  /// The `streams` parameter limits the recorded timeline event streams to only
  /// the ones listed. By default, all streams are recorded.
  /// See `timeline_streams` in
  /// [Dart-SDK/runtime/vm/timeline.cc](https://github.com/dart-lang/sdk/blob/master/runtime/vm/timeline.cc)
  ///
  /// If [retainPriorEvents] is true, retains events recorded prior to calling
  /// [action]. Otherwise, prior events are cleared before calling [action]. By
  /// default, prior events are cleared.
  Future<vm.Timeline> traceTimeline(
    Future<dynamic> action(), {
    List<String> streams = const <String>['all'],
    bool retainPriorEvents = false,
  }) async {
    await enableTimeline(streams: streams);
    if (retainPriorEvents) {
      await action();
      return await _vmService.getVMTimeline();
    }

    await _vmService.clearVMTimeline();
    final vm.Timestamp startTime = await _vmService.getVMTimelineMicros();
    await action();
    final vm.Timestamp endTime = await _vmService.getVMTimelineMicros();
    return await _vmService.getVMTimeline(
      timeOriginMicros: startTime.timestamp,
      timeExtentMicros: endTime.timestamp,
    );
  }

  /// This is a convenience wrap of [traceTimeline] and send the result back to
  /// the host for the [flutter_driver] style tests.
  ///
  /// This records the timeline during `action` and adds the result to
  /// [reportData] with `reportKey`. The [reportData] contains extra information
  /// from the test other than test success/fail. It will be passed back to the
  /// host and be processed by the [ResponseDataCallback] defined in
  /// [integration_test_driver.integrationDriver]. By default it will be written
  /// to `build/integration_response_data.json` with the key `timeline`.
  ///
  /// For tests with multiple calls of this method, `reportKey` needs to be a
  /// unique key, otherwise the later result will override earlier one.
  ///
  /// The `streams` and `retainPriorEvents` parameters are passed as-is to
  /// [traceTimeline].
  Future<void> traceAction(
    Future<dynamic> action(), {
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
    reportData[reportKey] = timeline.toJson();
  }

  /// Watches the [FrameTiming] during `action` and report it to the binding
  /// with key `reportKey`.
  ///
  /// This can be used to implement performance tests previously using
  /// [traceAction] and [TimelineSummary] from [flutter_driver]
  Future<void> watchPerformance(
    Future<void> action(), {
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
    // TODO(CareF): remove this when flush FrameTiming is readly in engine.
    //              See https://github.com/flutter/flutter/issues/64808
    //              and https://github.com/flutter/flutter/issues/67593
    Future<void> delayForFrameTimings() => Future<void>.delayed(const Duration(seconds: 2));

    await delayForFrameTimings(); // flush old FrameTimings
    final List<FrameTiming> frameTimings = <FrameTiming>[];
    final TimingsCallback watcher = frameTimings.addAll;
    addTimingsCallback(watcher);
    await action();
    await delayForFrameTimings(); // make sure all FrameTimings are reported
    removeTimingsCallback(watcher);
    final FrameTimingSummarizer frameTimes =
        FrameTimingSummarizer(frameTimings);
    reportData ??= <String, dynamic>{};
    reportData[reportKey] = frameTimes.summary;
  }

  @override
  Timeout get defaultTestTimeout => _defaultTestTimeout ?? super.defaultTestTimeout;

  /// Configures the default timeout for [testWidgets].
  ///
  /// See [TestWidgetsFlutterBinding.defaultTestTimeout] for more details.
  set defaultTestTimeout(Timeout timeout) => _defaultTestTimeout = timeout;
  Timeout _defaultTestTimeout;

  @override
  void attachRootWidget(Widget rootWidget) {
    // This is a workaround where screenshots of root widgets have incorrect
    // bounds.
    // TODO(jiahaog): Remove when https://github.com/flutter/flutter/issues/66006 is fixed.
    super.attachRootWidget(RepaintBoundary(child: rootWidget));
  }
}
