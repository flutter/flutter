// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/testing/async.dart';
import 'package:quiver/time.dart';

/// Enumeration of possible phases to reach in
/// [WidgetTester.pumpWidget] and [TestWidgetsFlutterBinding.pump].
// TODO(ianh): Merge with identical code in the rendering test code.
enum EnginePhase {
  layout,
  compositingBits,
  paint,
  composite,
  flushSemantics,
  sendSemanticsTree
}

class TestWidgetsFlutterBinding extends BindingBase with SchedulerBinding, GestureBinding, ServicesBinding, RendererBinding, WidgetsBinding {
  /// Creates and initializes the binding. This constructor is
  /// idempotent; calling it a second time will just return the
  /// previously-created instance.
  static WidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null)
      new TestWidgetsFlutterBinding();
    assert(WidgetsBinding.instance is TestWidgetsFlutterBinding);
    return WidgetsBinding.instance;
  }

  @override
  void initInstances() {
    timeDilation = 1.0; // just in case the developer has artificially changed it for development
    debugPrint = _synchronousDebugPrint; // TODO(ianh): don't do this when running as 'flutter run'
    super.initInstances();
  }

  void _synchronousDebugPrint(String message, { int wrapWidth }) {
    if (wrapWidth != null) {
      print(message.split('\n').expand((String line) => debugWordWrap(line, wrapWidth)).join('\n'));
    } else {
      print(message);
    }
  }

  FakeAsync get fakeAsync => _fakeAsync;
  bool get inTest => fakeAsync != null;

  FakeAsync _fakeAsync;
  Clock _clock;

  EnginePhase phase = EnginePhase.sendSemanticsTree;

  // Pump the rendering pipeline up to the given phase.
  @override
  void beginFrame() {
    assert(inTest);
    buildOwner.buildDirtyElements();
    _beginFrame();
    buildOwner.finalizeTree();
  }

  // Cloned from RendererBinding.beginFrame() but with early-exit semantics.
  void _beginFrame() {
    assert(inTest);
    assert(renderView != null);
    pipelineOwner.flushLayout();
    if (phase == EnginePhase.layout)
      return;
    pipelineOwner.flushCompositingBits();
    if (phase == EnginePhase.compositingBits)
      return;
    pipelineOwner.flushPaint();
    if (phase == EnginePhase.paint)
      return;
    renderView.compositeFrame(); // this sends the bits to the GPU
    if (phase == EnginePhase.composite)
      return;
    if (SemanticsNode.hasListeners) {
      pipelineOwner.flushSemantics();
      if (phase == EnginePhase.flushSemantics)
        return;
      SemanticsNode.sendSemanticsTree();
    }
  }

  @override
  void dispatchEvent(PointerEvent event, HitTestResult result) {
    assert(inTest);
    super.dispatchEvent(event, result);
    fakeAsync.flushMicrotasks();
  }

  /// Triggers a frame sequence (build/layout/paint/etc),
  /// then flushes microtasks.
  ///
  /// If duration is set, then advances the clock by that much first.
  /// Doing this flushes microtasks.
  ///
  /// The supplied EnginePhase is the final phase reached during the pump pass;
  /// if not supplied, the whole pass is executed.
  void pump([ Duration duration, EnginePhase newPhase = EnginePhase.sendSemanticsTree ]) {
    assert(inTest);
    assert(_clock != null);
    if (duration != null)
      fakeAsync.elapse(duration);
    phase = newPhase;
    handleBeginFrame(new Duration(
      milliseconds: _clock.now().millisecondsSinceEpoch
    ));
    fakeAsync.flushMicrotasks();
  }

  /// Artificially calls dispatchLocaleChanged on the Widget binding,
  /// then flushes microtasks.
  void setLocale(String languageCode, String countryCode) {
    assert(inTest);
    Locale locale = new Locale(languageCode, countryCode);
    dispatchLocaleChanged(locale);
    fakeAsync.flushMicrotasks();
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
    dynamic result = _pendingException;
    _pendingException = null;
    return result;
  }
  dynamic _pendingException;

  /// Called by the [testWidgets] function before a test is executed.
  void preTest() {
    assert(fakeAsync == null);
    assert(_clock == null);
    _fakeAsync = new FakeAsync();
    _clock = fakeAsync.getClock(new DateTime.utc(2015, 1, 1));
  }

  /// Invoke the callback inside a [FakeAsync] scope on which [pump] can
  /// advance time.
  ///
  /// Returns a future which completes when the test has run.
  ///
  /// Called by the [testWidgets] and [benchmarkWidgets] functions to
  /// run a test.
  Future<Null> runTest(Future<Null> callback()) {
    assert(inTest);
    Future<Null> callbackResult;
    fakeAsync.run((FakeAsync fakeAsync) {
      assert(fakeAsync == this.fakeAsync);
      callbackResult = _runTest(callback);
      fakeAsync.flushMicrotasks();
      assert(inTest);
    });
    // callbackResult is a Future that was created in the Zone of the fakeAsync.
    // This means that if we call .then() on it (as the test framework is about to),
    // it will register a microtask to handle the future _in the fake async zone_.
    // To avoid this, we wrap it in a Future that we've created _outside_ the fake
    // async zone.
    return new Future<Null>.value(callbackResult);
  }

  Future<Null> _runTest(Future<Null> callback()) async {
    assert(inTest);
    FlutterExceptionHandler oldHandler = FlutterError.onError;
    try {
      FlutterError.onError = (FlutterErrorDetails details) {
        if (_pendingException != null) {
          FlutterError.dumpErrorToConsole(_pendingException);
          FlutterError.dumpErrorToConsole(details.exception);
          _pendingException = 'An uncaught exception was thrown.';
          throw details.exception;
        }
        _pendingException = details;
      };

      // run the test
      runApp(new Container(key: new UniqueKey())); // Reset the tree to a known state.
      await callback();
      fakeAsync.flushMicrotasks();
      runApp(new Container(key: new UniqueKey())); // Unmount any remaining widgets.
      fakeAsync.flushMicrotasks();

      // verify invariants
      assert(debugAssertNoTransientCallbacks(
        'An animation is still running even after the widget tree was disposed.'
      ));
      assert(() {
        'A Timer is still running even after the widget tree was disposed.';
        return fakeAsync.periodicTimerCount == 0;
      });
      assert(() {
        'A Timer is still running even after the widget tree was disposed.';
        return fakeAsync.nonPeriodicTimerCount == 0;
      });
      assert(fakeAsync.microtaskCount == 0); // Shouldn't be possible.

      // check for unexpected exceptions
      if (_pendingException != null)
        throw 'An exception (shown above) was thrown during the test.';
    } finally {
      FlutterError.onError = oldHandler;
      if (_pendingException != null) {
        FlutterError.dumpErrorToConsole(_pendingException);
        _pendingException = null;
      }
      assert(inTest);
    }
    return null;
  }

  /// Called by the [testWidgets] function after a test is executed.
  void postTest() {
    assert(_fakeAsync != null);
    assert(_clock != null);
    _clock = null;
    _fakeAsync = null;
  }

}
