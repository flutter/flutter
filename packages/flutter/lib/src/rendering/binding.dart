// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:ui' as ui show SemanticsUpdate;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'debug.dart';
import 'mouse_tracker.dart';
import 'object.dart';
import 'service_extensions.dart';
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
      onSemanticsOwnerCreated: _handleSemanticsOwnerCreated,
      onSemanticsUpdate: _handleSemanticsUpdate,
      onSemanticsOwnerDisposed: _handleSemanticsOwnerDisposed,
    );
    platformDispatcher
      ..onMetricsChanged = handleMetricsChanged
      ..onTextScaleFactorChanged = handleTextScaleFactorChanged
      ..onPlatformBrightnessChanged = handlePlatformBrightnessChanged;
    initRenderView();
    addPersistentFrameCallback(_handlePersistentFrameCallback);
    initMouseTracker();
    if (kIsWeb) {
      addPostFrameCallback(_handleWebFirstFrame);
    }
    _pipelineOwner.attach(_manifold);
  }

  /// The current [RendererBinding], if one has been created.
  ///
  /// Provides access to the features exposed by this mixin. The binding must
  /// be initialized before using this getter; this is typically done by calling
  /// [runApp] or [WidgetsFlutterBinding.ensureInitialized].
  static RendererBinding get instance => BindingBase.checkInstance(_instance);
  static RendererBinding? _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    assert(() {
      // these service extensions only work in debug mode
      registerBoolServiceExtension(
        name: RenderingServiceExtensions.invertOversizedImages.name,
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
        name: RenderingServiceExtensions.debugPaint.name,
        getter: () async => debugPaintSizeEnabled,
        setter: (bool value) {
          if (debugPaintSizeEnabled == value) {
            return Future<void>.value();
          }
          debugPaintSizeEnabled = value;
          return _forceRepaint();
        },
      );
      registerBoolServiceExtension(
        name: RenderingServiceExtensions.debugPaintBaselinesEnabled.name,
        getter: () async => debugPaintBaselinesEnabled,
        setter: (bool value) {
          if (debugPaintBaselinesEnabled == value) {
            return Future<void>.value();
          }
          debugPaintBaselinesEnabled = value;
          return _forceRepaint();
        },
      );
      registerBoolServiceExtension(
        name: RenderingServiceExtensions.repaintRainbow.name,
        getter: () async => debugRepaintRainbowEnabled,
        setter: (bool value) {
          final bool repaint = debugRepaintRainbowEnabled && !value;
          debugRepaintRainbowEnabled = value;
          if (repaint) {
            return _forceRepaint();
          }
          return Future<void>.value();
        },
      );
      registerServiceExtension(
        name: RenderingServiceExtensions.debugDumpLayerTree.name,
        callback: (Map<String, String> parameters) async {
          final String data = RendererBinding.instance.renderView.debugLayer?.toStringDeep() ?? 'Layer tree unavailable.';
          return <String, Object>{
            'data': data,
          };
        },
      );
      registerBoolServiceExtension(
        name: RenderingServiceExtensions.debugDisableClipLayers.name,
        getter: () async => debugDisableClipLayers,
        setter: (bool value) {
          if (debugDisableClipLayers == value) {
            return Future<void>.value();
          }
          debugDisableClipLayers = value;
          return _forceRepaint();
        },
      );
      registerBoolServiceExtension(
        name: RenderingServiceExtensions.debugDisablePhysicalShapeLayers.name,
        getter: () async => debugDisablePhysicalShapeLayers,
        setter: (bool value) {
          if (debugDisablePhysicalShapeLayers == value) {
            return Future<void>.value();
          }
          debugDisablePhysicalShapeLayers = value;
          return _forceRepaint();
        },
      );
      registerBoolServiceExtension(
        name: RenderingServiceExtensions.debugDisableOpacityLayers.name,
        getter: () async => debugDisableOpacityLayers,
        setter: (bool value) {
          if (debugDisableOpacityLayers == value) {
            return Future<void>.value();
          }
          debugDisableOpacityLayers = value;
          return _forceRepaint();
        },
      );
      return true;
    }());

    if (!kReleaseMode) {
      // these service extensions work in debug or profile mode
      registerServiceExtension(
        name: RenderingServiceExtensions.debugDumpRenderTree.name,
        callback: (Map<String, String> parameters) async {
          final String data = RendererBinding.instance.renderView.toStringDeep();
          return <String, Object>{
            'data': data,
          };
        },
      );
      registerServiceExtension(
        name: RenderingServiceExtensions.debugDumpSemanticsTreeInTraversalOrder.name,
        callback: (Map<String, String> parameters) async {
          return <String, Object>{
            'data': _generateSemanticsTree(DebugSemanticsDumpOrder.traversalOrder),
          };
        },
      );
      registerServiceExtension(
        name: RenderingServiceExtensions.debugDumpSemanticsTreeInInverseHitTestOrder.name,
        callback: (Map<String, String> parameters) async {
          return <String, Object>{
            'data': _generateSemanticsTree(DebugSemanticsDumpOrder.inverseHitTest),
          };
        },
      );
      registerBoolServiceExtension(
        name: RenderingServiceExtensions.profileRenderObjectPaints.name,
        getter: () async => debugProfilePaintsEnabled,
        setter: (bool value) async {
          if (debugProfilePaintsEnabled != value) {
            debugProfilePaintsEnabled = value;
          }
        },
      );
      registerBoolServiceExtension(
        name: RenderingServiceExtensions.profileRenderObjectLayouts.name,
        getter: () async => debugProfileLayoutsEnabled,
        setter: (bool value) async {
          if (debugProfileLayoutsEnabled != value) {
            debugProfileLayoutsEnabled = value;
          }
        },
      );
    }
  }

  late final PipelineManifold _manifold = _BindingPipelineManifold(this);

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
    renderView = RenderView(configuration: createViewConfiguration(), view: platformDispatcher.implicitView!);
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
    _pipelineOwner.rootNode = value;
  }

  /// Called when the system metrics change.
  ///
  /// See [dart:ui.PlatformDispatcher.onMetricsChanged].
  @protected
  @visibleForTesting
  void handleMetricsChanged() {
    renderView.configuration = createViewConfiguration();
    if (renderView.child != null) {
      scheduleForcedFrame();
    }
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
  /// final Brightness brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
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
    final FlutterView view = platformDispatcher.implicitView!;
    final double devicePixelRatio = view.devicePixelRatio;
    return ViewConfiguration(
      size: view.physicalSize / devicePixelRatio,
      devicePixelRatio: devicePixelRatio,
    );
  }

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

  @override
  void performSemanticsAction(SemanticsActionEvent action) {
    _pipelineOwner.semanticsOwner?.performAction(action.nodeId, action.type, action.arguments);
  }

  void _handleSemanticsOwnerCreated() {
    renderView.scheduleInitialSemantics();
  }

  void _handleSemanticsUpdate(ui.SemanticsUpdate update) {
    renderView.updateSemantics(update);
  }

  void _handleSemanticsOwnerDisposed() {
    renderView.clearSemantics();
  }

  void _handleWebFirstFrame(Duration _) {
    assert(kIsWeb);
    const MethodChannel methodChannel = MethodChannel('flutter/service_worker');
    methodChannel.invokeMethod<void>('first-frame');
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
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
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
    if (!_firstFrameSent) {
      scheduleWarmUpFrame();
    }
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
      if (!kReleaseMode) {
        Timeline.startSync('Preparing Hot Reload (layout)');
      }
      try {
        renderView.reassemble();
      } finally {
        if (!kReleaseMode) {
          Timeline.finishSync();
        }
      }
    }
    scheduleWarmUpFrame();
    await endOfFrame;
  }

  @override
  void hitTest(HitTestResult result, Offset position) {
    renderView.hitTest(result, position: position);
    super.hitTest(result, position);
  }

  Future<void> _forceRepaint() {
    late RenderObjectVisitor visitor;
    visitor = (RenderObject child) {
      child.markNeedsPaint();
      child.visitChildren(visitor);
    };
    instance.renderView.visitChildren(visitor);
    return endOfFrame;
  }
}

