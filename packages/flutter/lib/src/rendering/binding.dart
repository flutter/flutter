// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';
import 'semantics.dart';
import 'view.dart';

export 'package:flutter/gestures.dart' show HitTestResult;

/// The glue between the render tree and the Flutter engine.
abstract class RendererBinding extends BindingBase with SchedulerBinding, ServicesBinding, HitTestable {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory RendererBinding._() => null;

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _pipelineOwner = new PipelineOwner(
      onNeedVisualUpdate: ensureVisualUpdate,
      onSemanticsOwnerCreated: _handleSemanticsOwnerCreated,
      onSemanticsOwnerDisposed: _handleSemanticsOwnerDisposed,
    );
    ui.window
      ..onMetricsChanged = handleMetricsChanged
      ..onSemanticsEnabledChanged = _handleSemanticsEnabledChanged
      ..onSemanticsAction = _handleSemanticsAction;
    initRenderView();
    _handleSemanticsEnabledChanged();
    assert(renderView != null);
    addPersistentFrameCallback(_handlePersistentFrameCallback);
  }

  /// The current [RendererBinding], if one has been created.
  static RendererBinding get instance => _instance;
  static RendererBinding _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    assert(() {
      // these service extensions only work in checked mode
      registerBoolServiceExtension(
        name: 'debugPaint',
        getter: () async => debugPaintSizeEnabled,
        setter: (bool value) {
          if (debugPaintSizeEnabled == value)
            return new Future<Null>.value();
          debugPaintSizeEnabled = value;
          return _forceRepaint();
        }
      );
      registerBoolServiceExtension(
          name: 'debugPaintBaselinesEnabled',
          getter: () async => debugPaintBaselinesEnabled,
          setter: (bool value) {
          if (debugPaintBaselinesEnabled == value)
            return new Future<Null>.value();
          debugPaintBaselinesEnabled = value;
          return _forceRepaint();
        }
      );
      registerBoolServiceExtension(
          name: 'repaintRainbow',
          getter: () async => debugRepaintRainbowEnabled,
          setter: (bool value) {
            final bool repaint = debugRepaintRainbowEnabled && !value;
            debugRepaintRainbowEnabled = value;
            if (repaint)
              return _forceRepaint();
            return new Future<Null>.value();
          }
      );
      return true;
    });

    registerSignalServiceExtension(
      name: 'debugDumpRenderTree',
      callback: () { debugDumpRenderTree(); return debugPrintDone; }
    );

    registerSignalServiceExtension(
      name: 'debugDumpLayerTree',
      callback: () { debugDumpLayerTree(); return debugPrintDone; }
    );

    registerSignalServiceExtension(
      name: 'debugDumpSemanticsTree',
      callback: () { debugDumpSemanticsTree(); return debugPrintDone; }
    );
  }

  /// Creates a [RenderView] object to be the root of the
  /// [RenderObject] rendering tree, and initializes it so that it
  /// will be rendered when the engine is next ready to display a
  /// frame.
  ///
  /// Called automatically when the binding is created.
  void initRenderView() {
    assert(renderView == null);
    renderView = new RenderView(configuration: createViewConfiguration());
    renderView.scheduleInitialFrame();
  }

  /// The render tree's owner, which maintains dirty state for layout,
  /// composite, paint, and accessibility semantics
  PipelineOwner get pipelineOwner => _pipelineOwner;
  PipelineOwner _pipelineOwner;

  /// The render tree that's attached to the output surface.
  RenderView get renderView => _pipelineOwner.rootNode;
  /// Sets the given [RenderView] object (which must not be null), and its tree, to
  /// be the new render tree to display. The previous tree, if any, is detached.
  set renderView(RenderView value) {
    assert(value != null);
    _pipelineOwner.rootNode = value;
  }

  /// Called when the system metrics change.
  ///
  /// See [Window.onMetricsChanged].
  void handleMetricsChanged() {
    assert(renderView != null);
    renderView.configuration = createViewConfiguration();
  }

  /// Returns a [ViewConfiguration] configured for the [RenderView] based on the
  /// current environment.
  ///
  /// This is called during construction and also in response to changes to the
  /// system metrics.
  ///
  /// Bindings can override this method to change what size or device pixel
  /// ratio the [RenderView] will use. For example, the testing framework uses
  /// this to force the display into 800x600 when a test is run on the device
  /// using `flutter run`.
  ViewConfiguration createViewConfiguration() {
    final double devicePixelRatio = ui.window.devicePixelRatio;
    return new ViewConfiguration(
      size: ui.window.physicalSize / devicePixelRatio,
      devicePixelRatio: devicePixelRatio,
    );
  }

  SemanticsHandle _semanticsHandle;

  void _handleSemanticsEnabledChanged() {
    setSemanticsEnabled(ui.window.semanticsEnabled);
  }

  /// Whether the render tree associated with this binding should produce a tree
  /// of [SemanticsNode] objects.
  void setSemanticsEnabled(bool enabled) {
    if (enabled) {
      _semanticsHandle ??= _pipelineOwner.ensureSemantics();
    } else {
      _semanticsHandle?.dispose();
      _semanticsHandle = null;
    }
  }

  void _handleSemanticsAction(int id, SemanticsAction action) {
    _pipelineOwner.semanticsOwner?.performAction(id, action);
  }

  void _handleSemanticsOwnerCreated() {
    renderView.scheduleInitialSemantics();
  }

  void _handleSemanticsOwnerDisposed() {
    renderView.clearSemantics();
  }

  void _handlePersistentFrameCallback(Duration timeStamp) {
    drawFrame();
  }

  /// Pump the rendering pipeline to generate a frame.
  ///
  /// This method is called by [handleDrawFrame], which itself is called
  /// automatically by the engine when when it is time to lay out and paint a
  /// frame.
  ///
  /// Each frame consists of the following phases:
  ///
  /// 1. The animation phase: The [handleBeginFrame] method, which is registered
  /// with [Window.onBeginFrame], invokes all the transient frame callbacks
  /// registered with [scheduleFrameCallback], in registration order. This
  /// includes all the [Ticker] instances that are driving [AnimationController]
  /// objects, which means all of the active [Animation] objects tick at this
  /// point.
  ///
  /// 2. Microtasks: After [handleBeginFrame] returns, any microtasks that got
  /// scheduled by transient frame callbacks get to run. This typically includes
  /// callbacks for futures from [Ticker]s and [AnimationController]s that
  /// completed this frame.
  ///
  /// After [handleBeginFrame], [handleDrawFrame], which is registered with
  /// [Window.onDrawFrame], is called, which invokes all the persistent frame
  /// callbacks, of which the most notable is this method, [drawFrame], which
  /// proceeds as follows:
  ///
  /// 3. The layout phase: All the dirty [RenderObject]s in the system are laid
  /// out (see [RenderObject.performLayout]). See [RenderObject.markNeedsLayout]
  /// for further details on marking an object dirty for layout.
  ///
  /// 4. The compositing bits phase: The compositing bits on any dirty
  /// [RenderObject] objects are updated. See
  /// [RenderObject.markNeedsCompositingBitsUpdate].
  ///
  /// 5. The paint phase: All the dirty [RenderObject]s in the system are
  /// repainted (see [RenderObject.paint]). This generates the [Layer] tree. See
  /// [RenderObject.markNeedsPaint] for further details on marking an object
  /// dirty for paint.
  ///
  /// 6. The compositing phase: The layer tree is turned into a [Scene] and
  /// sent to the GPU.
  ///
  /// 7. The semantics phase: All the dirty [RenderObject]s in the system have
  /// their semantics updated (see [RenderObject.semanticsAnnotator]). This
  /// generates the [SemanticsNode] tree. See
  /// [RenderObject.markNeedsSemanticsUpdate] for further details on marking an
  /// object dirty for semantics.
  ///
  /// For more details on steps 3-7, see [PipelineOwner].
  ///
  /// 8. The finalization phase: After [drawFrame] returns, [handleDrawFrame]
  /// then invokes post-frame callbacks (registered with [addPostFrameCallback]).
  ///
  /// Some bindings (for example, the [WidgetsBinding]) add extra steps to this
  /// list (for example, see [WidgetsBinding.drawFrame]).
  //
  // When editing the above, also update widgets/binding.dart's copy.
  @protected
  void drawFrame() {
    assert(renderView != null);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();
    renderView.compositeFrame(); // this sends the bits to the GPU
    pipelineOwner.flushSemantics(); // this also sends the semantics to the OS.
  }

  /// Schedule a frame to run as soon as possible, rather than waiting for
  /// the engine to request a frame.
  ///
  /// This is used during application startup so that the first frame (which is
  /// likely to be quite expensive) gets a few extra milliseconds to run.
  void scheduleWarmUpFrame() {
    // We use timers here to ensure that microtasks flush in between.
    //
    // We call resetEpoch after this frame so that, in the hot reload case, the
    // very next frame pretends to have occurred immediately after this warm-up
    // frame. The warm-up frame's timestamp will typically be far in the past
    // (the time of the last real frame), so if we didn't reset the epoch we
    // would see a sudden jump from the old time in the warm-up frame to the new
    // time in the "real" frame. The biggest problem with this is that implicit
    // animations end up being triggered at the old time and then skipping every
    // frame and finishing in the new time.
    Timer.run(() { handleBeginFrame(null); });
    Timer.run(() { handleDrawFrame(); resetEpoch(); });
  }

  @override
  Future<Null> reassembleApplication() async {
    await super.reassembleApplication();
    Timeline.startSync('Dirty Render Tree');
    try {
      renderView.reassemble();
    } finally {
      Timeline.finishSync();
    }
    scheduleWarmUpFrame();
    await endOfFrame;
  }

  @override
  void hitTest(HitTestResult result, Offset position) {
    assert(renderView != null);
    renderView.hitTest(result, position: position);
    // This super call is safe since it will be bound to a mixed-in declaration.
    super.hitTest(result, position); // ignore: abstract_super_member_reference
  }

  Future<Null> _forceRepaint() {
    RenderObjectVisitor visitor;
    visitor = (RenderObject child) {
      child.markNeedsPaint();
      child.visitChildren(visitor);
    };
    instance?.renderView?.visitChildren(visitor);
    return endOfFrame;
  }
}

