// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/testing/async.dart';
import 'package:quiver/time.dart';
import 'package:test_api/test_api.dart' as test_package;
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:vector_math/vector_math_64.dart';

import 'goldens.dart';
import 'stack_manipulation.dart';
import 'test_async_utils.dart';
import 'test_exception_reporter.dart';
import 'test_text_input.dart';

/// Phases that can be reached by [WidgetTester.pumpWidget] and
/// [TestWidgetsFlutterBinding.pump].
///
/// See [WidgetsBinding.drawFrame] for a more detailed description of some of
/// these phases.
enum EnginePhase {
  /// The build phase in the widgets library. See [BuildOwner.buildScope].
  build,

  /// The layout phase in the rendering library. See [PipelineOwner.flushLayout].
  layout,

  /// The compositing bits update phase in the rendering library. See
  /// [PipelineOwner.flushCompositingBits].
  compositingBits,

  /// The paint phase in the rendering library. See [PipelineOwner.flushPaint].
  paint,

  /// The compositing phase in the rendering library. See
  /// [RenderView.compositeFrame]. This is the phase in which data is sent to
  /// the GPU. If semantics are not enabled, then this is the last phase.
  composite,

  /// The semantics building phase in the rendering library. See
  /// [PipelineOwner.flushSemantics].
  flushSemantics,

  /// The final phase in the rendering library, wherein semantics information is
  /// sent to the embedder. See [SemanticsOwner.sendSemanticsUpdate].
  sendSemanticsUpdate,
}

/// Parts of the system that can generate pointer events that reach the test
/// binding.
///
/// This is used to identify how to handle events in the
/// [LiveTestWidgetsFlutterBinding]. See
/// [TestWidgetsFlutterBinding.dispatchEvent].
enum TestBindingEventSource {
  /// The pointer event came from the test framework itself, e.g. from a
  /// [TestGesture] created by [WidgetTester.startGesture].
  test,

  /// The pointer event came from the system, presumably as a result of the user
  /// interactive directly with the device while the test was running.
  device,
}

const Size _kDefaultTestViewportSize = Size(800.0, 600.0);