/// Prints a textual representation of the entire render tree.
void debugDumpRenderTree() {
  debugPrint(RendererBinding.instance.renderView.toStringDeep());
}

/// Prints a textual representation of the entire layer tree.
void debugDumpLayerTree() {
  debugPrint(RendererBinding.instance.renderView.debugLayer?.toStringDeep());
}

/// Prints a textual representation of the entire semantics tree.
/// This will only work if there is a semantics client attached.
/// Otherwise, a notice that no semantics are available will be printed.
///
/// The order in which the children of a [SemanticsNode] will be printed is
/// controlled by the [childOrder] parameter.
void debugDumpSemanticsTree([DebugSemanticsDumpOrder childOrder = DebugSemanticsDumpOrder.traversalOrder]) {
  debugPrint(_generateSemanticsTree(childOrder));
}

String _generateSemanticsTree(DebugSemanticsDumpOrder childOrder) {
  final String? tree = RendererBinding.instance.renderView.debugSemantics?.toStringDeep(childOrder: childOrder);
  if (tree != null) {
    return tree;
  }
  return 'Semantics not generated.\n'
    'For performance reasons, the framework only generates semantics when asked to do so by the platform.\n'
    'Usually, platforms only ask for semantics when assistive technologies (like screen readers) are running.\n'
    'To generate semantics, try turning on an assistive technology (like VoiceOver or TalkBack) on your device.';
}