/// Prints a textual representation of the entire render tree.
void debugDumpRenderTree() {
  debugPrint(RendererBinding.instance?.renderView?.toStringDeep());
}

/// Prints a textual representation of the entire layer tree.
void debugDumpLayerTree() {
  debugPrint(RendererBinding.instance?.renderView?.debugLayer?.toStringDeep());
}

/// Prints a textual representation of the entire semantics tree.
/// This will only work if there is a semantics client attached.
/// Otherwise, the tree is empty and this will print "null".
void debugDumpSemanticsTree() {
  debugPrint(RendererBinding.instance?.renderView?.debugSemantics?.toStringDeep() ?? 'Semantics not collected.');
}

/// A concrete binding for applications that use the Rendering framework
/// directly. This is the glue that binds the framework to the Flutter engine.
///
/// You would only use this binding if you are writing to the
/// rendering layer directly. If you are writing to a higher-level
/// library, such as the Flutter Widgets library, then you would use
/// that layer's binding.
///
/// See also [BindingBase].
class RenderingFlutterBinding extends BindingBase with SchedulerBinding, GestureBinding, ServicesBinding, RendererBinding {
  /// Creates a binding for the rendering layer.
  ///
  /// The `root` render box is attached directly to the [renderView] and is
  /// given constraints that require it to fill the window.
  RenderingFlutterBinding({ RenderBox root }) {
    assert(renderView != null);
    renderView.child = root;
  }
}