/// Base class for bindings used by widgets library tests.
///
/// The [ensureInitialized] method creates (if necessary) and returns
/// an instance of the appropriate subclass.
///
/// When using these bindings, certain features are disabled. For
/// example, [timeDilation] is reset to 1.0 on initialization.
abstract class TestWidgetsFlutterBinding extends BindingBase
  with ServicesBinding,
       SchedulerBinding,
       GestureBinding,
       SemanticsBinding,
       RendererBinding,
       PaintingBinding,
       WidgetsBinding {

  /// Constructor for [TestWidgetsFlutterBinding].
  ///
  /// This constructor overrides the [debugPrint] global hook to point to
  /// [debugPrintOverride], which can be overridden by subclasses.
  TestWidgetsFlutterBinding() {
    debugPrint = debugPrintOverride;
    debugDisableShadows = disableShadows;
    debugCheckIntrinsicSizes = checkIntrinsicSizes;
  }

  /// The value to set [debugPrint] to while tests are running.
  ///
  /// This can be used to redirect console output from the framework, or to
  /// change the behavior of [debugPrint]. For example,
  /// [AutomatedTestWidgetsFlutterBinding] uses it to make [debugPrint]
  /// synchronous, disabling its normal throttling behavior.
  @protected
  DebugPrintCallback get debugPrintOverride => debugPrint;

  /// The value to set [debugDisableShadows] to while tests are running.
  ///
  /// This can be used to reduce the likelihood of golden file tests being
  /// flaky, because shadow rendering is not always deterministic. The
  /// [AutomatedTestWidgetsFlutterBinding] sets this to true, so that all tests
  /// always run with shadows disabled.
  @protected
  bool get disableShadows => false;

  /// The value to set [debugCheckIntrinsicSizes] to while tests are running.
  ///
  /// This can be used to enable additional checks. For example,
  /// [AutomatedTestWidgetsFlutterBinding] sets this to true, so that all tests
  /// always run with aggressive intrinsic sizing tests enabled.
  @protected
  bool get checkIntrinsicSizes => false;

  /// Creates and initializes the binding. This function is
  /// idempotent; calling it a second time will just return the
  /// previously-created instance.
  ///
  /// This function will use [AutomatedTestWidgetsFlutterBinding] if
  /// the test was run using `flutter test`, and
  /// [LiveTestWidgetsFlutterBinding] otherwise (e.g. if it was run
  /// using `flutter run`). (This is determined by looking at the
  /// environment variables for a variable called `FLUTTER_TEST`.)
  static WidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null) {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        AutomatedTestWidgetsFlutterBinding();
      } else {
        LiveTestWidgetsFlutterBinding();
      }
    }
    assert(WidgetsBinding.instance is TestWidgetsFlutterBinding);
    return WidgetsBinding.instance;
  }

  @override
  void initInstances() {
    timeDilation = 1.0; // just in case the developer has artificially changed it for development
    HttpOverrides.global = _MockHttpOverrides();
    _testTextInput = TestTextInput(onCleared: _resetFocusedEditable)..register();
    super.initInstances();
  }

  @override
  void initLicenses() {
    // Do not include any licenses, because we're a test, and the LICENSE file
    // doesn't get generated for tests.
  }

  /// Whether there is currently a test executing.
  bool get inTest;

  /// The number of outstanding microtasks in the queue.
  int get microtaskCount;

  /// The default test timeout for tests when using this binding.
  ///
  /// The [AutomatedTestWidgetsFlutterBinding] layers in an additional timeout
  /// mechanism beyond this, with much more aggressive timeouts. See
  /// [AutomatedTestWidgetsFlutterBinding.addTime].
  test_package.Timeout get defaultTestTimeout;

  /// The current time.
  ///
  /// In the automated test environment (`flutter test`), this is a fake clock
  /// that begins in January 2015 at the start of the test and advances each
  /// time [pump] is called with a non-zero duration.
  ///
  /// In the live testing environment (`flutter run`), this object shows the
  /// actual current wall-clock time.
  Clock get clock;

  /// Triggers a frame sequence (build/layout/paint/etc),
  /// then flushes microtasks.
  ///
  /// If duration is set, then advances the clock by that much first.
  /// Doing this flushes microtasks.
  ///
  /// The supplied EnginePhase is the final phase reached during the pump pass;
  /// if not supplied, the whole pass is executed.
  ///
  /// See also [LiveTestWidgetsFlutterBindingFramePolicy], which affects how
  /// this method works when the test is run with `flutter run`.
  Future<void> pump([ Duration duration, EnginePhase newPhase = EnginePhase.sendSemanticsUpdate ]);

  /// Runs a `callback` that performs real asynchronous work.
  ///
  /// This is intended for callers who need to call asynchronous methods where
  /// the methods spawn isolates or OS threads and thus cannot be executed
  /// synchronously by calling [pump].
  ///
  /// If `callback` completes successfully, this will return the future
  /// returned by `callback`.
  ///
  /// If `callback` completes with an error, the error will be caught by the
  /// Flutter framework and made available via [takeException], and this method
  /// will return a future that completes will `null`.
  ///
  /// Re-entrant calls to this method are not allowed; callers of this method
  /// are required to wait for the returned future to complete before calling
  /// this method again. Attempts to do otherwise will result in a
  /// [TestFailure] error being thrown.
  ///
  /// The `additionalTime` argument is used by the
  /// [AutomatedTestWidgetsFlutterBinding] implementation to increase the
  /// current timeout. See [AutomatedTestWidgetsFlutterBinding.addTime] for
  /// details. The value is ignored by the [LiveTestWidgetsFlutterBinding].
  Future<T> runAsync<T>(Future<T> callback(), {
    Duration additionalTime = const Duration(milliseconds: 250),
  });

  /// Artificially calls dispatchLocalesChanged on the Widget binding,
  /// then flushes microtasks.
  ///
  /// Passes only one single Locale. Use [setLocales] to pass a full preferred
  /// locales list.
  Future<void> setLocale(String languageCode, String countryCode) {
    return TestAsyncUtils.guard<void>(() async {
      assert(inTest);
      final Locale locale = Locale(languageCode, countryCode == '' ? null : countryCode);
      dispatchLocalesChanged(<Locale>[locale]);
    });
  }

  /// Artificially calls dispatchLocalesChanged on the Widget binding,
  /// then flushes microtasks.
  Future<void> setLocales(List<Locale> locales) {
    return TestAsyncUtils.guard<void>(() async {
      assert(inTest);
      dispatchLocalesChanged(locales);
    });
  }

  Size _surfaceSize;

  /// Artificially changes the surface size to `size` on the Widget binding,
  /// then flushes microtasks.
  ///
  /// Set to null to use the default surface size.
  Future<void> setSurfaceSize(Size size) {
    return TestAsyncUtils.guard<void>(() async {
      assert(inTest);
      if (_surfaceSize == size)
        return;
      _surfaceSize = size;
      handleMetricsChanged();
    });
  }

  @override
  ViewConfiguration createViewConfiguration() {
    final double devicePixelRatio = ui.window.devicePixelRatio;
    final Size size = _surfaceSize ?? ui.window.physicalSize / devicePixelRatio;
    return ViewConfiguration(
      size: size,
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// Acts as if the application went idle.
  ///
  /// Runs all remaining microtasks, including those scheduled as a result of
  /// running them, until there are no more microtasks scheduled. Then, runs any
  /// previously scheduled timers with zero time, and completes the returned future.
  ///
  /// May result in an infinite loop or run out of memory if microtasks continue
  /// to recursively schedule new microtasks. Will not run any timers scheduled
  /// after this method was invoked, even if they are zero-time timers.
  Future<void> idle() {
    return TestAsyncUtils.guard<void>(() {
      final Completer<void> completer = Completer<void>();
      Timer.run(() {
        completer.complete();
      });
      return completer.future;
    });
  }

  /// Convert the given point from the global coordinate system (as used by
  /// pointer events from the device) to the coordinate system used by the
  /// tests (an 800 by 600 window).
  Offset globalToLocal(Offset point) => point;

  /// Convert the given point from the coordinate system used by the tests (an
  /// 800 by 600 window) to the global coordinate system (as used by pointer
  /// events from the device).
  Offset localToGlobal(Offset point) => point;

  @override
  void dispatchEvent(PointerEvent event, HitTestResult result, {
    TestBindingEventSource source = TestBindingEventSource.device
  }) {
    assert(source == TestBindingEventSource.test);
    super.dispatchEvent(event, result);
  }

  /// A stub for the system's onscreen keyboard. Callers must set the
  /// [focusedEditable] before using this value.
  TestTextInput get testTextInput => _testTextInput;
  TestTextInput _testTextInput;

  /// The current client of the onscreen keyboard. Callers must pump
  /// an additional frame after setting this property to complete the
  /// the focus change.
  ///
  /// Instead of setting this directly, consider using
  /// [WidgetTester.showKeyboard].
  EditableTextState get focusedEditable => _focusedEditable;
  EditableTextState _focusedEditable;
  set focusedEditable(EditableTextState value) {
    if (_focusedEditable != value) {
      _focusedEditable = value;
      value?.requestKeyboard();
    }
  }

  void _resetFocusedEditable() {
    _focusedEditable = null;
  }

  /// Returns the exception most recently caught by the Flutter framework.
  ///
  /// Call this if you expect an exception during a test. If an exception is
  /// thrown and this is not called, then the exception is rethrown when
  /// the [testWidgets] call completes.
  ///
  /// If two exceptions are thrown in a row without the first one being
  /// acknowledged with a call to this method, then when the second exception is
  /// thrown, they are both dumped to the console and then the second is
  /// rethrown from the exception handler. This will likely result in the
  /// framework entering a highly unstable state and everything collapsing.
  ///
  /// It's safe to call this when there's no pending exception; it will return
  /// null in that case.
  dynamic takeException() {
    assert(inTest);
    final dynamic result = _pendingExceptionDetails?.exception;
    _pendingExceptionDetails = null;
    return result;
  }
  FlutterExceptionHandler _oldExceptionHandler;
  FlutterErrorDetails _pendingExceptionDetails;

  static const TextStyle _messageStyle = TextStyle(
    color: Color(0xFF917FFF),
    fontSize: 40.0,
  );

  static const Widget _preTestMessage = Center(
    child: Text(
      'Test starting...',
      style: _messageStyle,
      textDirection: TextDirection.ltr,
    )
  );

  static const Widget _postTestMessage = Center(
    child: Text(
      'Test finished.',
      style: _messageStyle,
      textDirection: TextDirection.ltr,
    )
  );

  /// Whether to include the output of debugDumpApp() when reporting
  /// test failures.
  bool showAppDumpInErrors = false;

  /// Call the testBody inside a [FakeAsync] scope on which [pump] can
  /// advance time.
  ///
  /// Returns a future which completes when the test has run.
  ///
  /// Called by the [testWidgets] and [benchmarkWidgets] functions to
  /// run a test.
  ///
  /// The `invariantTester` argument is called after the `testBody`'s [Future]
  /// completes. If it throws, then the test is marked as failed.
  ///
  /// The `description` is used by the [LiveTestWidgetsFlutterBinding] to
  /// show a label on the screen during the test. The description comes from
  /// the value passed to [testWidgets]. It must not be null.
  Future<void> runTest(Future<void> testBody(), VoidCallback invariantTester, { String description = '' });

  /// This is called during test execution before and after the body has been
  /// executed.
  ///
  /// It's used by [AutomatedTestWidgetsFlutterBinding] to drain the microtasks
  /// before the final [pump] that happens during test cleanup.
  void asyncBarrier() {
    TestAsyncUtils.verifyAllScopesClosed();
  }

  Zone _parentZone;

  VoidCallback _createTestCompletionHandler(String testDescription, Completer<void> completer) {
    return () {
      // This can get called twice, in the case of a Future without listeners failing, and then
      // our main future completing.
      assert(Zone.current == _parentZone);
      if (_pendingExceptionDetails != null) {
        debugPrint = debugPrintOverride; // just in case the test overrides it -- otherwise we won't see the error!
        reportTestException(_pendingExceptionDetails, testDescription);
        _pendingExceptionDetails = null;
      }
      if (!completer.isCompleted)
        completer.complete();
    };
  }

  /// Called when the framework catches an exception, even if that exception is
  /// being handled by [takeException].
  ///
  /// This is called when there is no pending exception; if multiple exceptions
  /// are thrown and [takeException] isn't used, then subsequent exceptions are
  /// logged to the console regardless (and the test will fail).
  @protected
  void reportExceptionNoticed(FlutterErrorDetails exception) {
    // By default we do nothing.
    // The LiveTestWidgetsFlutterBinding overrides this to report the exception to the console.
  }

  Future<void> _runTest(Future<void> testBody(), VoidCallback invariantTester, String description, {
    Future<void> timeout,
  }) {
    assert(description != null);
    assert(inTest);
    _oldExceptionHandler = FlutterError.onError;
    int _exceptionCount = 0; // number of un-taken exceptions
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_pendingExceptionDetails != null) {
        debugPrint = debugPrintOverride; // just in case the test overrides it -- otherwise we won't see the errors!
        if (_exceptionCount == 0) {
          _exceptionCount = 2;
          FlutterError.dumpErrorToConsole(_pendingExceptionDetails, forceReport: true);
        } else {
          _exceptionCount += 1;
        }
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        _pendingExceptionDetails = FlutterErrorDetails(
          exception: 'Multiple exceptions ($_exceptionCount) were detected during the running of the current test, and at least one was unexpected.',
          library: 'Flutter test framework'
        );
      } else {
        reportExceptionNoticed(details); // mostly this is just a hook for the LiveTestWidgetsFlutterBinding
        _pendingExceptionDetails = details;
      }
    };
    final Completer<void> testCompleter = Completer<void>();
    final VoidCallback testCompletionHandler = _createTestCompletionHandler(description, testCompleter);
    void handleUncaughtError(dynamic exception, StackTrace stack) {
      if (testCompleter.isCompleted) {
        // Well this is not a good sign.
        // Ideally, once the test has failed we would stop getting errors from the test.
        // However, if someone tries hard enough they could get in a state where this happens.
        // If we silently dropped these errors on the ground, nobody would ever know. So instead
        // we report them to the console. They don't cause test failures, but hopefully someone
        // will see them in the logs at some point.
        debugPrint = debugPrintOverride; // just in case the test overrides it -- otherwise we won't see the error!
        FlutterError.dumpErrorToConsole(FlutterErrorDetails(
          exception: exception,
          stack: _unmangle(stack),
          context: 'running a test (but after the test had completed)',
          library: 'Flutter test framework'
        ), forceReport: true);
        return;
      }
      // This is where test failures, e.g. those in expect(), will end up.
      // Specifically, runUnaryGuarded() will call this synchronously and
      // return our return value if _runTestBody fails synchronously (which it
      // won't, so this never happens), and Future will call this when the
      // Future completes with an error and it would otherwise call listeners
      // if the listener is in a different zone (which it would be for the
      // `whenComplete` handler below), or if the Future completes with an
      // error and the future has no listeners at all.
      //
      // This handler further calls the onError handler above, which sets
      // _pendingExceptionDetails. Nothing gets printed as a result of that
      // call unless we already had an exception pending, because in general
      // we want people to be able to cause the framework to report exceptions
      // and then use takeException to verify that they were really caught.
      // Now, if we actually get here, this isn't going to be one of those
      // cases. We only get here if the test has actually failed. So, once
      // we've carefully reported it, we then immediately end the test by
      // calling the testCompletionHandler in the _parentZone.
      //
      // We have to manually call testCompletionHandler because if the Future
      // library calls us, it is maybe _instead_ of calling a registered
      // listener from a different zone. In our case, that would be instead of
      // calling the whenComplete() listener below.
      //
      // We have to call it in the parent zone because if we called it in
      // _this_ zone, the test framework would find this zone was the current
      // zone and helpfully throw the error in this zone, causing us to be
      // directly called again.
      String treeDump;
      try {
        treeDump = renderViewElement?.toStringDeep() ?? '<no tree>';
      } catch (exception) {
        treeDump = '<additional error caught while dumping tree: $exception>';
      }
      final StringBuffer expectLine = StringBuffer();
      final int stackLinesToOmit = reportExpectCall(stack, expectLine);
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: _unmangle(stack),
        context: 'running a test',
        library: 'Flutter test framework',
        stackFilter: (Iterable<String> frames) {
          return FlutterError.defaultStackFilter(frames.skip(stackLinesToOmit));
        },
        informationCollector: (StringBuffer information) {
          if (stackLinesToOmit > 0)
            information.writeln(expectLine.toString());
          if (showAppDumpInErrors) {
            information.writeln('At the time of the failure, the widget tree looked as follows:');
            information.writeln('# ${treeDump.split("\n").takeWhile((String s) => s != "").join("\n# ")}');
          }
          if (description.isNotEmpty)
            information.writeln('The test description was:\n$description');
        }
      ));
      assert(_parentZone != null);
      assert(_pendingExceptionDetails != null, 'A test overrode FlutterError.onError but either failed to return it to its original state, or had unexpected additional errors that it could not handle. Typically, this is caused by using expect() before restoring FlutterError.onError.');
      _parentZone.run<void>(testCompletionHandler);
    }
    final ZoneSpecification errorHandlingZoneSpecification = ZoneSpecification(
      handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone, dynamic exception, StackTrace stack) {
        handleUncaughtError(exception, stack);
      }
    );
    _parentZone = Zone.current;
    final Zone testZone = _parentZone.fork(specification: errorHandlingZoneSpecification);
    testZone.runBinary<Future<void>, Future<void> Function(), VoidCallback>(_runTestBody, testBody, invariantTester)
      .whenComplete(testCompletionHandler);
    timeout?.catchError(handleUncaughtError);
    return testCompleter.future;
  }

  Future<void> _runTestBody(Future<void> testBody(), VoidCallback invariantTester) async {
    assert(inTest);

    runApp(Container(key: UniqueKey(), child: _preTestMessage)); // Reset the tree to a known state.
    await pump();

    final bool autoUpdateGoldensBeforeTest = autoUpdateGoldenFiles;
    final TestExceptionReporter reportTestExceptionBeforeTest = reportTestException;

    // run the test
    await testBody();
    asyncBarrier(); // drains the microtasks in `flutter test` mode (when using AutomatedTestWidgetsFlutterBinding)

    if (_pendingExceptionDetails == null) {
      // We only try to clean up and verify invariants if we didn't already
      // fail. If we got an exception already, then we instead leave everything
      // alone so that we don't cause more spurious errors.
      runApp(Container(key: UniqueKey(), child: _postTestMessage)); // Unmount any remaining widgets.
      await pump();
      invariantTester();
      _verifyAutoUpdateGoldensUnset(autoUpdateGoldensBeforeTest);
      _verifyReportTestExceptionUnset(reportTestExceptionBeforeTest);
      _verifyInvariants();
    }

    assert(inTest);
    asyncBarrier(); // When using AutomatedTestWidgetsFlutterBinding, this flushes the microtasks.
  }

  void _verifyInvariants() {
    assert(debugAssertNoTransientCallbacks(
      'An animation is still running even after the widget tree was disposed.'
    ));
    assert(debugAssertAllFoundationVarsUnset(
      'The value of a foundation debug variable was changed by the test.',
      debugPrintOverride: debugPrintOverride,
    ));
    assert(debugAssertAllGesturesVarsUnset(
      'The value of a gestures debug variable was changed by the test.',
    ));
    assert(debugAssertAllPaintingVarsUnset(
      'The value of a painting debug variable was changed by the test.',
      debugDisableShadowsOverride: disableShadows,
    ));
    assert(debugAssertAllRenderVarsUnset(
      'The value of a rendering debug variable was changed by the test.',
      debugCheckIntrinsicSizesOverride: checkIntrinsicSizes,
    ));
    assert(debugAssertAllWidgetVarsUnset(
      'The value of a widget debug variable was changed by the test.',
    ));
    assert(debugAssertAllSchedulerVarsUnset(
      'The value of a scheduler debug variable was changed by the test.',
    ));
  }

  void _verifyAutoUpdateGoldensUnset(bool valueBeforeTest) {
    assert(() {
      if (autoUpdateGoldenFiles != valueBeforeTest) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: FlutterError(
              'The value of autoUpdateGoldenFiles was changed by the test.',
          ),
          stack: StackTrace.current,
          library: 'Flutter test framework',
        ));
      }
      return true;
    }());
  }

  void _verifyReportTestExceptionUnset(TestExceptionReporter valueBeforeTest) {
    assert(() {
      if (reportTestException != valueBeforeTest) {
        // We can't report this error to their modified reporter because we
        // can't be guaranteed that their reporter will cause the test to fail.
        // So we reset the error reporter to its initial value and then report
        // this error.
        reportTestException = valueBeforeTest;
        FlutterError.reportError(FlutterErrorDetails(
          exception: FlutterError(
            'The value of reportTestException was changed by the test.',
          ),
          stack: StackTrace.current,
          library: 'Flutter test framework',
        ));
      }
      return true;
    }());
  }

  /// Called by the [testWidgets] function after a test is executed.
  void postTest() {
    assert(inTest);
    FlutterError.onError = _oldExceptionHandler;
    _pendingExceptionDetails = null;
    _parentZone = null;
  }
}

