// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'debug.dart';
import 'mouse_tracker.dart';
import 'object.dart';
import 'view.dart';

export 'package:flutter/gestures.dart' show HitTestResult;

// Examples can assume:
// late BuildContext context;

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
    initMouseTracker();
    if (kIsWeb) {
      addPostFrameCallback(_handleWebFirstFrame);
    }
  }

  /// The current [RendererBinding], if one has been created.
  static RendererBinding? get instance => _instance;
  static RendererBinding? _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    assert(() {
      // these service extensions only work in debug mode
      registerBoolServiceExtension(
        name: 'invertOversizedImages',
        getter: () async => debugInvertOversizedImages,
        setter: (bool value) async {
          if (debugInvertOversizedImages != value) {
            debugInvertOversizedImages = value;
            return _forceRepaint();
          }
          return Future<void>.value();
        },
      );
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
      registerServiceExtension(
        name: 'debugDumpLayerTree',
        callback: (Map<String, String> parameters) async {
          final String data = RendererBinding.instance?.renderView.debugLayer?.toStringDeep() ?? 'Layer tree unavailable.';
          return <String, Object>{
            'data': data,
          };
        },
      );
      return true;
    }());

    if (!kReleaseMode) {
      // these service extensions work in debug or profile mode
      registerServiceExtension(
        name: 'debugDumpRenderTree',
        callback: (Map<String, String> parameters) async {
          final String data = RendererBinding.instance?.renderView.toStringDeep() ?? 'Render tree unavailable.';
          return <String, Object>{
            'data': data,
          };
        },
      );

      registerServiceExtension(
        name: 'debugDumpSemanticsTreeInTraversalOrder',
        callback: (Map<String, String> parameters) async {
          final String data = RendererBinding.instance?.renderView.debugSemantics
            ?.toStringDeep(childOrder: DebugSemanticsDumpOrder.traversalOrder) ?? 'Semantics not collected.';
          return <String, Object>{
            'data': data,
          };
        },
      );

      registerServiceExtension(
        name: 'debugDumpSemanticsTreeInInverseHitTestOrder',
        callback: (Map<String, String> parameters) async {
          final String data = RendererBinding.instance?.renderView.debugSemantics
            ?.toStringDeep(childOrder: DebugSemanticsDumpOrder.inverseHitTest) ?? 'Semantics not collected.';
          return <String, Object>{
            'data': data,
          };
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
    assert(!_debugIsRenderViewInitialized);
    assert(() {
      _debugIsRenderViewInitialized = true;
      return true;
    }());
    renderView = RenderView(configuration: createViewConfiguration(), window: window);
    renderView.prepareInitialFrame();
  }
  bool _debugIsRenderViewInitialized = false;

  /// The object that manages state about currently connected mice, for hover
  /// notification.
  MouseTracker get mouseTracker => _mouseTracker!;
  MouseTracker? _mouseTracker;

  /// The render tree's owner, which maintains dirty state for layout,
  /// composite, paint, and accessibility semantics.
  PipelineOwner get pipelineOwner => _pipelineOwner;
  late PipelineOwner _pipelineOwner;

  /// The render tree that's attached to the output surface.
  RenderView get renderView => _pipelineOwner.rootNode! as RenderView;
  /// Sets the given [RenderView] object (which must not be null), and its tree, to
  /// be the new render tree to display. The previous tree, if any, is detached.
  set renderView(RenderView value) {
    assert(value != null);
    _pipelineOwner.rootNode = value;
  }

  /// Called when the system metrics change.
  ///
  /// See [dart:ui.PlatformDispatcher.onMetricsChanged].
  @protected
  void handleMetricsChanged() {
    assert(renderView != null);
    renderView.configuration = createViewConfiguration();
    scheduleForcedFrame();
  }

  /// Called when the platform text scale factor changes.
  ///
  /// See [dart:ui.PlatformDispatcher.onTextScaleFactorChanged].
  @protected
  void handleTextScaleFactorChanged() { }

  /// Called when the platform brightness changes.
  ///
  /// The current platform brightness can be queried from a Flutter binding or
  /// from a [MediaQuery] widget. The latter is preferred from widgets because
  /// it causes the widget to be automatically rebuilt when the brightness
  /// changes.
  ///
  /// {@tool snippet}
  /// Querying [MediaQuery] directly. Preferred.
  ///
  /// ```dart
  /// final Brightness brightness = MediaQuery.platformBrightnessOf(context);
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  /// Querying [PlatformDispatcher.platformBrightness].
  ///
  /// ```dart
  /// final Brightness brightness = WidgetsBinding.instance!.platformDispatcher.platformBrightness;
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  /// Querying [MediaQueryData].
  ///
  /// ```dart
  /// final MediaQueryData mediaQueryData = MediaQuery.of(context);
  /// final Brightness brightness = mediaQueryData.platformBrightness;
  /// ```
  /// {@end-tool}
  ///
  /// See [dart:ui.PlatformDispatcher.onPlatformBrightnessChanged].
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

  SemanticsHandle? _semanticsHandle;

  /// Creates a [MouseTracker] which manages state about currently connected
  /// mice, for hover notification.
  ///
  /// Used by testing framework to reinitialize the mouse tracker between tests.
  @visibleForTesting
  void initMouseTracker([MouseTracker? tracker]) {
    _mouseTracker?.dispose();
    _mouseTracker = tracker ?? MouseTracker();
  }

  @override // from GestureBinding
  void dispatchEvent(PointerEvent event, HitTestResult? hitTestResult) {
    _mouseTracker!.updateWithEvent(
      event,
      // Enter and exit events should be triggered with or without buttons
      // pressed. When the button is pressed, normal hit test uses a cached
      // result, but MouseTracker requires that the hit test is re-executed to
      // update the hovering events.
      () => (hitTestResult == null || event is PointerMoveEvent) ? renderView.hitTestMouseTrackers(event.position) : hitTestResult,
    );
    super.dispatchEvent(event, hitTestResult);
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

  void _handleWebFirstFrame(Duration _) {
    assert(kIsWeb);
    const MethodChannel methodChannel = MethodChannel('flutter/service_worker');
    methodChannel.invokeMethod<void>('first-frame');
  }

  void _handleSemanticsAction(int id, SemanticsAction action, ByteData? args) {
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
    _scheduleMouseTrackerUpdate();
  }

  bool _debugMouseTrackerUpdateScheduled = false;
  void _scheduleMouseTrackerUpdate() {
    assert(!_debugMouseTrackerUpdateScheduled);
    assert(() {
      _debugMouseTrackerUpdateScheduled = true;
      return true;
    }());
    SchedulerBinding.instance!.addPostFrameCallback((Duration duration) {
      assert(_debugMouseTrackerUpdateScheduled);
      assert(() {
        _debugMouseTrackerUpdateScheduled = false;
        return true;
      }());
      _mouseTracker!.updateAllDevices(renderView.hitTestMouseTrackers);
    });
  }

  int _firstFrameDeferredCount = 0;
  bool _firstFrameSent = false;

  /// Whether frames produced by [drawFrame] are sent to the engine.
  ///
  /// If false the framework will do all the work to produce a frame,
  /// but the frame is never sent to the engine to actually appear on screen.
  ///
  /// See also:
  ///
  ///  * [deferFirstFrame], which defers when the first frame is sent to the
  ///    engine.
  bool get sendFramesToEngine => _firstFrameSent || _firstFrameDeferredCount == 0;

  /// Tell the framework to not send the first frames to the engine until there
  /// is a corresponding call to [allowFirstFrame].
  ///
  /// Call this to perform asynchronous initialization work before the first
  /// frame is rendered (which takes down the splash screen). The framework
  /// will still do all the work to produce frames, but those frames are never
  /// sent to the engine and will not appear on screen.
  ///
  /// Calling this has no effect after the first frame has been sent to the
  /// engine.
  void deferFirstFrame() {
    assert(_firstFrameDeferredCount >= 0);
    _firstFrameDeferredCount += 1;
  }

  /// Called after [deferFirstFrame] to tell the framework that it is ok to
  /// send the first frame to the engine now.
  ///
  /// For best performance, this method should only be called while the
  /// [schedulerPhase] is [SchedulerPhase.idle].
  ///
  /// This method may only be called once for each corresponding call
  /// to [deferFirstFrame].
  void allowFirstFrame() {
    assert(_firstFrameDeferredCount > 0);
    _firstFrameDeferredCount -= 1;
    // Always schedule a warm up frame even if the deferral count is not down to
    // zero yet since the removal of a deferral may uncover new deferrals that
    // are lower in the widget tree.
    if (!_firstFrameSent)
      scheduleWarmUpFrame();
  }

  /// Call this to pretend that no frames have been sent to the engine yet.
  ///
  /// This is useful for tests that want to call [deferFirstFrame] and
  /// [allowFirstFrame] since those methods only have an effect if no frames
  /// have been sent to the engine yet.
  void resetFirstFrameSent() {
    _firstFrameSent = false;
  }

  /// Pump the rendering pipeline to generate a frame.
  ///
  /// This method is called by [handleDrawFrame], which itself is called
  /// automatically by the engine when it is time to lay out and paint a frame.
  ///
  /// Each frame consists of the following phases:
  ///
  /// 1. The animation phase: The [handleBeginFrame] method, which is registered
  /// with [PlatformDispatcher.onBeginFrame], invokes all the transient frame
  /// callbacks registered with [scheduleFrameCallback], in registration order.
  /// This includes all the [Ticker] instances that are driving
  /// [AnimationController] objects, which means all of the active [Animation]
  /// objects tick at this point.
  ///
  /// 2. Microtasks: After [handleBeginFrame] returns, any microtasks that got
  /// scheduled by transient frame callbacks get to run. This typically includes
  /// callbacks for futures from [Ticker]s and [AnimationController]s that
  /// completed this frame.
  ///
  /// After [handleBeginFrame], [handleDrawFrame], which is registered with
  /// [dart:ui.PlatformDispatcher.onDrawFrame], is called, which invokes all the
  /// persistent frame callbacks, of which the most notable is this method,
  /// [drawFrame], which proceeds as follows:
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
  /// their semantics updated. This generates the [SemanticsNode] tree. See
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
    if (sendFramesToEngine) {
      renderView.compositeFrame(); // this sends the bits to the GPU
      pipelineOwner.flushSemantics(); // this also sends the semantics to the OS.
      _firstFrameSent = true;
    }
  }

  @override
  Future<void> performReassemble() async {
    await super.performReassemble();
    if (BindingBase.debugReassembleConfig?.widgetName == null) {
      Timeline.startSync('Dirty Render Tree', arguments: timelineArgumentsIndicatingLandmarkEvent);
      try {
        renderView.reassemble();
      } finally {
        Timeline.finishSync();
      }
    }
    scheduleWarmUpFrame();
    await endOfFrame;
  }

  @override
  void hitTest(HitTestResult result, Offset position) {
    assert(renderView != null);
    assert(result != null);
    assert(position != null);
    renderView.hitTest(result, position: position);
    super.hitTest(result, position);
  }

  Future<void> _forceRepaint() {
    late RenderObjectVisitor visitor;
    visitor = (RenderObject child) {
      child.markNeedsPaint();
      child.visitChildren(visitor);
    };
    instance?.renderView.visitChildren(visitor);
    return endOfFrame;
  }
}

/// Prints a textual representation of the entire render tree.
void debugDumpRenderTree() {
  debugPrint(RendererBinding.instance?.renderView.toStringDeep() ?? 'Render tree unavailable.');
}

/// Prints a textual representation of the entire layer tree.
void debugDumpLayerTree() {
  debugPrint(RendererBinding.instance?.renderView.debugLayer?.toStringDeep() ?? 'Layer tree unavailable.');
}

/// Prints a textual representation of the entire semantics tree.
/// This will only work if there is a semantics client attached.
/// Otherwise, a notice that no semantics are available will be printed.
///
/// The order in which the children of a [SemanticsNode] will be printed is
/// controlled by the [childOrder] parameter.
void debugDumpSemanticsTree(DebugSemanticsDumpOrder childOrder) {
  debugPrint(RendererBinding.instance?.renderView.debugSemantics?.toStringDeep(childOrder: childOrder) ?? 'Semantics not collected.');
}

/// A concrete binding for applications that use the Rendering framework
/// directly. This is the glue that binds the framework to the Flutter engine.
///
/// You would only use this binding if you are writing to the
/// rendering layer directly. If you are writing to a higher-level
/// library, such as the Flutter Widgets library, then you would use
/// that layer's binding.
class RenderingFlutterBinding extends BindingBase with GestureBinding, SchedulerBinding, ServicesBinding, SemanticsBinding, PaintingBinding, RendererBinding {
  /// Creates a binding for the rendering layer.
  ///
  /// The `root` render box is attached directly to the [renderView] and is
  /// given constraints that require it to fill the window.
  ///
  /// This binding does not automatically schedule any frames. Callers are
  /// responsible for deciding when to first call [scheduleFrame].
  RenderingFlutterBinding({ RenderBox? root }) {
    assert(renderView != null);
    renderView.child = root;
  }
}
