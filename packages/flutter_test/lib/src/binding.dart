// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart' show TestWindow;
// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' as test_package;
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:vector_math/vector_math_64.dart';

import '_binding_io.dart' if (dart.library.html) '_binding_web.dart' as binding;
import 'goldens.dart';
import 'platform.dart';
import 'restoration.dart';
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

/// A [BinaryMessenger] subclass that is used as the default binary messenger
/// under testing environment.
///
/// It tracks status of data sent across the Flutter platform barrier, which is
/// useful for testing frameworks to monitor and synchronize against the
/// platform messages.
class TestDefaultBinaryMessenger extends BinaryMessenger {
  /// Creates a [TestDefaultBinaryMessenger] instance.
  ///
  /// The [delegate] instance must not be null.
  TestDefaultBinaryMessenger(this.delegate): assert(delegate != null);

  /// The delegate [BinaryMessenger].
  final BinaryMessenger delegate;

  final List<Future<ByteData>> _pendingMessages = <Future<ByteData>>[];

  /// The number of incomplete/pending calls sent to the platform channels.
  int get pendingMessageCount => _pendingMessages.length;

  @override
  Future<ByteData> send(String channel, ByteData message) {
    final Future<ByteData> resultFuture = delegate.send(channel, message);
    // Removes the future itself from the [_pendingMessages] list when it
    // completes.
    if (resultFuture != null) {
      _pendingMessages.add(resultFuture);
      resultFuture.whenComplete(() => _pendingMessages.remove(resultFuture));
    }
    return resultFuture;
  }

  /// Returns a Future that completes after all the platform calls are finished.
  ///
  /// If a new platform message is sent after this method is called, this new
  /// message is not tracked. Use with [pendingMessageCount] to guarantee no
  /// pending message calls.
  Future<void> get platformMessagesFinished {
    return Future.wait<void>(_pendingMessages);
  }

  @override
  Future<void> handlePlatformMessage(
      String channel,
      ByteData data,
      ui.PlatformMessageResponseCallback callback,
  ) {
    return delegate.handlePlatformMessage(channel, data, callback);
  }

  @override
  void setMessageHandler(String channel, MessageHandler handler) {
    delegate.setMessageHandler(channel, handler);
  }

  @override
  bool checkMessageHandler(String channel, MessageHandler handler) {
    return delegate.checkMessageHandler(channel, handler);
  }

  @override
  void setMockMessageHandler(String channel, MessageHandler handler) {
    delegate.setMockMessageHandler(channel, handler);
  }

  @override
  bool checkMockMessageHandler(String channel, MessageHandler handler) {
    return delegate.checkMockMessageHandler(channel, handler);
  }
}