/// A variant of [TestWidgetsFlutterBinding] for executing tests in
/// the `flutter test` environment.
///
/// This binding controls time, allowing tests to verify long
/// animation sequences without having to execute them in real time.
///
/// This class assumes it is always run in checked mode (since tests are always
/// run in checked mode).
class AutomatedTestWidgetsFlutterBinding extends TestWidgetsFlutterBinding {
  @override
  void initInstances() {
    super.initInstances();
    ui.window.onBeginFrame = null;
    ui.window.onDrawFrame = null;
  }

  FakeAsync _currentFakeAsync; // set in runTest; cleared in postTest
  Completer<void> _pendingAsyncTasks;

  @override
  Clock get clock => _clock;
  Clock _clock;

  @override
  DebugPrintCallback get debugPrintOverride => debugPrintSynchronously;

  @override
  bool get disableShadows => true;

  @override
  bool get checkIntrinsicSizes => true;

  // The timeout here is absurdly high because we do our own timeout logic and
  // this is just a backstop.
  @override
  test_package.Timeout get defaultTestTimeout => const test_package.Timeout(Duration(minutes: 5));

  @override
  bool get inTest => _currentFakeAsync != null;

  @override
  int get microtaskCount => _currentFakeAsync.microtaskCount;

  @override
  Future<void> pump([ Duration duration, EnginePhase newPhase = EnginePhase.sendSemanticsUpdate ]) {
    return TestAsyncUtils.guard<void>(() {
      assert(inTest);
      assert(_clock != null);
      if (duration != null)
        _currentFakeAsync.elapse(duration);
      _phase = newPhase;
      if (hasScheduledFrame) {
        addTime(const Duration(milliseconds: 500));
        _currentFakeAsync.flushMicrotasks();
        handleBeginFrame(Duration(
          milliseconds: _clock.now().millisecondsSinceEpoch,
        ));
        _currentFakeAsync.flushMicrotasks();
        handleDrawFrame();
      }
      _currentFakeAsync.flushMicrotasks();
      return Future<void>.value();
    });
  }

