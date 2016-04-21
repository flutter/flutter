// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/testing/async.dart';
import 'package:quiver/time.dart';

import 'instrumentation.dart';

/// Enumeration of possible phases to reach in pumpWidget.
// TODO(ianh): Merge with identical code in the rendering test code.
enum EnginePhase {
  layout,
  compositingBits,
  paint,
  composite,
  flushSemantics,
  sendSemanticsTree
}

class _SteppedWidgetFlutterBinding extends WidgetsFlutterBinding { // TODO(ianh): refactor so we're not extending a concrete binding
  _SteppedWidgetFlutterBinding(this.async);

  final FakeAsync async;

  /// Creates and initializes the binding. This constructor is
  /// idempotent; calling it a second time will just return the
  /// previously-created instance.
  static WidgetsBinding ensureInitialized(FakeAsync async) {
    if (WidgetsBinding.instance == null)
      new _SteppedWidgetFlutterBinding(async);
    return WidgetsBinding.instance;
  }

  EnginePhase phase = EnginePhase.sendSemanticsTree;

  // Pump the rendering pipeline up to the given phase.
  @override
  void beginFrame() {
    buildOwner.buildDirtyElements();
    _beginFrame();
    buildOwner.finalizeTree();
  }

  // Cloned from RendererBinding.beginFrame() but with early-exit semantics.
  void _beginFrame() {
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
    super.dispatchEvent(event, result);
    async.flushMicrotasks();
  }
}

/// Helper class for flutter tests providing fake async.
///
/// This class extends Instrumentation to also abstract away the beginFrame
/// and async/clock access to allow writing tests which depend on the passage
/// of time without actually moving the clock forward.
class ElementTreeTester extends Instrumentation {
  ElementTreeTester._(FakeAsync async)
    : async = async,
      clock = async.getClock(new DateTime.utc(2015, 1, 1)),
      super(binding: _SteppedWidgetFlutterBinding.ensureInitialized(async)) {
    timeDilation = 1.0;
    ui.window.onBeginFrame = null;
    debugPrint = _synchronousDebugPrint;
  }

  void _synchronousDebugPrint(String message, { int wrapWidth }) {
    if (wrapWidth != null) {
      print(message.split('\n').expand((String line) => debugWordWrap(line, wrapWidth)).join('\n'));
    } else {
      print(message);
    }
  }


  final FakeAsync async;
  final Clock clock;

  /// Calls [runApp] with the given widget, then triggers a frame sequence and
  /// flushes microtasks, by calling [pump] with the same duration (if any).
  /// The supplied [EnginePhase] is the final phase reached during the pump pass;
  /// if not supplied, the whole pass is executed.
  void pumpWidget(Widget widget, [ Duration duration, EnginePhase phase ]) {
    runApp(widget);
    pump(duration, phase);
  }

  /// Triggers a frame sequence (build/layout/paint/etc),
  /// then flushes microtasks.
  ///
  /// If duration is set, then advances the clock by that much first.
  /// Doing this flushes microtasks.
  ///
  /// The supplied EnginePhase is the final phase reached during the pump pass;
  /// if not supplied, the whole pass is executed.
  void pump([ Duration duration, EnginePhase phase ]) {
    if (duration != null)
      async.elapse(duration);
    if (binding is _SteppedWidgetFlutterBinding) {
      // Some tests call WidgetsFlutterBinding.ensureInitialized() manually, so
      // we can't actually be sure we have a stepped binding.
      _SteppedWidgetFlutterBinding steppedBinding = binding;
      steppedBinding.phase = phase ?? EnginePhase.sendSemanticsTree;
    } else {
      // Can't step to a given phase in that case
      assert(phase == null);
    }
    binding.handleBeginFrame(new Duration(
      milliseconds: clock.now().millisecondsSinceEpoch)
    );
    async.flushMicrotasks();
  }

  /// Artificially calls dispatchLocaleChanged on the Widget binding,
  /// then flushes microtasks.
  void setLocale(String languageCode, String countryCode) {
    Locale locale = new Locale(languageCode, countryCode);
    binding.dispatchLocaleChanged(locale);
    async.flushMicrotasks();
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
    dynamic result = _pendingException;
    _pendingException = null;
    return result;
  }
  dynamic _pendingException;
}

void testElementTree(callback(ElementTreeTester tester)) {
  new FakeAsync().run((FakeAsync async) {
    FlutterExceptionHandler oldHandler = FlutterError.onError;
    ElementTreeTester tester = new ElementTreeTester._(async);
    try {
      FlutterError.onError = (FlutterErrorDetails details) {
        if (tester._pendingException != null) {
          FlutterError.dumpErrorToConsole(tester._pendingException);
          FlutterError.dumpErrorToConsole(details.exception);
          tester._pendingException = 'An uncaught exception was thrown.';
          throw details.exception;
        }
        tester._pendingException = details;
      };
      runApp(new Container(key: new UniqueKey())); // Reset the tree to a known state.
      callback(tester);
      runApp(new Container(key: new UniqueKey())); // Unmount any remaining widgets.
      async.flushMicrotasks();
      assert(SchedulerBinding.instance.debugAssertNoTransientCallbacks(
        'An animation is still running even after the widget tree was disposed.'
      ));
      assert(() {
        'A Timer is still running even after the widget tree was disposed.';
        return async.periodicTimerCount == 0;
      });
      assert(() {
        'A Timer is still running even after the widget tree was disposed.';
        return async.nonPeriodicTimerCount == 0;
      });
      assert(async.microtaskCount == 0); // Shouldn't be possible.
      if (tester._pendingException != null)
        throw 'An exception (shown above) was thrown during the test.';
    } finally {
      FlutterError.onError = oldHandler;
      if (tester._pendingException != null) {
        FlutterError.dumpErrorToConsole(tester._pendingException);
        tester._pendingException = null;
      }
    }
  });
}