/// Base class for bindings used by widgets library tests.
///
/// The [ensureInitialized] method creates (if necessary) and returns
/// an instance of the appropriate subclass.
///
/// When using these bindings, certain features are disabled. For
/// example, [timeDilation] is reset to 1.0 on initialization.
///
/// In non-browser tests, the binding overrides `HttpClient` creation with a
/// fake client that always returns a status code of 400. This is to prevent
/// tests from making network calls, which could introduce flakiness. A test
/// that actually needs to make a network call should provide its own
/// `HttpClient` to the code making the call, so that it can appropriately mock
/// or fake responses.
abstract class TestWidgetsFlutterBinding extends BindingBase
  with SchedulerBinding,
       ServicesBinding,
       GestureBinding,
       SemanticsBinding,
       RendererBinding,
       PaintingBinding,
       WidgetsBinding {

  /// Constructor for [TestWidgetsFlutterBinding].
  ///
  /// This constructor overrides the [debugPrint] global hook to point to
  /// [debugPrintOverride], which can be overridden by subclasses.
  TestWidgetsFlutterBinding() : _window = TestWindow(window: ui.window) {
    debugPrint = debugPrintOverride;
    debugDisableShadows = disableShadows;
    debugCheckIntrinsicSizes = checkIntrinsicSizes;
  }

  @override
  TestWindow get window => _window;
  final TestWindow _window;

  @override
  TestRestorationManager get restorationManager => _restorationManager;
  TestRestorationManager _restorationManager;

  /// Called by the test framework at the beginning of a widget test to
  /// prepare the binding for the next test.
  void reset() {
    _restorationManager = createRestorationManager();
  }

  @override
  TestRestorationManager createRestorationManager() {
    return TestRestorationManager();
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

  /// Determines whether the Dart [HttpClient] class should be overriden to
  /// always return a failure response.
  ///
  /// By default, this value is true, so that unit tests will not become flaky
  /// due to intermitten network errors. The value may be overriden by a binding
  /// intended for use in integration tests that do end to end application
  /// testing, including working with real network responses.
  @protected
  bool get overrideHttpClient => true;

  /// Determines whether the binding automatically registers [testTextInput].
  ///
  /// Unit tests make use of this to mock out text input communication for
  /// widgets. An integration test would set this to false, to test real IME
  /// or keyboard input.
  ///
  /// [TestTextInput.isRegistered] reports whether the text input mock is
  /// registered or not.
  @protected
  bool get registerTestTextInput => true;

  /// Increase the timeout for the current test by the given duration.
  ///
  /// This only matters if the test has an `initialTimeout` set on
  /// [testWidgets], and the test is running via `flutter test`. By default,
  /// tests do not have such a timeout. Tests run using `flutter run` never time
  /// out even if one is specified.
  ///
  /// This method has no effect on the timeout specified via `timeout` on
  /// [testWidgets]. That timeout is implemented by the `test` package.
  ///
  /// By default, each [pump] and [WidgetTester.pumpWidget] call increases the
  /// timeout by a hundred milliseconds, and each [matchesGoldenFile]
  /// expectation increases it by a minute. If there is no timeout in the first
  /// place, this has no effect.
  ///
  /// The granularity of timeouts is coarse: the time is checked once per
  /// second, and only when the test is not executing. It is therefore possible
  /// for a timeout to be exceeded by hundreds of milliseconds and for the test
  /// to still succeed. If precise timing is required, it should be implemented
  /// as a part of the test rather than relying on this mechanism.
  ///
  /// See also:
  ///
  ///  * [testWidgets], on which a timeout can be set using the `timeout`
  ///    argument.
  ///  * [defaultTestTimeout], the maximum that the timeout can reach.
  ///    (That timeout is implemented by the `test` package.)
  // See AutomatedTestWidgetsFlutterBinding.addTime for an actual implementation.
  void addTime(Duration duration);

  /// Delay for `duration` of time.
  ///
  /// In the automated test environment ([AutomatedTestWidgetsFlutterBinding],
  /// typically used in `flutter test`), this advances the fake [clock] for the
  /// period and also increases timeout (see [addTime]).
  ///
  /// In the live test environemnt ([LiveTestWidgetsFlutterBinding], typically
  /// used for `flutter run` and for [e2e](https://pub.dev/packages/e2e)), it is
  /// equivalent as [Future.delayed].
  Future<void> delayed(Duration duration);

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
  /// using `flutter run`). This is determined by looking at the
  /// environment variables for a variable called `FLUTTER_TEST`.
  ///
  /// If `FLUTTER_TEST` is set with a value of 'true', then this test was
  /// invoked by `flutter test`. If `FLUTTER_TEST` is not set, or if it is set
  /// to 'false', then this test was invoked by `flutter run`.
  ///
  /// Browser environments do not currently support the
  /// [LiveTestWidgetsFlutterBinding], so this function will always set up an
  /// [AutomatedTestWidgetsFlutterBinding] when run in a web browser.
  ///
  /// The parameter `environment` is exposed to test different environment
  /// variable values, and should not be used.
  static WidgetsBinding ensureInitialized([@visibleForTesting Map<String, String> environment]) => binding.ensureInitialized(environment);

  @override
  void initInstances() {
    super.initInstances();
    timeDilation = 1.0; // just in case the developer has artificially changed it for development
    if (overrideHttpClient) {
      binding.setupHttpOverrides();
    }
    _testTextInput = TestTextInput(onCleared: _resetFocusedEditable);
    if (registerTestTextInput) {
      _testTextInput.register();
    }
  }

  @override
  // ignore: MUST_CALL_SUPER
  void initLicenses() {
    // Do not include any licenses, because we're a test, and the LICENSE file
    // doesn't get generated for tests.
  }

  @override
  BinaryMessenger createBinaryMessenger() {
    return TestDefaultBinaryMessenger(super.createBinaryMessenger());
  }

  /// Whether there is currently a test executing.
  bool get inTest;

  /// The number of outstanding microtasks in the queue.
  int get microtaskCount;

  /// The default maximum test timeout for tests when using this binding.
  ///
  /// This controls the default for the `timeout` argument on `testWidgets`. It
  /// is 10 minutes for [AutomatedTestWidgetsFlutterBinding] (tests running
  /// using `flutter test`), and unlimited for tests using
  /// [LiveTestWidgetsFlutterBinding] (tests running using `flutter run`).
  ///
  /// This is the maximum that the timeout controlled by `initialTimeout` on
  /// [testWidgets] can reach when augmented using [addTime].
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
  /// will return a future that completes with `null`.
  ///
  /// Re-entrant calls to this method are not allowed; callers of this method
  /// are required to wait for the returned future to complete before calling
  /// this method again. Attempts to do otherwise will result in a
  /// [TestFailure] error being thrown.
  ///
  /// The `additionalTime` argument is used by the
  /// [AutomatedTestWidgetsFlutterBinding] implementation to increase the
  /// current timeout, if any. See [AutomatedTestWidgetsFlutterBinding.addTime]
  /// for details.
  Future<T> runAsync<T>(
    Future<T> callback(), {
    Duration additionalTime = const Duration(milliseconds: 1000),
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

  /// Re-attempts the initialization of the lifecycle state after providing
  /// test values in [TestWindow.initialLifecycleStateTestValue].
  void readTestInitialLifecycleStateFromNativeWindow() {
    readInitialLifecycleStateFromNativeWindow();
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
    final double devicePixelRatio = window.devicePixelRatio;
    final Size size = _surfaceSize ?? window.physicalSize / devicePixelRatio;
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
  void dispatchEvent(
    PointerEvent event,
    HitTestResult hitTestResult, {
    TestBindingEventSource source = TestBindingEventSource.device,
  }) {
    // This override disables calling this method from base class
    // [GestureBinding] when the runtime type is [TestWidgetsFlutterBinding],
    // while enables sub class [LiveTestWidgetsFlutterBinding] to override
    // this behavior and use this argument to determine the souce of the event
    // especially when the test app is running on a device.
    assert(source == TestBindingEventSource.test);
    super.dispatchEvent(event, hitTestResult);
  }

  /// A stub for the system's onscreen keyboard. Callers must set the
  /// [focusedEditable] before using this value.
  TestTextInput get testTextInput => _testTextInput;
  TestTextInput _testTextInput;

  /// The current client of the onscreen keyboard. Callers must pump
  /// an additional frame after setting this property to complete the
  /// focus change.
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
  StackTraceDemangler _oldStackTraceDemangler;
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
    ),
  );

  static const Widget _postTestMessage = Center(
    child: Text(
      'Test finished.',
      style: _messageStyle,
      textDirection: TextDirection.ltr,
    ),
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
  ///
  /// The `timeout` argument sets the initial timeout, if any. It can
  /// be increased with [addTime]. By default there is no timeout.
  Future<void> runTest(Future<void> testBody(), VoidCallback invariantTester, { String description = '', Duration timeout });

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

  Future<void> _runTest(
    Future<void> testBody(),
    VoidCallback invariantTester,
    String description, {
    Future<void> timeout,
  }) {
    assert(description != null);
    assert(inTest);
    _oldExceptionHandler = FlutterError.onError;
    _oldStackTraceDemangler = FlutterError.demangleStackTrace;
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
          library: 'Flutter test framework',
        );
      } else {
        reportExceptionNoticed(details); // mostly this is just a hook for the LiveTestWidgetsFlutterBinding
        _pendingExceptionDetails = details;
      }
    };
    FlutterError.demangleStackTrace = (StackTrace stack) {
      // package:stack_trace uses ZoneSpecification.errorCallback to add useful
      // information to stack traces, in this case the Trace and Chain classes
      // can be present. Because these StackTrace implementations do not follow
      // the format the framework expects, we covert them to a vm trace here.
      if (stack is stack_trace.Trace)
        return stack.vmTrace;
      if (stack is stack_trace.Chain)
        return stack.toTrace().vmTrace;
      return stack;
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
          stack: stack,
          context: ErrorDescription('running a test (but after the test had completed)'),
          library: 'Flutter test framework',
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
      DiagnosticsNode treeDump;
      try {
        treeDump = renderViewElement?.toDiagnosticsNode() ?? DiagnosticsNode.message('<no tree>');
        // TODO(jacobr): this is a hack to make sure the tree can safely be fully dumped.
        // Potentially everything is good enough without this case.
        treeDump.toStringDeep();
      } catch (exception) {
        treeDump = DiagnosticsNode.message('<additional error caught while dumping tree: $exception>', level: DiagnosticLevel.error);
      }
      final List<DiagnosticsNode> omittedFrames = <DiagnosticsNode>[];
      final int stackLinesToOmit = reportExpectCall(stack, omittedFrames);
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        context: ErrorDescription('running a test'),
        library: 'Flutter test framework',
        stackFilter: (Iterable<String> frames) {
          return FlutterError.defaultStackFilter(frames.skip(stackLinesToOmit));
        },
        informationCollector: () sync* {
          if (stackLinesToOmit > 0)
            yield* omittedFrames;
          if (showAppDumpInErrors) {
            yield DiagnosticsProperty<DiagnosticsNode>('At the time of the failure, the widget tree looked as follows', treeDump, linePrefix: '# ', style: DiagnosticsTreeStyle.flat);
          }
          if (description.isNotEmpty)
            yield DiagnosticsProperty<String>('The test description was', description, style: DiagnosticsTreeStyle.errorProperty);
        },
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
    // Pretend that the first frame produced in the test body is the first frame
    // sent to the engine.
    resetFirstFrameSent();

    final bool autoUpdateGoldensBeforeTest = autoUpdateGoldenFiles && !isBrowser;
    final TestExceptionReporter reportTestExceptionBeforeTest = reportTestException;
    final ErrorWidgetBuilder errorWidgetBuilderBeforeTest = ErrorWidget.builder;

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
      _verifyAutoUpdateGoldensUnset(autoUpdateGoldensBeforeTest && !isBrowser);
      _verifyReportTestExceptionUnset(reportTestExceptionBeforeTest);
      _verifyErrorWidgetBuilderUnset(errorWidgetBuilderBeforeTest);
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

  void _verifyErrorWidgetBuilderUnset(ErrorWidgetBuilder valueBeforeTest) {
    assert(() {
      if (ErrorWidget.builder != valueBeforeTest) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: FlutterError(
              'The value of ErrorWidget.builder was changed by the test.',
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
    FlutterError.demangleStackTrace = _oldStackTraceDemangler;
    _pendingExceptionDetails = null;
    _parentZone = null;
    buildOwner.focusManager = FocusManager();
    // Disabling the warning because @visibleForTesting doesn't take the testing
    // framework itself into account, but we don't want it visible outside of
    // tests.
    // ignore: invalid_use_of_visible_for_testing_member
    RawKeyboard.instance.clearKeysPressed();
    assert(!RendererBinding.instance.mouseTracker.mouseIsConnected,
        'The MouseTracker thinks that there is still a mouse connected, which indicates that a '
        'test has not removed the mouse pointer which it added. Call removePointer on the '
        'active mouse gesture to remove the mouse pointer.');
    // ignore: invalid_use_of_visible_for_testing_member
    RendererBinding.instance.initMouseTracker();
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
    binding.mockFlutterAssets();
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

  /// The value of [defaultTestTimeout] can be set to `None` to enable debugging flutter tests where
  /// we would not want to timeout the test. This is expected to be used by test tooling which
  /// can detect debug mode.
  @override
  test_package.Timeout defaultTestTimeout = const test_package.Timeout(Duration(minutes: 10));

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
  Future<T> runAsync<T>(
    Future<T> callback(), {
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
          context: ErrorDescription('while running async test code'),
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
  void ensureFrameCallbacksRegistered() {
    // Leave Window alone, do nothing.
    assert(window.onDrawFrame == null);
    assert(window.onBeginFrame == null);
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
  void scheduleAttachRootWidget(Widget rootWidget) {
    // We override the default version of this so that the application-startup widget tree
    // build does not schedule timers which we might never get around to running.
    attachRootWidget(rootWidget);
    _currentFakeAsync.flushMicrotasks();
  }

  @override
  Future<void> idle() {
    final Future<void> result = super.idle();
    _currentFakeAsync.elapse(Duration.zero);
    return result;
  }

  int _firstFrameDeferredCount = 0;
  bool _firstFrameSent = false;

  @override
  bool get sendFramesToEngine => _firstFrameSent || _firstFrameDeferredCount == 0;

  @override
  void deferFirstFrame() {
    assert(_firstFrameDeferredCount >= 0);
    _firstFrameDeferredCount += 1;
  }

  @override
  void allowFirstFrame() {
    assert(_firstFrameDeferredCount > 0);
    _firstFrameDeferredCount -= 1;
    // Unlike in RendererBinding.allowFirstFrame we do not force a frame her
    // to give the test full control over frame scheduling.
  }

  @override
  void resetFirstFrameSent() {
    _firstFrameSent = false;
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
            if (_phase != EnginePhase.paint && sendFramesToEngine) {
              _firstFrameSent = true;
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
    assert(_timeout != null);
    if (_timeoutStopwatch.elapsed > _timeout) {
      _timeoutCompleter.completeError(
        TimeoutException(
          'The test exceeded the timeout. It may have hung.\n'
          'Consider using "tester.binding.addTime" to increase the timeout before expensive operations.',
          _timeout,
        ),
      );
    }
  }

  @override
  void addTime(Duration duration) {
    if (_timeout != null)
      _timeout += duration;
  }

  @override
  Future<void> delayed(Duration duration) {
    assert(_currentFakeAsync != null);
    addTime(duration);
    _currentFakeAsync.elapse(duration);
    return Future<void>.value();
  }

  @override
  Future<void> runTest(
    Future<void> testBody(),
    VoidCallback invariantTester, {
    String description = '',
    Duration timeout,
  }) {
    assert(description != null);
    assert(!inTest);
    assert(_currentFakeAsync == null);
    assert(_clock == null);

    _timeout = timeout;
    if (_timeout != null) {
      _timeoutStopwatch = Stopwatch()..start();
      _timeoutTimer = Timer.periodic(const Duration(seconds: 1), _checkTimeout);
      _timeoutCompleter = Completer<void>();
    }

    final FakeAsync fakeAsync = FakeAsync();
    _currentFakeAsync = fakeAsync; // reset in postTest
    _clock = fakeAsync.getClock(DateTime.utc(2015, 1, 1));
    Future<void> testBodyResult;
    fakeAsync.run((FakeAsync localFakeAsync) {
      assert(fakeAsync == _currentFakeAsync);
      assert(fakeAsync == localFakeAsync);
      testBodyResult = _runTest(testBody, invariantTester, description, timeout: _timeoutCompleter?.future);
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

    bool timersPending = false;
    if (_currentFakeAsync.periodicTimerCount != 0 ||
        _currentFakeAsync.nonPeriodicTimerCount != 0) {
        debugPrint('Pending timers:');
        for (final FakeTimer timer in _currentFakeAsync.pendingTimers) {
          debugPrint(
            'Timer (duration: ${timer.duration}, '
            'periodic: ${timer.isPeriodic}), created:');
          debugPrintStack(stackTrace: timer.creationStackTrace);
          debugPrint('');
        }
        timersPending = true;
    }
    assert(!timersPending, 'A Timer is still pending even after the widget tree was disposed.');
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
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _timeoutStopwatch = null;
    _timeout = null;
  }
}

/// Available policies for how a [LiveTestWidgetsFlutterBinding] should paint
/// frames.
///
/// These values are set on the binding's
/// [LiveTestWidgetsFlutterBinding.framePolicy] property.
///
/// {@template flutter.flutter_test.frame_policy}
/// The default is [LiveTestWidgetsFlutterBindingFramePolicy.fadePointers].
/// Setting this to anything other than
/// [LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps] results in pumping
/// extra frames, which might involve calling builders more, or calling paint
/// callbacks more, etc, and might interfere with the test. If you know that
/// your test won't be affected by this, you can set the policy to
/// [LiveTestWidgetsFlutterBindingFramePolicy.fullyLive] or
/// [LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive] in that particular
/// file.
///
/// To set a value while still allowing the test file to work as a normal test,
/// add the following code to your test file at the top of your
/// `void main() { }` function, before calls to [testWidgets]:
///
/// ```dart
/// TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
/// if (binding is LiveTestWidgetsFlutterBinding) {
///   binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.[thePolicy];
/// }
/// ```
/// {@endtemplate}
enum LiveTestWidgetsFlutterBindingFramePolicy {
  /// Strictly show only frames that are explicitly pumped.
  ///
  /// This most closely matches the [AutomatedTestWidgetsFlutterBinding]
  /// (the defualt binding for `flutter test`) behavior.
  onlyPumps,

  /// Show pumped frames, and additionally schedule and run frames to fade
  /// out the pointer crosshairs and other debugging information shown by
  /// the binding.
  ///
  /// This will schedule frames when pumped or when there has been some
  /// activity with [TestPointer]s.
  ///
  /// This can result in additional frames being pumped beyond those that
  /// the test itself requests, which can cause differences in behavior.
  fadePointers,

  /// Show every frame that the framework requests, even if the frames are not
  /// explicitly pumped.
  ///
  /// The major difference between [fullyLive] and [benchmarkLive] is the latter
  /// ignores frame requests by [WidgetTester.pump].
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
  /// directly to run (either by using [WidgetTester.pumpBenchmark] or invoking
  /// [Window.onBeginFrame] and [Window.onDrawFrame]).
  ///
  /// This allows all frame requests from the engine to be serviced, and allows
  /// all frame requests that are artificially triggered to be serviced, but
  /// ignores [SchedulerBinding.scheduleFrame] requests from the framework.
  /// Therefore animation won't run for this mode because the framework
  /// generates an animation by requesting new frames.
  ///
  /// The [SchedulerBinding.hasScheduledFrame] property will never be true in
  /// this mode. This can cause unexpected effects. For instance,
  /// [WidgetTester.pumpAndSettle] does not function in this mode, as it relies
  /// on the [SchedulerBinding.hasScheduledFrame] property to determine when the
  /// application has "settled".
  benchmark,

  /// Ignore any request from pump but respect other requests to schedule a
  /// frame.
  ///
  /// This is used for running the test on a device, where scheduling of new
  /// frames respects what the engine and the device needed.
  ///
  /// Compared to [fullyLive] this policy ignores the frame requests from
  /// [WidgetTester.pump] so that frame scheduling mimics that of the real
  /// environment, and avoids waiting for an artificially pumped frame. (For
  /// example, when driving the test in methods like
  /// [WidgetTester.handlePointerEventRecord] or [WidgetTester.fling].)
  ///
  /// This policy differs from [benchmark] in that it can be used for capturing
  /// animation frames requested by the framework.
  benchmarkLive,
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

  /// The strategy for [pump]ing and requesting new frames.
  ///
  /// The policy decides whether [pump] (with a duration) pumps a single frame
  /// (as would happen in a normal test environment using
  /// [AutomatedTestWidgetsFlutterBinding]), or pumps every frame that the
  /// system requests during an asynchronous pause (as would normally happen
  /// when running an application with [WidgetsFlutterBinding]).
  ///
  /// {@macro flutter.flutter_test.frame_policy}
  ///
  /// See [LiveTestWidgetsFlutterBindingFramePolicy].
  LiveTestWidgetsFlutterBindingFramePolicy framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fadePointers;

  @override
  void addTime(Duration duration) {
    // We don't support timeouts on the LiveTestWidgetsFlutterBinding.
    // See runTest().
  }

  @override
  Future<void> delayed(Duration duration) {
    return Future<void>.delayed(duration);
  }

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
        (framePolicy == LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive) ||
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
    } else if (framePolicy != LiveTestWidgetsFlutterBindingFramePolicy.benchmark) {
      window.scheduleFrame();
    }
  }

  @override
  void initRenderView() {
    assert(renderView == null);
    renderView = _LiveTestRenderView(
      configuration: createViewConfiguration(),
      onNeedPaint: _handleViewNeedsPaint,
      window: window,
    );
    renderView.prepareInitialFrame();
  }

  @override
  _LiveTestRenderView get renderView => super.renderView as _LiveTestRenderView;

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


  /// Dispatch an event to a hit test result's path.
  ///
  /// Apart from forwarding the event to [GestureBinding.dispatchEvent],
  /// This also paint all events that's down on the screen.
  @override
  void dispatchEvent(
    PointerEvent event,
    HitTestResult hitTestResult, {
    TestBindingEventSource source = TestBindingEventSource.device,
  }) {
    switch (source) {
      case TestBindingEventSource.test:
        if (renderView._pointers.containsKey(event.pointer)) {
          renderView._pointers[event.pointer].position = event.position;
          if (!event.down)
            renderView._pointers[event.pointer].decay = _kPointerDecay;
          _handleViewNeedsPaint();
        } else if (event.down) {
          assert(event is PointerDownEvent);
          renderView._pointers[event.pointer] = _LiveTestPointerRecord(
            event.pointer,
            event.position,
          );
          _handleViewNeedsPaint();
        }
        super.dispatchEvent(event, hitTestResult, source: source);
        break;
      case TestBindingEventSource.device:
        if (deviceEventDispatcher != null)
          deviceEventDispatcher.dispatchEvent(event, hitTestResult);
        break;
    }
  }

  @override
  Future<void> pump([ Duration duration, EnginePhase newPhase = EnginePhase.sendSemanticsUpdate ]) {
    assert(newPhase == EnginePhase.sendSemanticsUpdate);
    assert(inTest);
    assert(!_expectingFrame);
    assert(_pendingFrame == null);
    if (framePolicy == LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive) {
      // Ignore all pumps and just wait.
      return delayed(duration ?? Duration.zero);
    }
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
  Future<T> runAsync<T>(
    Future<T> callback(), {
    Duration additionalTime = const Duration(milliseconds: 1000),
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

    addTime(additionalTime); // doesn't do anything since we don't actually track the timeout, but just for correctness...

    _runningAsyncTasks = true;
    try {
      return await callback();
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Flutter test framework',
        context: ErrorSummary('while running async test code'),
      ));
      return null;
    } finally {
      _runningAsyncTasks = false;
    }
  }

  @override
  Future<void> runTest(Future<void> testBody(), VoidCallback invariantTester, { String description = '', Duration timeout }) async {
    assert(description != null);
    assert(!inTest);
    _inTest = true;
    renderView._setDescription(description);
    // We drop the timeout on the floor in `flutter run` mode.
    // We could support it, but we'd have to automatically add the entire duration of pumps
    // and timers and so on, since those operate in real time when using this binding, but
    // the timeouts expect them to happen near-instantaneously.
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
    return TestViewConfiguration(
      size: _surfaceSize ?? _kDefaultTestViewportSize,
      window: window,
    );
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
  ///
  /// If a [window] instance is not provided it defaults to [ui.window].
  factory TestViewConfiguration({
    Size size = _kDefaultTestViewportSize,
    ui.Window window,
  }) {
    return TestViewConfiguration._(size, window ?? ui.window);
  }

  TestViewConfiguration._(Size size, ui.Window window)
    : _paintMatrix = _getMatrix(size, window.devicePixelRatio, window),
      _hitTestMatrix = _getMatrix(size, 1.0, window),
      super(size: size);

  static Matrix4 _getMatrix(Size size, double devicePixelRatio, ui.Window window) {
    final double inverseRatio = devicePixelRatio / window.devicePixelRatio;
    final double actualWidth = window.physicalSize.width * inverseRatio;
    final double actualHeight = window.physicalSize.height * inverseRatio;
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
      Vector3(scale, scale, 1.0), // scale
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
    this.position,
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
    @required ui.Window window,
  }) : super(configuration: configuration, window: window);

  @override
  TestViewConfiguration get configuration => super.configuration as TestViewConfiguration;
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
      for (final int pointer in _pointers.keys) {
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