  @override
  Future<T> runAsync<T>(Future<T> callback(), {
    Duration additionalTime = const Duration(milliseconds: 1000),
  }) {
    assert(additionalTime != null);
    assert(() {
      if (_pendingAsyncTasks == null)
        return true;
      throw test_package.TestFailure(
          'Reentrant call to runAsync() denied.\n'
          'runAsync() was called, then before its future completed, it '
          'was called again. You must wait for the first returned future '
          'to complete before calling runAsync() again.'
      );
    }());

    final Zone realAsyncZone = Zone.current.fork(
      specification: ZoneSpecification(
        scheduleMicrotask: (Zone self, ZoneDelegate parent, Zone zone, void f()) {
          Zone.root.scheduleMicrotask(f);
        },
        createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f()) {
          return Zone.root.createTimer(duration, f);
        },
        createPeriodicTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration period, void f(Timer timer)) {
          return Zone.root.createPeriodicTimer(period, f);
        },
      ),
    );

    addTime(additionalTime);

    return realAsyncZone.run<Future<T>>(() {
      _pendingAsyncTasks = Completer<void>();
      return callback().catchError((dynamic exception, StackTrace stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'Flutter test framework',
          context: 'while running async test code',
        ));
        return null;
      }).whenComplete(() {
        // We complete the _pendingAsyncTasks future successfully regardless of
        // whether an exception occurred because in the case of an exception,
        // we already reported the exception to FlutterError. Moreover,
        // completing the future with an error would trigger an unhandled
        // exception due to zone error boundaries.
        _pendingAsyncTasks.complete();
        _pendingAsyncTasks = null;
      });
    });
  }

  @override
  void scheduleWarmUpFrame() {
    // We override the default version of this so that the application-startup warm-up frame
    // does not schedule timers which we might never get around to running.
    handleBeginFrame(null);
    _currentFakeAsync.flushMicrotasks();
    handleDrawFrame();
    _currentFakeAsync.flushMicrotasks();
  }

  @override
  Future<void> idle() {
    final Future<void> result = super.idle();
    _currentFakeAsync.elapse(Duration.zero);
    return result;
  }

  EnginePhase _phase = EnginePhase.sendSemanticsUpdate;

  // Cloned from RendererBinding.drawFrame() but with early-exit semantics.
  @override
  void drawFrame() {
    assert(inTest);
    try {
      debugBuildingDirtyElements = true;
      buildOwner.buildScope(renderViewElement);
      if (_phase != EnginePhase.build) {
        assert(renderView != null);
        pipelineOwner.flushLayout();
        if (_phase != EnginePhase.layout) {
          pipelineOwner.flushCompositingBits();
          if (_phase != EnginePhase.compositingBits) {
            pipelineOwner.flushPaint();
            if (_phase != EnginePhase.paint) {
              renderView.compositeFrame(); // this sends the bits to the GPU
              if (_phase != EnginePhase.composite) {
                pipelineOwner.flushSemantics();
                assert(_phase == EnginePhase.flushSemantics ||
                       _phase == EnginePhase.sendSemanticsUpdate);
              }
            }
          }
        }
      }
      buildOwner.finalizeTree();
    } finally {
      debugBuildingDirtyElements = false;
    }
  }

  Duration _timeout;
  Stopwatch _timeoutStopwatch;
  Timer _timeoutTimer;
  Completer<void> _timeoutCompleter;

  void _checkTimeout(Timer timer) {
    assert(_timeoutTimer == timer);
    if (_timeoutStopwatch.elapsed > _timeout) {
      _timeoutCompleter.completeError(
        TimeoutException(
          'The test exceeded the timeout. It may have hung.\n'
          'Consider using "addTime" to increase the timeout before expensive operations.',
          _timeout,
        ),
      );
    }
  }

  /// Increase the timeout for the current test by the given duration.
  ///
  /// Tests by default time out after two seconds, but the timeout can be
  /// increased before an expensive operation to allow it to complete without
  /// hitting the test timeout.
  ///
  /// By default, each [pump] and [pumpWidget] call increases the timeout by a
  /// hundred milliseconds, and each [matchesGoldenFile] expectation increases
  /// it by several seconds.
  ///
  /// In general, unit tests are expected to run very fast, and this method is
  /// usually not necessary.
  ///
  /// The granularity of timeouts is coarse: the time is checked once per
  /// second, and only when the test is not executing. It is therefore possible
  /// for a timeout to be exceeded by hundreds of milliseconds and for the test
  /// to still succeed. If precise timing is required, it should be implemented
  /// as a part of the test rather than relying on this mechanism.
  ///
  /// See also:
  ///
  ///  * [defaultTestTimeout], the maximum that the timeout can reach.
  ///    (That timeout is implemented by the test package.)
  void addTime(Duration duration) {
    assert(_timeout != null, 'addTime can only be called during a test.');
    _timeout += duration;
  }

  @override
  Future<void> runTest(Future<void> testBody(), VoidCallback invariantTester, {
    String description = '',
    Duration timeout = const Duration(seconds: 2),
  }) {
    assert(description != null);
    assert(!inTest);
    assert(_currentFakeAsync == null);
    assert(_clock == null);

    _timeout = timeout;
    _timeoutStopwatch = Stopwatch()..start();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), _checkTimeout);
    _timeoutCompleter = Completer<void>();

    final FakeAsync fakeAsync = FakeAsync();
    _currentFakeAsync = fakeAsync; // reset in postTest
    _clock = fakeAsync.getClock(DateTime.utc(2015, 1, 1));
    Future<void> testBodyResult;
    fakeAsync.run((FakeAsync localFakeAsync) {
      assert(fakeAsync == _currentFakeAsync);
      assert(fakeAsync == localFakeAsync);
      testBodyResult = _runTest(testBody, invariantTester, description, timeout: _timeoutCompleter.future);
      assert(inTest);
    });

    return Future<void>.microtask(() async {
      // testBodyResult is a Future that was created in the Zone of the
      // fakeAsync. This means that if we await it here, it will register a
      // microtask to handle the future _in the fake async zone_. We avoid this
      // by calling '.then' in the current zone. While flushing the microtasks
      // of the fake-zone below, the new future will be completed and can then
      // be used without fakeAsync.
      final Future<void> resultFuture = testBodyResult.then<void>((_) {
        // Do nothing.
      });

      // Resolve interplay between fake async and real async calls.
      fakeAsync.flushMicrotasks();
      while (_pendingAsyncTasks != null) {
        await _pendingAsyncTasks.future;
        fakeAsync.flushMicrotasks();
      }
      return resultFuture;
    });
  }

  @override
  void asyncBarrier() {
    assert(_currentFakeAsync != null);
    _currentFakeAsync.flushMicrotasks();
    super.asyncBarrier();
  }

  @override
  void _verifyInvariants() {
    super._verifyInvariants();
    assert(
      _currentFakeAsync.periodicTimerCount == 0,
      'A periodic Timer is still running even after the widget tree was disposed.'
    );
    assert(
      _currentFakeAsync.nonPeriodicTimerCount == 0,
      'A Timer is still pending even after the widget tree was disposed.'
    );
    assert(_currentFakeAsync.microtaskCount == 0); // Shouldn't be possible.
  }

  @override
  void postTest() {
    super.postTest();
    assert(_currentFakeAsync != null);
    assert(_clock != null);
    _clock = null;
    _currentFakeAsync = null;
    _timeoutCompleter = null;
    _timeoutTimer.cancel();
    _timeoutTimer = null;
    _timeoutStopwatch = null;
    _timeout = null;
  }

}

