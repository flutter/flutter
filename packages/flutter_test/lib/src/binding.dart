// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:meta/meta.dart';
import 'package:quiver/testing/async.dart';
import 'package:quiver/time.dart';
import 'package:test/test.dart' as test_package;
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:vector_math/vector_math_64.dart';

import 'stack_manipulation.dart';
import 'test_async_utils.dart';
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
  /// sent to the embedder. See [SemanticsNode.sendSemanticsUpdate].
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

const Size _kDefaultTestViewportSize = const Size(800.0, 600.0);

/// Base class for bindings used by widgets library tests.
///
/// The [ensureInitialized] method creates (if necessary) and returns
/// an instance of the appropriate subclass.
///
/// When using these bindings, certain features are disabled. For
/// example, [timeDilation] is reset to 1.0 on initialization.
abstract class TestWidgetsFlutterBinding extends BindingBase
  with SchedulerBinding,
       GestureBinding,
       RendererBinding,
       // Services binding omitted to avoid dragging in the licenses code.
       WidgetsBinding {

  TestWidgetsFlutterBinding() {
    debugPrint = debugPrintOverride;
  }

  @protected
  DebugPrintCallback get debugPrintOverride => debugPrint;

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
        new AutomatedTestWidgetsFlutterBinding();
      } else {
        new LiveTestWidgetsFlutterBinding();
      }
    }
    assert(WidgetsBinding.instance is TestWidgetsFlutterBinding);
    return WidgetsBinding.instance;
  }

  @override
  void initInstances() {
    timeDilation = 1.0; // just in case the developer has artificially changed it for development
    createHttpClient = () {
      return new http.MockClient((http.BaseRequest request) {
        return new Future<http.Response>.value(
          new http.Response("Mocked: Unavailable.", 404, request: request)
        );
      });
    };
    _testTextInput = new TestTextInput()..register();
    super.initInstances();
  }

  /// Whether there is currently a test executing.
  bool get inTest;

  /// The number of outstanding microtasks in the queue.
  int get microtaskCount;

  /// The default test timeout for tests when using this binding.
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
  Future<Null> pump([ Duration duration, EnginePhase newPhase = EnginePhase.sendSemanticsUpdate ]);

  /// Artificially calls dispatchLocaleChanged on the Widget binding,
  /// then flushes microtasks.
  Future<Null> setLocale(String languageCode, String countryCode) {
    return TestAsyncUtils.guard(() async {
      assert(inTest);
      final Locale locale = new Locale(languageCode, countryCode);
      dispatchLocaleChanged(locale);
      return null;
    });
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
  Future<Null> idle() {
    return TestAsyncUtils.guard(() {
      final Completer<Null> completer = new Completer<Null>();
      Timer.run(() {
        completer.complete(null);
      });
      return completer.future;
    });
  }

  /// Convert the given point from the global coodinate system (as used by
  /// pointer events from the device) to the coordinate system used by the
  /// tests (an 800 by 600 window).
  Offset globalToLocal(Offset point) => point;

  /// Convert the given point from the coordinate system used by the tests (an
  /// 800 by 600 window) to the global coodinate system (as used by pointer
  /// events from the device).
  Offset localToGlobal(Offset point) => point;

  @override
  void dispatchEvent(PointerEvent event, HitTestResult result, {
    TestBindingEventSource source: TestBindingEventSource.device
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
  EditableTextState get focusedEditable => _focusedEditable;
  EditableTextState _focusedEditable;
  set focusedEditable(EditableTextState value) {
    _focusedEditable = value..requestKeyboard();
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

  static const TextStyle _kMessageStyle = const TextStyle(
    color: const Color(0xFF917FFF),
    fontSize: 40.0
  );

  static final Widget _kPreTestMessage = const Center(
    child: const Text(
      'Test starting...',
      style: _kMessageStyle
    )
  );

  static final Widget _kPostTestMessage = const Center(
    child: const Text(
      'Test finished.',
      style: _kMessageStyle
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
  Future<Null> runTest(Future<Null> testBody(), VoidCallback invariantTester, { String description: '' });

  /// This is called during test execution before and after the body has been
  /// executed.
  ///
  /// It's used by [AutomatedTestWidgetsFlutterBinding] to drain the microtasks
  /// before the final [pump] that happens during test cleanup.
  void asyncBarrier() {
    TestAsyncUtils.verifyAllScopesClosed();
  }

  Zone _parentZone;
  Completer<Null> _currentTestCompleter;

  void _testCompletionHandler() {
    // This can get called twice, in the case of a Future without listeners failing, and then
    // our main future completing.
    assert(Zone.current == _parentZone);
    assert(_currentTestCompleter != null);
    if (_pendingExceptionDetails != null) {
      FlutterError.dumpErrorToConsole(_pendingExceptionDetails, forceReport: true);
      // test_package.registerException actually just calls the current zone's error handler (that
      // is to say, _parentZone's handleUncaughtError function). FakeAsync doesn't add one of those,
      // but the test package does, that's how the test package tracks errors. So really we could
      // get the same effect here by calling that error handler directly or indeed just throwing.
      // However, we call registerException because that's the semantically correct thing...
      test_package.registerException('Test failed. See exception logs above.', _EmptyStack.instance);
      _pendingExceptionDetails = null;
    }
    if (!_currentTestCompleter.isCompleted)
      _currentTestCompleter.complete(null);
  }

  Future<Null> _runTest(Future<Null> testBody(), VoidCallback invariantTester, String description) {
    assert(description != null);
    assert(inTest);
    _oldExceptionHandler = FlutterError.onError;
    int _exceptionCount = 0; // number of un-taken exceptions
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_pendingExceptionDetails != null) {
        if (_exceptionCount == 0) {
          _exceptionCount = 2;
          FlutterError.dumpErrorToConsole(_pendingExceptionDetails, forceReport: true);
        } else {
          _exceptionCount += 1;
        }
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        _pendingExceptionDetails = new FlutterErrorDetails(
          exception: 'Multiple exceptions ($_exceptionCount) were detected during the running of the current test, and at least one was unexpected.',
          library: 'Flutter test framework'
        );
      } else {
        _pendingExceptionDetails = details;
      }
    };
    _currentTestCompleter = new Completer<Null>();
    final ZoneSpecification errorHandlingZoneSpecification = new ZoneSpecification(
      handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone, dynamic exception, StackTrace stack) {
        if (_currentTestCompleter.isCompleted) {
          // Well this is not a good sign.
          // Ideally, once the test has failed we would stop getting errors from the test.
          // However, if someone tries hard enough they could get in a state where this happens.
          // If we silently dropped these errors on the ground, nobody would ever know. So instead
          // we report them to the console. They don't cause test failures, but hopefully someone
          // will see them in the logs at some point.
          FlutterError.dumpErrorToConsole(new FlutterErrorDetails(
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
        // This handler further calls the onError handler above, which sets
        // _pendingExceptionDetails. Nothing gets printed as a result of that
        // call unless we already had an exception pending, because in general
        // we want people to be able to cause the framework to report exceptions
        // and then use takeException to verify that they were really caught.
        // Now, if we actually get here, this isn't going to be one of those
        // cases. We only get here if the test has actually failed. So, once
        // we've carefully reported it, we then immediately end the test by
        // calling the _testCompletionHandler in the _parentZone.
        // We have to manually call _testCompletionHandler because if the Future
        // library calls us, it is maybe _instead_ of calling a registered
        // listener from a different zone. In our case, that would be instead of
        // calling the whenComplete() listener below.
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
        final StringBuffer expectLine = new StringBuffer();
        final int stackLinesToOmit = reportExpectCall(stack, expectLine);
        FlutterError.reportError(new FlutterErrorDetails(
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
        assert(_pendingExceptionDetails != null);
        _parentZone.run<Null>(_testCompletionHandler);
      }
    );
    _parentZone = Zone.current;
    final Zone testZone = _parentZone.fork(specification: errorHandlingZoneSpecification);
    testZone.runBinaryGuarded(_runTestBody, testBody, invariantTester)
      .whenComplete(_testCompletionHandler);
    asyncBarrier(); // When using AutomatedTestWidgetsFlutterBinding, this flushes the microtasks.
    return _currentTestCompleter.future;
  }

  Future<Null> _runTestBody(Future<Null> testBody(), VoidCallback invariantTester) async {
    assert(inTest);

    runApp(new Container(key: new UniqueKey(), child: _kPreTestMessage)); // Reset the tree to a known state.
    await pump();

    // run the test
    await testBody();
    asyncBarrier(); // drains the microtasks in `flutter test` mode (when using AutomatedTestWidgetsFlutterBinding)

    if (_pendingExceptionDetails == null) {
      // We only try to clean up and verify invariants if we didn't already
      // fail. If we got an exception already, then we instead leave everything
      // alone so that we don't cause more spurious errors.
      runApp(new Container(key: new UniqueKey(), child: _kPostTestMessage)); // Unmount any remaining widgets.
      await pump();
      invariantTester();
      _verifyInvariants();
    }

    assert(inTest);
    return null;
  }

  void _verifyInvariants() {
    assert(debugAssertNoTransientCallbacks(
      'An animation is still running even after the widget tree was disposed.'
    ));
    assert(debugAssertAllFoundationVarsUnset(
      'The value of a foundation debug variable was changed by the test.',
      debugPrintOverride: debugPrintOverride,
    ));
    assert(debugAssertAllRenderVarsUnset(
      'The value of a rendering debug variable was changed by the test.'
    ));
    assert(debugAssertAllWidgetVarsUnset(
      'The value of a widget debug variable was changed by the test.'
    ));
    assert(debugAssertAllSchedulerVarsUnset(
      'The value of a scheduler debug variable was changed by the test.'
    ));
  }

  /// Called by the [testWidgets] function after a test is executed.
  void postTest() {
    assert(inTest);
    FlutterError.onError = _oldExceptionHandler;
    _pendingExceptionDetails = null;
    _currentTestCompleter = null;
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

  FakeAsync _fakeAsync;

  @override
  Clock get clock => _clock;
  Clock _clock;

  @override
  DebugPrintCallback get debugPrintOverride => debugPrintSynchronously;

  @override
  test_package.Timeout get defaultTestTimeout => const test_package.Timeout(const Duration(seconds: 5));

  @override
  bool get inTest => _fakeAsync != null;

  @override
  int get microtaskCount => _fakeAsync.microtaskCount;

  @override
  Future<Null> pump([ Duration duration, EnginePhase newPhase = EnginePhase.sendSemanticsUpdate ]) {
    return TestAsyncUtils.guard(() {
      assert(inTest);
      assert(_clock != null);
      if (duration != null)
        _fakeAsync.elapse(duration);
      _phase = newPhase;
      if (hasScheduledFrame) {
        _fakeAsync.flushMicrotasks();
        handleBeginFrame(new Duration(
          milliseconds: _clock.now().millisecondsSinceEpoch,
        ));
        _fakeAsync.flushMicrotasks();
        handleDrawFrame();
      }
      _fakeAsync.flushMicrotasks();
      return new Future<Null>.value();
    });
  }

  @override
  void scheduleWarmUpFrame() {
    // We override the default version of this so that the application-startup warm-up frame
    // does not schedule timers which we might never get around to running.
    handleBeginFrame(null);
    _fakeAsync.flushMicrotasks();
    handleDrawFrame();
  }

  @override
  Future<Null> idle() {
    final Future<Null> result = super.idle();
    _fakeAsync.elapse(const Duration());
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

  @override
  Future<Null> runTest(Future<Null> testBody(), VoidCallback invariantTester, { String description: '' }) {
    assert(description != null);
    assert(!inTest);
    assert(_fakeAsync == null);
    assert(_clock == null);
    _fakeAsync = new FakeAsync();
    _clock = _fakeAsync.getClock(new DateTime.utc(2015, 1, 1));
    Future<Null> testBodyResult;
    _fakeAsync.run((FakeAsync fakeAsync) {
      assert(fakeAsync == _fakeAsync);
      testBodyResult = _runTest(testBody, invariantTester, description);
      assert(inTest);
    });
    // testBodyResult is a Future that was created in the Zone of the fakeAsync.
    // This means that if we call .then() on it (as the test framework is about to),
    // it will register a microtask to handle the future _in the fake async zone_.
    // To avoid this, we wrap it in a Future that we've created _outside_ the fake
    // async zone.
    return new Future<Null>.value(testBodyResult);
  }

  @override
  void asyncBarrier() {
    assert(_fakeAsync != null);
    _fakeAsync.flushMicrotasks();
    super.asyncBarrier();
  }

  @override
  void _verifyInvariants() {
    super._verifyInvariants();
    assert(
      _fakeAsync.periodicTimerCount == 0,
      'A periodic Timer is still running even after the widget tree was disposed.'
    );
    assert(
      _fakeAsync.nonPeriodicTimerCount == 0,
      'A Timer is still pending even after the widget tree was disposed.'
    );
    assert(_fakeAsync.microtaskCount == 0); // Shouldn't be possible.
  }

  @override
  void postTest() {
    super.postTest();
    assert(_fakeAsync != null);
    assert(_clock != null);
    _clock = null;
    _fakeAsync = null;
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
  bool get inTest => _inTest;
  bool _inTest = false;

  @override
  Clock get clock => const Clock();

  @override
  int get microtaskCount {
    // Unsupported until we have a wrapper around the real async API
    // https://github.com/flutter/flutter/issues/4637
    assert(false);
    return -1;
  }

  @override
  test_package.Timeout get defaultTestTimeout => test_package.Timeout.none;

  Completer<Null> _pendingFrame;
  bool _expectingFrame = false;
  bool _viewNeedsPaint = false;

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

  bool _doDrawThisFrame;

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    assert(_doDrawThisFrame == null);
    if (_expectingFrame ||
        (framePolicy == LiveTestWidgetsFlutterBindingFramePolicy.fullyLive) ||
        (framePolicy == LiveTestWidgetsFlutterBindingFramePolicy.fadePointers && _viewNeedsPaint)) {
      _doDrawThisFrame = true;
      super.handleBeginFrame(rawTimeStamp);
    } else {
      _doDrawThisFrame = false;
    }
    _viewNeedsPaint = false;
    if (_expectingFrame) { // set during pump
      assert(_pendingFrame != null);
      _pendingFrame.complete(); // unlocks the test API
      _pendingFrame = null;
      _expectingFrame = false;
    } else {
      ui.window.scheduleFrame();
    }
  }

  @override
  void handleDrawFrame() {
    assert(_doDrawThisFrame != null);
    if (_doDrawThisFrame)
      super.handleDrawFrame();
    _doDrawThisFrame = null;
  }

  @override
  void initRenderView() {
    assert(renderView == null);
    renderView = new _LiveTestRenderView(
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
    TestBindingEventSource source: TestBindingEventSource.device
  }) {
    switch (source) {
      case TestBindingEventSource.test:
        if (!renderView._pointers.containsKey(event.pointer)) {
          assert(event.down);
          renderView._pointers[event.pointer] = new _LiveTestPointerRecord(event.pointer, event.position);
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
  Future<Null> pump([ Duration duration, EnginePhase newPhase = EnginePhase.sendSemanticsUpdate ]) {
    assert(newPhase == EnginePhase.sendSemanticsUpdate);
    assert(inTest);
    assert(!_expectingFrame);
    assert(_pendingFrame == null);
    return TestAsyncUtils.guard(() {
      if (duration != null) {
        new Timer(duration, () {
          _expectingFrame = true;
          scheduleFrame();
        });
      } else {
        _expectingFrame = true;
        scheduleFrame();
      }
      _pendingFrame = new Completer<Null>();
      return _pendingFrame.future;
    });
  }

  @override
  Future<Null> runTest(Future<Null> testBody(), VoidCallback invariantTester, { String description: '' }) async {
    assert(description != null);
    assert(!inTest);
    _inTest = true;
    renderView._setDescription(description);
    return _runTest(testBody, invariantTester, description);
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
    return new TestViewConfiguration();
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
  TestViewConfiguration({ Size size: _kDefaultTestViewportSize })
    : _paintMatrix = _getMatrix(size, ui.window.devicePixelRatio),
      _hitTestMatrix = _getMatrix(size, 1.0),
      super(size: size);

  static Matrix4 _getMatrix(Size size, double devicePixelRatio) {
    final double actualWidth = ui.window.physicalSize.width;
    final double actualHeight = ui.window.physicalSize.height;
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
    final Matrix4 matrix = new Matrix4.compose(
      new Vector3(shiftX, shiftY, 0.0), // translation
      new Quaternion.identity(), // rotation
      new Vector3(scale, scale, 1.0) // scale
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
  /// This is essenitally the same as [toMatrix] but ignoring the device pixel
  /// ratio.
  ///
  /// This is useful because pointers are described in logical pixels, as
  /// opposed to graphics which are expressed in physical pixels.
  // TODO(ianh): We should make graphics and pointers use the same coordinate space.
  //             See: https://github.com/flutter/flutter/issues/1360
  Matrix4 toHitTestMatrix() => _hitTestMatrix.clone();

  @override
  String toString() => 'TestViewConfiguration';
}

const int _kPointerDecay = -2;

class _LiveTestPointerRecord {
  _LiveTestPointerRecord(
    this.pointer,
    this.position
  ) : color = new HSVColor.fromAHSV(0.8, (35.0 * pointer) % 360.0, 1.0, 1.0).toColor(),
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
  static const TextStyle _labelStyle = const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 10.0,
  );
  void _setDescription(String value) {
    assert(value != null);
    if (value.isEmpty) {
      _label = null;
      return;
    }
    _label ??= new TextPainter(textAlign: TextAlign.left);
    _label.text = new TextSpan(text: value, style: _labelStyle);
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
      final Path path = new Path()
        ..addOval(new Rect.fromCircle(center: Offset.zero, radius: radius))
        ..moveTo(0.0, -radius * 2.0)
        ..lineTo(0.0, radius * 2.0)
        ..moveTo(-radius * 2.0, 0.0)
        ..lineTo(radius * 2.0, 0.0);
      final Canvas canvas = context.canvas;
      final Paint paint = new Paint()
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

class _EmptyStack implements StackTrace {
  const _EmptyStack._();
  static const _EmptyStack instance = const _EmptyStack._();
  @override
  String toString() => '';
}

StackTrace _unmangle(StackTrace stack) {
  if (stack is stack_trace.Trace)
    return stack.vmTrace;
  if (stack is stack_trace.Chain)
    return stack.toTrace().vmTrace;
  return stack;
}