/// A concrete binding for applications that use the Rendering framework
/// directly. This is the glue that binds the framework to the Flutter engine.
///
/// When using the rendering framework directly, this binding, or one that
/// implements the same interfaces, must be used. The following
/// mixins are used to implement this binding:
///
/// * [GestureBinding], which implements the basics of hit testing.
/// * [SchedulerBinding], which introduces the concepts of frames.
/// * [ServicesBinding], which provides access to the plugin subsystem.
/// * [SemanticsBinding], which supports accessibility.
/// * [PaintingBinding], which enables decoding images.
/// * [RendererBinding], which handles the render tree.
///
/// You would only use this binding if you are writing to the
/// rendering layer directly. If you are writing to a higher-level
/// library, such as the Flutter Widgets library, then you would use
/// that layer's binding (see [WidgetsFlutterBinding]).
class RenderingFlutterBinding extends BindingBase with GestureBinding, SchedulerBinding, ServicesBinding, SemanticsBinding, PaintingBinding, RendererBinding {
  /// Creates a binding for the rendering layer.
  ///
  /// The `root` render box is attached directly to the [renderView] and is
  /// given constraints that require it to fill the window.
  ///
  /// This binding does not automatically schedule any frames. Callers are
  /// responsible for deciding when to first call [scheduleFrame].
  RenderingFlutterBinding({ RenderBox? root }) {
    renderView.child = root;
  }

  /// Returns an instance of the binding that implements
  /// [RendererBinding]. If no binding has yet been initialized, the
  /// [RenderingFlutterBinding] class is used to create and initialize
  /// one.
  ///
  /// You need to call this method before using the rendering framework
  /// if you are using it directly. If you are using the widgets framework,
  /// see [WidgetsFlutterBinding.ensureInitialized].
  static RendererBinding ensureInitialized() {
    if (RendererBinding._instance == null) {
      RenderingFlutterBinding();
    }
    return RendererBinding.instance;
  }
}

/// A [PipelineManifold] implementation that is backed by the [RendererBinding].
class _BindingPipelineManifold extends ChangeNotifier implements PipelineManifold {
  _BindingPipelineManifold(this._binding) {
    _binding.addSemanticsEnabledListener(notifyListeners);
  }

  final RendererBinding _binding;

  @override
  void requestVisualUpdate() {
    _binding.ensureVisualUpdate();
  }

  @override
  bool get semanticsEnabled => _binding.semanticsEnabled;

  @override
  void dispose() {
    _binding.removeSemanticsEnabledListener(notifyListeners);
    super.dispose();
  }
}