/// Available policies for how a [LiveTestWidgetsFlutterBinding] should paint
/// frames.
///
/// These values are set on the binding's
/// [LiveTestWidgetsFlutterBinding.framePolicy] property. The default is
/// [fadePointers].
enum LiveTestWidgetsFlutterBindingFramePolicy {
  /// Strictly show only frames that are explicitly pumped. This most closely
  /// matches the behavior of tests when run under `flutter test`.
  onlyPumps,

  /// Show pumped frames, and additionally schedule and run frames to fade
  /// out the pointer crosshairs and other debugging information shown by
  /// the binding.
  ///
  /// This can result in additional frames being pumped beyond those that
  /// the test itself requests, which can cause differences in behavior.
  fadePointers,

  /// Show every frame that the framework requests, even if the frames are not
  /// explicitly pumped.
  ///
  /// This can help with orienting the developer when looking at
  /// heavily-animated situations, and will almost certainly result in
  /// additional frames being pumped beyond those that the test itself requests,
  /// which can cause differences in behavior.
  fullyLive,

  /// Ignore any request to schedule a frame.
  ///
  /// This is intended to be used by benchmarks (hence the name) that drive the
  /// pipeline directly. It tells the binding to entirely ignore requests for a
  /// frame to be scheduled, while still allowing frames that are pumped
  /// directly (invoking [Window.onBeginFrame] and [Window.onDrawFrame]) to run.
  ///
  /// The [SchedulerBinding.hasScheduledFrame] property will never be true in
  /// this mode. This can cause unexpected effects. For instance,
  /// [WidgetTester.pumpAndSettle] does not function in this mode, as it relies
  /// on the [SchedulerBinding.hasScheduledFrame] property to determine when the
  /// application has "settled".
  benchmark,
}

