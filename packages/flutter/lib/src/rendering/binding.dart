// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';
import 'view.dart';

export 'package:flutter/gestures.dart' show HitTestResult;

// Examples can assume:
// dynamic context;

/// The glue between the render tree and the Flutter engine.
mixin RendererBinding on BindingBase, ServicesBinding, SchedulerBinding, GestureBinding, SemanticsBinding, HitTestable {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _pipelineOwner = PipelineOwner(
      onNeedVisualUpdate: ensureVisualUpdate,
      onSemanticsOwnerCreated: _handleSemanticsOwnerCreated,
      onSemanticsOwnerDisposed: _handleSemanticsOwnerDisposed,
    );
    window
      ..onMetricsChanged = handleMetricsChanged
      ..onTextScaleFactorChanged = handleTextScaleFactorChanged
      ..onPlatformBrightnessChanged = handlePlatformBrightnessChanged
      ..onSemanticsEnabledChanged = _handleSemanticsEnabledChanged
      ..onSemanticsAction = _handleSemanticsAction;
    initRenderView();
    _handleSemanticsEnabledChanged();
    assert(renderView != null);
    addPersistentFrameCallback(_handlePersistentFrameCallback);
    _mouseTracker = _createMouseTracker();
  }

  /// The current [RendererBinding], if one has been created.
  static RendererBinding get instance => _instance;
  static RendererBinding _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    assert(() {
      // these service extensions only work in debug mode
      registerBoolServiceExtension(
        name: 'debugPaint',
        getter: () async => debugPaintSizeEnabled,
        setter: (bool value) {
          if (debugPaintSizeEnabled == value)
            return Future<void>.value();
          debugPaintSizeEnabled = value;
          return _forceRepaint();
        },
      );
      registerBoolServiceExtension(
        name: 'debugPaintBaselinesEnabled',
        getter: () async => debugPaintBaselinesEnabled,
        setter: (bool value) {
          if (debugPaintBaselinesEnabled == value)
            return Future<void>.value();
          debugPaintBaselinesEnabled = value;
          return _forceRepaint();
        },
      );
      registerBoolServiceExtension(
        name: 'repaintRainbow',
        getter: () async => debugRepaintRainbowEnabled,
        setter: (bool value) {
          final bool repaint = debugRepaintRainbowEnabled && !value;
          debugRepaintRainbowEnabled = value;
          if (repaint)
            return _forceRepaint();
          return Future<void>.value();
        },
      );
      registerBoolServiceExtension(
        name: 'debugCheckElevationsEnabled',
        getter: () async => debugCheckElevationsEnabled,
        setter: (bool value) {
          if (debugCheckElevationsEnabled == value) {
            return Future<void>.value();
          }
          debugCheckElevationsEnabled = value;
          return _forceRepaint();
        }
      );
      registerSignalServiceExtension(
        name: 'debugDumpLayerTree',
        callback: () {
          debugDumpLayerTree();
          return debugPrintDone;
        },
      );
      return true;
    }());

    if (!kReleaseMode) {
      // these service extensions work in debug or profile mode
      registerSignalServiceExtension(
        name: 'debugDumpRenderTree',
        callback: () {
          debugDumpRenderTree();
          return debugPrintDone;
        },
      );

      registerSignalServiceExtension(
        name: 'debugDumpSemanticsTreeInTraversalOrder',
        callback: () {
          debugDumpSemanticsTree(DebugSemanticsDumpOrder.traversalOrder);
          return debugPrintDone;
        },
      );

      registerSignalServiceExtension(
        name: 'debugDumpSemanticsTreeInInverseHitTestOrder',
        callback: () {
          debugDumpSemanticsTree(DebugSemanticsDumpOrder.inverseHitTest);
          return debugPrintDone;
        },
      );
    }
  }

  /// Creates a [RenderView] object to be the root of the
  /// [RenderObject] rendering tree, and initializes it so that it
  /// will be rendered when the next frame is requested.
  ///
  /// Called automatically when the binding is created.
  void initRenderView() {
    assert(renderView == null);
    renderView = RenderView(configuration: createViewConfiguration(), window: window);
    renderView.prepareInitialFrame();
  }

  /// The object that manages state about currently connected mice, for hover
  /// notification.
  MouseTracker get mouseTracker => _mouseTracker;
  MouseTracker _mouseTracker;

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
  @protected
  void handleMetricsChanged() {
    assert(renderView != null);
    renderView.configuration = createViewConfiguration();
    scheduleForcedFrame();
  }

  /// Called when the platform text scale factor changes.
  ///
  /// See [Window.onTextScaleFactorChanged].
  @protected
  void handleTextScaleFactorChanged() { }

  /// {@template on_platform_brightness_change}
  /// Called when the platform brightness changes.
  ///
  /// The current platform brightness can be queried either from a Flutter
  /// binding, or from a [MediaQuery] widget.
  ///
  /// {@tool sample}
  /// Querying [Window.platformBrightness].
  ///
  /// ```dart
  /// final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
  /// ```
  /// {@end-tool}
  ///
  /// {@tool sample}
  /// Querying [MediaQuery] directly.
  ///
  /// ```dart
  /// final Brightness brightness = MediaQuery.platformBrightnessOf(context);
  /// ```
  /// {@end-tool}
  ///
  /// {@tool sample}
  /// Querying [MediaQueryData].
  ///
  /// ```dart
  /// final MediaQueryData mediaQueryData = MediaQuery.of(context);
  /// final Brightness brightness = mediaQueryData.platformBrightness;
  /// ```
  /// {@end-tool}
  ///
  /// See [Window.onPlatformBrightnessChanged].
  /// {@endtemplate}
  @protected
  void handlePlatformBrightnessChanged() { }

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
    final double devicePixelRatio = window.devicePixelRatio;
    return ViewConfiguration(
      size: window.physicalSize / devicePixelRatio,
      devicePixelRatio: devicePixelRatio,
    );
  }

  SemanticsHandle _semanticsHandle;

  // Creates a [MouseTracker] which manages state about currently connected
  // mice, for hover notification.
  MouseTracker _createMouseTracker() {
    return MouseTracker(pointerRouter, renderView.hitTestMouseTrackers);
  }

  void _handleSemanticsEnabledChanged() {
    setSemanticsEnabled(window.semanticsEnabled);
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

  void _handleSemanticsAction(int id, SemanticsAction action, ByteData args) {
    _pipelineOwner.semanticsOwner?.performAction(
      id,
      action,
      args != null ? const StandardMessageCodec().decodeMessage(args) : null,
    );
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
  /// automatically by the engine when it is time to lay out and paint a frame.
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

  @override
  Future<void> performReassemble() async {
    await super.performReassemble();
    Timeline.startSync('Dirty Render Tree', arguments: timelineWhitelistArguments);
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
    super.hitTest(result, position);
  }

  Future<void> _forceRepaint() {
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
  debugPrint(RendererBinding.instance?.renderView?.toStringDeep() ?? 'Render tree unavailable.');
}

/// Prints a textual representation of the entire layer tree.
void debugDumpLayerTree() {
  debugPrint(RendererBinding.instance?.renderView?.debugLayer?.toStringDeep() ?? 'Layer tree unavailable.');
}

/// Prints a textual representation of the entire semantics tree.
/// This will only work if there is a semantics client attached.
/// Otherwise, a notice that no semantics are available will be printed.
///
/// The order in which the children of a [SemanticsNode] will be printed is
/// controlled by the [childOrder] parameter.
void debugDumpSemanticsTree(DebugSemanticsDumpOrder childOrder) {
  debugPrint(RendererBinding.instance?.renderView?.debugSemantics?.toStringDeep(childOrder: childOrder) ?? 'Semantics not collected.');
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
class RenderingFlutterBinding extends BindingBase with GestureBinding, ServicesBinding, SchedulerBinding, SemanticsBinding, RendererBinding {
  /// Creates a binding for the rendering layer.
  ///
  /// The `root` render box is attached directly to the [renderView] and is
  /// given constraints that require it to fill the window.
  RenderingFlutterBinding({ RenderBox root }) {
    assert(renderView != null);
    renderView.child = root;
  }
}
