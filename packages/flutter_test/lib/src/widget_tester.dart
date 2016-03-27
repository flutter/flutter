// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;

import 'package:quiver/testing/async.dart';
import 'package:quiver/time.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'instrumentation.dart';

/// Enumeration of possible phases to reach in pumpWidget.
enum EnginePhase {
  layout,
  compositingBits,
  paint,
  composite,
  flushSemantics,
  sendSemanticsTree
}

class _SteppedWidgetFlutterBinding extends WidgetFlutterBinding {

  /// Creates and initializes the binding. This constructor is
  /// idempotent; calling it a second time will just return the
  /// previously-created instance.
  static WidgetFlutterBinding ensureInitialized() {
    if (WidgetFlutterBinding.instance == null)
      new _SteppedWidgetFlutterBinding();
    return WidgetFlutterBinding.instance;
  }

  EnginePhase phase = EnginePhase.sendSemanticsTree;

  // Pump the rendering pipeline up to the given phase.
  @override
  void beginFrame() {
    buildDirtyElements();
    _beginFrame();
    Element.finalizeTree();
  }

  // Cloned from Renderer.beginFrame() but with early-exit semantics.
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
}

/// Helper class for flutter tests providing fake async.
///
/// This class extends Instrumentation to also abstract away the beginFrame
/// and async/clock access to allow writing tests which depend on the passage
/// of time without actually moving the clock forward.
class WidgetTester extends Instrumentation {
  WidgetTester._(FakeAsync async)
    : async = async,
      clock = async.getClock(new DateTime.utc(2015, 1, 1)),
      super(binding: _SteppedWidgetFlutterBinding.ensureInitialized()) {
    timeDilation = 1.0;
    ui.window.onBeginFrame = null;
  }

  final FakeAsync async;
  final Clock clock;

  /// Calls [runApp()] with the given widget, then triggers a frame sequent and
  /// flushes microtasks, by calling [pump()] with the same duration (if any).
  /// The supplied EnginePhase is the final phase reached during the pump pass;
  /// if not supplied, the whole pass is executed.
  void pumpWidget(Widget widget, [ Duration duration, EnginePhase phase ]) {
    if (binding is _SteppedWidgetFlutterBinding) {
      // Some tests call WidgetFlutterBinding.ensureInitialized() manually, so
      // we can't actually be sure we have a stepped binding.
      _SteppedWidgetFlutterBinding steppedBinding = binding;
      steppedBinding.phase = phase ?? EnginePhase.sendSemanticsTree;
    } else {
      // Can't step to a given phase in that case
      assert(phase == null);
    }
    runApp(widget);
    pump(duration);
  }

  /// Artificially calls dispatchLocaleChanged on the Widget binding,
  /// then flushes microtasks.
  void setLocale(String languageCode, String countryCode) {
    Locale locale = new Locale(languageCode, countryCode);
    binding.dispatchLocaleChanged(locale);
    async.flushMicrotasks();
  }

  /// Triggers a frame sequence (build/layout/paint/etc),
  /// then flushes microtasks.
  ///
  /// If duration is set, then advances the clock by that much first.
  /// Doing this flushes microtasks.
  void pump([ Duration duration ]) {
    if (duration != null)
      async.elapse(duration);
    binding.handleBeginFrame(new Duration(
      milliseconds: clock.now().millisecondsSinceEpoch)
    );
    async.flushMicrotasks();
  }

  @override
  void dispatchEvent(PointerEvent event, HitTestResult result) {
    super.dispatchEvent(event, result);
    async.flushMicrotasks();
  }
}

void testWidgets(callback(WidgetTester tester)) {
  new FakeAsync().run((FakeAsync async) {
    WidgetTester tester = new WidgetTester._(async);
    runApp(new Container(key: new UniqueKey())); // Reset the tree to a known state.
    callback(tester);
    runApp(new Container(key: new UniqueKey())); // Unmount any remaining widgets.
    async.flushMicrotasks();
    assert(() {
      "An animation is still running even after the widget tree was disposed.";
      return Scheduler.instance.transientCallbackCount == 0;
    });
    assert(() {
      "A Timer is still running even after the widget tree was disposed.";
      return async.periodicTimerCount == 0;
    });
    assert(() {
      "A Timer is still running even after the widget tree was disposed.";
      return async.nonPeriodicTimerCount == 0;
    });
    assert(async.microtaskCount == 0); // Shouldn't be possible.
  });
}