/// A variant of [TestWidgetsFlutterBinding] for executing tests in
/// the `flutter run` environment, on a device. This is intended to
/// allow interactive test development.
///
/// This is not the way to run a remote-control test. To run a test on
/// a device from a development computer, see the [flutter_driver]
/// package and the `flutter drive` command.
///
/// When running tests using `flutter run`, consider adding the
/// `--use-test-fonts` argument so that the fonts used match those used under
/// `flutter test`. (This forces all text to use the "Ahem" font, which is a
/// font that covers ASCII characters and gives them all the appearance of a
/// square whose size equals the font size.)
///
/// This binding overrides the default [SchedulerBinding] behavior to ensure
/// that tests work in the same way in this environment as they would under the
/// [AutomatedTestWidgetsFlutterBinding]. To override this (and see intermediate
/// frames that the test does not explicitly trigger), set [framePolicy] to
/// [LiveTestWidgetsFlutterBindingFramePolicy.fullyLive]. (This is likely to
/// make tests fail, though, especially if e.g. they test how many times a
/// particular widget was built.) The default behavior is to show pumped frames
/// and a few additional frames when pointers are triggered (to animate the
/// pointer crosshairs).
///
/// This binding does not support the [EnginePhase] argument to
/// [pump]. (There would be no point setting it to a value that
/// doesn't trigger a paint, since then you could not see anything
/// anyway.)
class LiveTestWidgetsFlutterBinding extends TestWidgetsFlutterBinding {
  @override
  void initInstances() {
    super.initInstances();
    assert(!autoUpdateGoldenFiles);
  }

  @override
  bool get inTest => _inTest;
  bool _inTest = false;

  @override
  Clock get clock => const Clock();

  @override
  int get microtaskCount {
    // The Dart SDK doesn't report this number.
    assert(false, 'microtaskCount cannot be reported when running in real time');
    return -1;
  }

  @override
  test_package.Timeout get defaultTestTimeout => test_package.Timeout.none;

  Completer<void> _pendingFrame;
  bool _expectingFrame = false;
  bool _viewNeedsPaint = false;
  bool _runningAsyncTasks = false;

  /// Whether to have [pump] with a duration only pump a single frame
  /// (as would happen in a normal test environment using
  /// [AutomatedTestWidgetsFlutterBinding]), or whether to instead
  /// pump every frame that the system requests during any
  /// asynchronous pause in the test (as would normally happen when
  /// running an application with [WidgetsFlutterBinding]).
  ///
  /// * [LiveTestWidgetsFlutterBindingFramePolicy.fadePointers] is the default
  ///   behavior, which is to only pump once, except when there has been some
  ///   activity with [TestPointer]s, in which case those are shown and may pump
  ///   additional frames.
  ///
  /// * [LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps] is the strictest
  ///   behavior, which is to only pump once. This most closely matches the
  ///   [AutomatedTestWidgetsFlutterBinding] (`flutter test`) behavior.
  ///
  /// * [LiveTestWidgetsFlutterBindingFramePolicy.fullyLive] allows all frame
  ///   requests from the engine to be serviced, even those the test did not
  ///   explicitly pump.
  ///
  /// * [LiveTestWidgetsFlutterBindingFramePolicy.benchmark] allows all frame
  ///   requests from the engine to be serviced, and allows all frame requests
  ///   that are artificially triggered to be serviced, but prevents the
  ///   framework from requesting any frames from the engine itself. The
  ///   [SchedulerBinding.hasScheduledFrame] property will never be true in this
  ///   mode. This can cause unexpected effects. For instance,
  ///   [WidgetTester.pumpAndSettle] does not function in this mode, as it
  ///   relies on the [SchedulerBinding.hasScheduledFrame] property to determine
  ///   when the application has "settled".
  ///
  /// Setting this to anything other than
  /// [LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps] means pumping extra
  /// frames, which might involve calling builders more, or calling paint
  /// callbacks more, etc, which might interfere with the test. If you know your
  /// test file wouldn't be affected by this, you can set it to
  /// [LiveTestWidgetsFlutterBindingFramePolicy.fullyLive] persistently in that
  /// particular test file. To set this to
  /// [LiveTestWidgetsFlutterBindingFramePolicy.fullyLive] while still allowing
  /// the test file to work as a normal test, add the following code to your
  /// test file at the top of your `void main() { }` function, before calls to
  /// [testWidgets]:
  ///
  /// ```dart
  /// TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  /// if (binding is LiveTestWidgetsFlutterBinding)
  ///   binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  /// ```
  LiveTestWidgetsFlutterBindingFramePolicy framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fadePointers;

  @override
  void scheduleFrame() {
    if (framePolicy == LiveTestWidgetsFlutterBindingFramePolicy.benchmark)
      return; // In benchmark mode, don't actually schedule any engine frames.
    super.scheduleFrame();
  }

  @override
  void scheduleForcedFrame() {
    if (framePolicy == LiveTestWidgetsFlutterBindingFramePolicy.benchmark)
      return; // In benchmark mode, don't actually schedule any engine frames.
    super.scheduleForcedFrame();
  }

  bool _doDrawThisFrame;

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    assert(_doDrawThisFrame == null);
    if (_expectingFrame ||
        (framePolicy == LiveTestWidgetsFlutterBindingFramePolicy.fullyLive) ||
        (framePolicy == LiveTestWidgetsFlutterBindingFramePolicy.benchmark) ||
        (framePolicy == LiveTestWidgetsFlutterBindingFramePolicy.fadePointers && _viewNeedsPaint)) {
      _doDrawThisFrame = true;
      super.handleBeginFrame(rawTimeStamp);
    } else {
      _doDrawThisFrame = false;
    }
  }

  @override
  void handleDrawFrame() {
    assert(_doDrawThisFrame != null);
    if (_doDrawThisFrame)
      super.handleDrawFrame();
    _doDrawThisFrame = null;
    _viewNeedsPaint = false;
    if (_expectingFrame) { // set during pump
      assert(_pendingFrame != null);
      _pendingFrame.complete(); // unlocks the test API
      _pendingFrame = null;
      _expectingFrame = false;
    } else {
      assert(framePolicy != LiveTestWidgetsFlutterBindingFramePolicy.benchmark);
      ui.window.scheduleFrame();
    }
  }

  @override
  void initRenderView() {
    assert(renderView == null);
    renderView = _LiveTestRenderView(
      configuration: createViewConfiguration(),
      onNeedPaint: _handleViewNeedsPaint,
    );
    renderView.scheduleInitialFrame();
  }

  @override
  _LiveTestRenderView get renderView => super.renderView;

  void _handleViewNeedsPaint() {
    _viewNeedsPaint = true;
    renderView.markNeedsPaint();
  }

  /// An object to which real device events should be routed.
  ///
  /// Normally, device events are silently dropped. However, if this property is
  /// set to a non-null value, then the events will be routed to its
  /// [HitTestDispatcher.dispatchEvent] method instead.
  ///
  /// Events dispatched by [TestGesture] are not affected by this.
  HitTestDispatcher deviceEventDispatcher;

  @override
  void dispatchEvent(PointerEvent event, HitTestResult result, {
    TestBindingEventSource source = TestBindingEventSource.device
  }) {
    switch (source) {
      case TestBindingEventSource.test:
        if (!renderView._pointers.containsKey(event.pointer)) {
          assert(event.down);
          renderView._pointers[event.pointer] = _LiveTestPointerRecord(event.pointer, event.position);
        } else {
          renderView._pointers[event.pointer].position = event.position;
          if (!event.down)
            renderView._pointers[event.pointer].decay = _kPointerDecay;
        }
        _handleViewNeedsPaint();
        super.dispatchEvent(event, result, source: source);
        break;
      case TestBindingEventSource.device:
        if (deviceEventDispatcher != null)
          deviceEventDispatcher.dispatchEvent(event, result);
        break;
    }
  }

  @override
  Future<void> pump([ Duration duration, EnginePhase newPhase = EnginePhase.sendSemanticsUpdate ]) {
    assert(newPhase == EnginePhase.sendSemanticsUpdate);
    assert(inTest);
    assert(!_expectingFrame);
    assert(_pendingFrame == null);
    return TestAsyncUtils.guard<void>(() {
      if (duration != null) {
        Timer(duration, () {
          _expectingFrame = true;
          scheduleFrame();
        });
      } else {
        _expectingFrame = true;
        scheduleFrame();
      }
      _pendingFrame = Completer<void>();
      return _pendingFrame.future;
    });
  }

  @override
  Future<T> runAsync<T>(Future<T> callback(), {
    Duration additionalTime = const Duration(milliseconds: 250),
  }) async {
    assert(() {
      if (!_runningAsyncTasks)
        return true;
      throw test_package.TestFailure(
          'Reentrant call to runAsync() denied.\n'
          'runAsync() was called, then before its future completed, it '
          'was called again. You must wait for the first returned future '
          'to complete before calling runAsync() again.'
      );
    }());

    _runningAsyncTasks = true;
    try {
      return await callback();
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Flutter test framework',
        context: 'while running async test code',
      ));
      return null;
    } finally {
      _runningAsyncTasks = false;
    }
  }

  @override
  Future<void> runTest(Future<void> testBody(), VoidCallback invariantTester, { String description = '' }) async {
    assert(description != null);
    assert(!inTest);
    _inTest = true;
    renderView._setDescription(description);
    return _runTest(testBody, invariantTester, description);
  }

  @override
  void reportExceptionNoticed(FlutterErrorDetails exception) {
    final DebugPrintCallback testPrint = debugPrint;
    debugPrint = debugPrintOverride;
    debugPrint('(The following exception is now available via WidgetTester.takeException:)');
    FlutterError.dumpErrorToConsole(exception, forceReport: true);
    debugPrint(
      '(If WidgetTester.takeException is called, the above exception will be ignored. '
      'If it is not, then the above exception will be dumped when another exception is '
      'caught by the framework or when the test ends, whichever happens first, and then '
      'the test will fail due to having not caught or expected the exception.)'
    );
    debugPrint = testPrint;
  }

  @override
  void postTest() {
    super.postTest();
    assert(!_expectingFrame);
    assert(_pendingFrame == null);
    _inTest = false;
  }

  @override
  ViewConfiguration createViewConfiguration() {
    return TestViewConfiguration(size: _surfaceSize ?? _kDefaultTestViewportSize);
  }

  @override
  Offset globalToLocal(Offset point) {
    final Matrix4 transform = renderView.configuration.toHitTestMatrix();
    final double det = transform.invert();
    assert(det != 0.0);
    final Offset result = MatrixUtils.transformPoint(transform, point);
    return result;
  }

  @override
  Offset localToGlobal(Offset point) {
    final Matrix4 transform = renderView.configuration.toHitTestMatrix();
    return MatrixUtils.transformPoint(transform, point);
  }
}

/// A [ViewConfiguration] that pretends the display is of a particular size. The
/// size is in logical pixels. The resulting ViewConfiguration maps the given
/// size onto the actual display using the [BoxFit.contain] algorithm.
class TestViewConfiguration extends ViewConfiguration {
  /// Creates a [TestViewConfiguration] with the given size. Defaults to 800x600.
  TestViewConfiguration({ Size size = _kDefaultTestViewportSize })
    : _paintMatrix = _getMatrix(size, ui.window.devicePixelRatio),
      _hitTestMatrix = _getMatrix(size, 1.0),
      super(size: size);

  static Matrix4 _getMatrix(Size size, double devicePixelRatio) {
    final double inverseRatio = devicePixelRatio / ui.window.devicePixelRatio;
    final double actualWidth = ui.window.physicalSize.width * inverseRatio;
    final double actualHeight = ui.window.physicalSize.height * inverseRatio;
    final double desiredWidth = size.width;
    final double desiredHeight = size.height;
    double scale, shiftX, shiftY;
    if ((actualWidth / actualHeight) > (desiredWidth / desiredHeight)) {
      scale = actualHeight / desiredHeight;
      shiftX = (actualWidth - desiredWidth * scale) / 2.0;
      shiftY = 0.0;
    } else {
      scale = actualWidth / desiredWidth;
      shiftX = 0.0;
      shiftY = (actualHeight - desiredHeight * scale) / 2.0;
    }
    final Matrix4 matrix = Matrix4.compose(
      Vector3(shiftX, shiftY, 0.0), // translation
      Quaternion.identity(), // rotation
      Vector3(scale, scale, 1.0) // scale
    );
    return matrix;
  }

  final Matrix4 _paintMatrix;
  final Matrix4 _hitTestMatrix;

  @override
  Matrix4 toMatrix() => _paintMatrix.clone();

  /// Provides the transformation matrix that converts coordinates in the test
  /// coordinate space to coordinates in logical pixels on the real display.
  ///
  /// This is essentially the same as [toMatrix] but ignoring the device pixel
  /// ratio.
  ///
  /// This is useful because pointers are described in logical pixels, as
  /// opposed to graphics which are expressed in physical pixels.
  Matrix4 toHitTestMatrix() => _hitTestMatrix.clone();

  @override
  String toString() => 'TestViewConfiguration';
}

const int _kPointerDecay = -2;

class _LiveTestPointerRecord {
  _LiveTestPointerRecord(
    this.pointer,
    this.position
  ) : color = HSVColor.fromAHSV(0.8, (35.0 * pointer) % 360.0, 1.0, 1.0).toColor(),
      decay = 1;
  final int pointer;
  final Color color;
  Offset position;
  int decay; // >0 means down, <0 means up, increases by one each time, removed at 0
}

class _LiveTestRenderView extends RenderView {
  _LiveTestRenderView({
    ViewConfiguration configuration,
    this.onNeedPaint,
  }) : super(configuration: configuration);

  @override
  TestViewConfiguration get configuration => super.configuration;
  @override
  set configuration(covariant TestViewConfiguration value) { super.configuration = value; }

  final VoidCallback onNeedPaint;

  final Map<int, _LiveTestPointerRecord> _pointers = <int, _LiveTestPointerRecord>{};

  TextPainter _label;
  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 10.0,
  );
  void _setDescription(String value) {
    assert(value != null);
    if (value.isEmpty) {
      _label = null;
      return;
    }
    // TODO(ianh): Figure out if the test name is actually RTL.
    _label ??= TextPainter(textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    _label.text = TextSpan(text: value, style: _labelStyle);
    _label.layout();
    if (onNeedPaint != null)
      onNeedPaint();
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    final Matrix4 transform = configuration.toHitTestMatrix();
    final double det = transform.invert();
    assert(det != 0.0);
    position = MatrixUtils.transformPoint(transform, position);
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(offset == Offset.zero);
    super.paint(context, offset);
    if (_pointers.isNotEmpty) {
      final double radius = configuration.size.shortestSide * 0.05;
      final Path path = Path()
        ..addOval(Rect.fromCircle(center: Offset.zero, radius: radius))
        ..moveTo(0.0, -radius * 2.0)
        ..lineTo(0.0, radius * 2.0)
        ..moveTo(-radius * 2.0, 0.0)
        ..lineTo(radius * 2.0, 0.0);
      final Canvas canvas = context.canvas;
      final Paint paint = Paint()
        ..strokeWidth = radius / 10.0
        ..style = PaintingStyle.stroke;
      bool dirty = false;
      for (int pointer in _pointers.keys) {
        final _LiveTestPointerRecord record = _pointers[pointer];
        paint.color = record.color.withOpacity(record.decay < 0 ? (record.decay / (_kPointerDecay - 1)) : 1.0);
        canvas.drawPath(path.shift(record.position), paint);
        if (record.decay < 0)
          dirty = true;
        record.decay += 1;
      }
      _pointers
        .keys
        .where((int pointer) => _pointers[pointer].decay == 0)
        .toList()
        .forEach(_pointers.remove);
      if (dirty && onNeedPaint != null)
        scheduleMicrotask(onNeedPaint);
    }
    _label?.paint(context.canvas, offset - const Offset(0.0, 10.0));
  }
}

StackTrace _unmangle(StackTrace stack) {
  if (stack is stack_trace.Trace)
    return stack.vmTrace;
  if (stack is stack_trace.Chain)
    return stack.toTrace().vmTrace;
  return stack;
}

/// Provides a default [HttpClient] which always returns empty 400 responses.
///
/// If another [HttpClient] is provided using [HttpOverrides.runZoned], that will
/// take precedence over this provider.
class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext _) {
    return _MockHttpClient();
  }
}

/// A mocked [HttpClient] which always returns a [_MockHttpRequest].
class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress;

  @override
  Duration connectionTimeout;

  @override
  Duration idleTimeout;

  @override
  int maxConnectionsPerHost;

  @override
  String userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String realm) f) {}

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String realm) f) {}

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port) callback) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  set findProxy(String Function(Uri url) f) {}

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }
}

/// A mocked [HttpClientRequest] which always returns a [_MockHttpClientResponse].
class _MockHttpRequest extends HttpClientRequest {
  @override
  Encoding encoding;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    return Future<void>.value();
  }

  @override
  Future<HttpClientResponse> close() {
    return Future<HttpClientResponse>.value(_MockHttpResponse());
  }

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  List<Cookie> get cookies => null;

  @override
  Future<HttpClientResponse> get done async => null;

  @override
  Future<void> flush() {
    return Future<void>.value();
  }

  @override
  String get method => null;

  @override
  Uri get uri => null;

  @override
  void write(Object obj) {}

  @override
  void writeAll(Iterable<Object> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object obj = '']) {}
}

/// A mocked [HttpClientResponse] which is empty and has a [statusCode] of 400.
class _MockHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  X509Certificate get certificate => null;

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  int get contentLength => -1;

  @override
  List<Cookie> get cookies => null;

  @override
  Future<Socket> detachSocket() {
    return Future<Socket>.error(UnsupportedError('Mocked response'));
  }

  @override
  bool get isRedirect => false;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event) onData, {Function onError, void Function() onDone, bool cancelOnError}) {
    return const Stream<List<int>>.empty().listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  bool get persistentConnection => null;

  @override
  String get reasonPhrase => null;

  @override
  Future<HttpClientResponse> redirect([String method, Uri url, bool followLoops]) {
    return Future<HttpClientResponse>.error(UnsupportedError('Mocked response'));
  }

  @override
  List<RedirectInfo> get redirects => <RedirectInfo>[];

  @override
  int get statusCode => 400;
}

/// A mocked [HttpHeaders] that ignores all writes.
class _MockHttpHeaders extends HttpHeaders {
  @override
  List<String> operator [](String name) => <String>[];

  @override
  void add(String name, Object value) {}

  @override
  void clear() {}

  @override
  void forEach(void Function(String name, List<String> values) f) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value) {}

  @override
  String value(String name) => null;
}
