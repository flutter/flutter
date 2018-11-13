// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' show AppLifecycleState, Locale, AccessibilityFeatures;
import 'dart:ui' as ui show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'debug.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'widget_inspector.dart';

export 'dart:ui' show AppLifecycleState, Locale;

/// Interface for classes that register with the Widgets layer binding.
///
/// When used as a mixin, provides noop method implementations.
///
/// See [WidgetsBinding.addObserver] and [WidgetsBinding.removeObserver].
///
/// This class can be extended directly, to get default behaviors for all of the
/// handlers, or can used with the `implements` keyword, in which case all the
/// handlers must be implemented (and the analyzer will list those that have
/// been omitted).
///
/// {@tool sample}
///
/// This [StatefulWidget] implements the parts of the [State] and
/// [WidgetsBindingObserver] protocols necessary to react to application
/// lifecycle messages. See [didChangeAppLifecycleState].
///
/// ```dart
/// class AppLifecycleReactor extends StatefulWidget {
///   const AppLifecycleReactor({ Key key }) : super(key: key);
///
///   @override
///   _AppLifecycleReactorState createState() => _AppLifecycleReactorState();
/// }
///
/// class _AppLifecycleReactorState extends State<AppLifecycleReactor> with WidgetsBindingObserver {
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addObserver(this);
///   }
///
///   @override
///   void dispose() {
///     WidgetsBinding.instance.removeObserver(this);
///     super.dispose();
///   }
///
///   AppLifecycleState _notification;
///
///   @override
///   void didChangeAppLifecycleState(AppLifecycleState state) {
///     setState(() { _notification = state; });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Text('Last notification: $_notification');
///   }
/// }
/// ```
/// {@end-tool}
///
/// To respond to other notifications, replace the [didChangeAppLifecycleState]
/// method above with other methods from this class.
abstract class WidgetsBindingObserver {
  /// Called when the system tells the app to pop the current route.
  /// For example, on Android, this is called when the user presses
  /// the back button.
  ///
  /// Observers are notified in registration order until one returns
  /// true. If none return true, the application quits.
  ///
  /// Observers are expected to return true if they were able to
  /// handle the notification, for example by closing an active dialog
  /// box, and false otherwise. The [WidgetsApp] widget uses this
  /// mechanism to notify the [Navigator] widget that it should pop
  /// its current route if possible.
  ///
  /// This method exposes the `popRoute` notification from
  /// [SystemChannels.navigation].
  Future<bool> didPopRoute() => Future<bool>.value(false);

  /// Called when the host tells the app to push a new route onto the
  /// navigator.
  ///
  /// Observers are expected to return true if they were able to
  /// handle the notification. Observers are notified in registration
  /// order until one returns true.
  ///
  /// This method exposes the `pushRoute` notification from
  /// [SystemChannels.navigation].
  Future<bool> didPushRoute(String route) => Future<bool>.value(false);

  /// Called when the application's dimensions change. For example,
  /// when a phone is rotated.
  ///
  /// This method exposes notifications from [Window.onMetricsChanged].
  ///
  /// {@tool sample}
  ///
  /// This [StatefulWidget] implements the parts of the [State] and
  /// [WidgetsBindingObserver] protocols necessary to react when the device is
  /// rotated (or otherwise changes dimensions).
  ///
  /// ```dart
  /// class MetricsReactor extends StatefulWidget {
  ///   const MetricsReactor({ Key key }) : super(key: key);
  ///
  ///   @override
  ///   _MetricsReactorState createState() => _MetricsReactorState();
  /// }
  ///
  /// class _MetricsReactorState extends State<MetricsReactor> with WidgetsBindingObserver {
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     WidgetsBinding.instance.addObserver(this);
  ///   }
  ///
  ///   @override
  ///   void dispose() {
  ///     WidgetsBinding.instance.removeObserver(this);
  ///     super.dispose();
  ///   }
  ///
  ///   Size _lastSize;
  ///
  ///   @override
  ///   void didChangeMetrics() {
  ///     setState(() { _lastSize = ui.window.physicalSize; });
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Text('Current size: $_lastSize');
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// In general, this is unnecessary as the layout system takes care of
  /// automatically recomputing the application geometry when the application
  /// size changes.
  ///
  /// See also:
  ///
  ///  * [MediaQuery.of], which provides a similar service with less
  ///    boilerplate.
  void didChangeMetrics() { }

  /// Called when the platform's text scale factor changes.
  ///
  /// This typically happens as the result of the user changing system
  /// preferences, and it should affect all of the text sizes in the
  /// application.
  ///
  /// This method exposes notifications from [Window.onTextScaleFactorChanged].
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// class TextScaleFactorReactor extends StatefulWidget {
  ///   const TextScaleFactorReactor({ Key key }) : super(key: key);
  ///
  ///   @override
  ///   _TextScaleFactorReactorState createState() => _TextScaleFactorReactorState();
  /// }
  ///
  /// class _TextScaleFactorReactorState extends State<TextScaleFactorReactor> with WidgetsBindingObserver {
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     WidgetsBinding.instance.addObserver(this);
  ///   }
  ///
  ///   @override
  ///   void dispose() {
  ///     WidgetsBinding.instance.removeObserver(this);
  ///     super.dispose();
  ///   }
  ///
  ///   double _lastTextScaleFactor;
  ///
  ///   @override
  ///   void didChangeTextScaleFactor() {
  ///     setState(() { _lastTextScaleFactor = ui.window.textScaleFactor; });
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Text('Current scale factor: $_lastTextScaleFactor');
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [MediaQuery.of], which provides a similar service with less
  ///    boilerplate.
  void didChangeTextScaleFactor() { }

  /// Called when the system tells the app that the user's locale has
  /// changed. For example, if the user changes the system language
  /// settings.
  ///
  /// This method exposes notifications from [Window.onLocaleChanged].
  void didChangeLocales(List<Locale> locale) { }

  /// Called when the system puts the app in the background or returns
  /// the app to the foreground.
  ///
  /// An example of implementing this method is provided in the class-level
  /// documentation for the [WidgetsBindingObserver] class.
  ///
  /// This method exposes notifications from [SystemChannels.lifecycle].
  void didChangeAppLifecycleState(AppLifecycleState state) { }

  /// Called when the system is running low on memory.
  ///
  /// This method exposes the `memoryPressure` notification from
  /// [SystemChannels.system].
  void didHaveMemoryPressure() { }

  /// Called when the system changes the set of currently active accessibility
  /// features.
  ///
  /// This method exposes notifications from [Window.onAccessibilityFeaturesChanged].
  void didChangeAccessibilityFeatures() {}
}

/// The glue between the widgets layer and the Flutter engine.
mixin WidgetsBinding on BindingBase, SchedulerBinding, GestureBinding, RendererBinding, SemanticsBinding {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    buildOwner.onBuildScheduled = _handleBuildScheduled;
    ui.window.onLocaleChanged = handleLocaleChanged;
    ui.window.onAccessibilityFeaturesChanged = handleAccessibilityFeaturesChanged;
    SystemChannels.navigation.setMethodCallHandler(_handleNavigationInvocation);
    SystemChannels.system.setMessageHandler(_handleSystemMessage);
  }

  /// The current [WidgetsBinding], if one has been created.
  ///
  /// If you need the binding to be constructed before calling [runApp],
  /// you can ensure a Widget binding has been constructed by calling the
  /// `WidgetsFlutterBinding.ensureInitialized()` function.
  static WidgetsBinding get instance => _instance;
  static WidgetsBinding _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    const bool isReleaseMode = bool.fromEnvironment('dart.vm.product');
    if (!isReleaseMode) {
      registerSignalServiceExtension(
        name: 'debugDumpApp',
        callback: () {
          debugDumpApp();
          return debugPrintDone;
        },
      );

      registerBoolServiceExtension(
        name: 'showPerformanceOverlay',
        getter: () =>
        Future<bool>.value(WidgetsApp.showPerformanceOverlayOverride),
        setter: (bool value) {
          if (WidgetsApp.showPerformanceOverlayOverride == value)
            return Future<void>.value();
          WidgetsApp.showPerformanceOverlayOverride = value;
          return _forceRebuild();
        },
      );
    }

    assert(() {
      registerBoolServiceExtension(
        name: 'debugAllowBanner',
        getter: () => Future<bool>.value(WidgetsApp.debugAllowBannerOverride),
        setter: (bool value) {
          if (WidgetsApp.debugAllowBannerOverride == value)
            return Future<void>.value();
          WidgetsApp.debugAllowBannerOverride = value;
          return _forceRebuild();
        },
      );

      // Expose the ability to send Widget rebuilds as [Timeline] events.
      registerBoolServiceExtension(
        name: 'profileWidgetBuilds',
        getter: () async => debugProfileBuildsEnabled,
        setter: (bool value) async {
          if (debugProfileBuildsEnabled != value)
            debugProfileBuildsEnabled = value;
        },
      );

      // This service extension is deprecated and will be removed by 12/1/2018.
      // Use ext.flutter.inspector.show instead.
      registerBoolServiceExtension(
          name: 'debugWidgetInspector',
          getter: () async => WidgetsApp.debugShowWidgetInspectorOverride,
          setter: (bool value) {
            if (WidgetsApp.debugShowWidgetInspectorOverride == value)
              return Future<void>.value();
            WidgetsApp.debugShowWidgetInspectorOverride = value;
            return _forceRebuild();
          }
      );

      WidgetInspectorService.instance.initServiceExtensions(registerServiceExtension);

      return true;
    }());
  }

  Future<void> _forceRebuild() {
    if (renderViewElement != null) {
      buildOwner.reassemble(renderViewElement);
      return endOfFrame;
    }
    return Future<void>.value();
  }

  /// The [BuildOwner] in charge of executing the build pipeline for the
  /// widget tree rooted at this binding.
  BuildOwner get buildOwner => _buildOwner;
  final BuildOwner _buildOwner = BuildOwner();

  /// The object in charge of the focus tree.
  ///
  /// Rarely used directly. Instead, consider using [FocusScope.of] to obtain
  /// the [FocusScopeNode] for a given [BuildContext].
  ///
  /// See [FocusManager] for more details.
  FocusManager get focusManager => _buildOwner.focusManager;

  final List<WidgetsBindingObserver> _observers = <WidgetsBindingObserver>[];

  /// Registers the given object as a binding observer. Binding
  /// observers are notified when various application events occur,
  /// for example when the system locale changes. Generally, one
  /// widget in the widget tree registers itself as a binding
  /// observer, and converts the system state into inherited widgets.
  ///
  /// For example, the [WidgetsApp] widget registers as a binding
  /// observer and passes the screen size to a [MediaQuery] widget
  /// each time it is built, which enables other widgets to use the
  /// [MediaQuery.of] static method and (implicitly) the
  /// [InheritedWidget] mechanism to be notified whenever the screen
  /// size changes (e.g. whenever the screen rotates).
  ///
  /// See also:
  ///
  ///  * [removeObserver], to release the resources reserved by this method.
  ///  * [WidgetsBindingObserver], which has an example of using this method.
  void addObserver(WidgetsBindingObserver observer) => _observers.add(observer);

  /// Unregisters the given observer. This should be used sparingly as
  /// it is relatively expensive (O(N) in the number of registered
  /// observers).
  ///
  /// See also:
  ///
  ///  * [addObserver], for the method that adds observers in the first place.
  ///  * [WidgetsBindingObserver], which has an example of using this method.
  bool removeObserver(WidgetsBindingObserver observer) => _observers.remove(observer);

  @override
  void handleMetricsChanged() {
    super.handleMetricsChanged();
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeMetrics();
  }

  @override
  void handleTextScaleFactorChanged() {
    super.handleTextScaleFactorChanged();
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeTextScaleFactor();
  }

  @override
  void handleAccessibilityFeaturesChanged() {
    super.handleAccessibilityFeaturesChanged();
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeAccessibilityFeatures();
  }

  /// Called when the system locale changes.
  ///
  /// Calls [dispatchLocaleChanged] to notify the binding observers.
  ///
  /// See [Window.onLocaleChanged].
  @protected
  @mustCallSuper
  void handleLocaleChanged() {
    dispatchLocalesChanged(ui.window.locales);
  }

  /// Notify all the observers that the locale has changed (using
  /// [WidgetsBindingObserver.didChangeLocales]), giving them the
  /// `locales` argument.
  ///
  /// This is called by [handleLocaleChanged] when the [Window.onLocaleChanged]
  /// notification is received.
  @protected
  @mustCallSuper
  void dispatchLocalesChanged(List<Locale> locales) {
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeLocales(locales);
  }

  /// Notify all the observers that the active set of [AccessibilityFeatures]
  /// has changed (using [WidgetsBindingObserver.didChangeAccessibilityFeatures]),
  /// giving them the `features` argument.
  ///
  /// This is called by [handleAccessibilityFeaturesChanged] when the
  /// [Window.onAccessibilityFeaturesChanged] notification is received.
  @protected
  @mustCallSuper
  void dispatchAccessibilityFeaturesChanged() {
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeAccessibilityFeatures();
  }

  /// Called when the system pops the current route.
  ///
  /// This first notifies the binding observers (using
  /// [WidgetsBindingObserver.didPopRoute]), in registration order, until one
  /// returns true, meaning that it was able to handle the request (e.g. by
  /// closing a dialog box). If none return true, then the application is shut
  /// down by calling [SystemNavigator.pop].
  ///
  /// [WidgetsApp] uses this in conjunction with a [Navigator] to
  /// cause the back button to close dialog boxes, return from modal
  /// pages, and so forth.
  ///
  /// This method exposes the `popRoute` notification from
  /// [SystemChannels.navigation].
  @protected
  Future<void> handlePopRoute() async {
    for (WidgetsBindingObserver observer in List<WidgetsBindingObserver>.from(_observers)) {
      if (await observer.didPopRoute())
        return;
    }
    SystemNavigator.pop();
  }

  /// Called when the host tells the app to push a new route onto the
  /// navigator.
  ///
  /// This notifies the binding observers (using
  /// [WidgetsBindingObserver.didPushRoute]), in registration order, until one
  /// returns true, meaning that it was able to handle the request (e.g. by
  /// opening a dialog box). If none return true, then nothing happens.
  ///
  /// This method exposes the `pushRoute` notification from
  /// [SystemChannels.navigation].
  @protected
  @mustCallSuper
  Future<void> handlePushRoute(String route) async {
    for (WidgetsBindingObserver observer in List<WidgetsBindingObserver>.from(_observers)) {
      if (await observer.didPushRoute(route))
        return;
    }
  }

  Future<dynamic> _handleNavigationInvocation(MethodCall methodCall) {
    switch (methodCall.method) {
      case 'popRoute':
        return handlePopRoute();
      case 'pushRoute':
        return handlePushRoute(methodCall.arguments);
    }
    return Future<dynamic>.value();
  }

  @override
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    super.handleAppLifecycleStateChanged(state);
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeAppLifecycleState(state);
  }

  /// Called when the operating system notifies the application of a memory
  /// pressure situation.
  ///
  /// Notifies all the observers using
  /// [WidgetsBindingObserver.didHaveMemoryPressure].
  ///
  /// This method exposes the `memoryPressure` notification from
  /// [SystemChannels.system].
  void handleMemoryPressure() {
    for (WidgetsBindingObserver observer in _observers)
      observer.didHaveMemoryPressure();
  }

  Future<void> _handleSystemMessage(Object systemMessage) async {
    final Map<String, dynamic> message = systemMessage;
    final String type = message['type'];
    switch (type) {
      case 'memoryPressure':
        handleMemoryPressure();
        break;
    }
    return;
  }

  bool _needToReportFirstFrame = true;
  int _deferFirstFrameReportCount = 0;
  bool get _reportFirstFrame => _deferFirstFrameReportCount == 0;

  /// Whether the first frame has finished rendering.
  ///
  /// Only valid in profile and debug builds, it can't be used in release
  /// builds.
  /// It can be deferred using [deferFirstFrameReport] and
  /// [allowFirstFrameReport].
  /// The value is set at the end of the call to [drawFrame].
  bool get debugDidSendFirstFrameEvent => !_needToReportFirstFrame;

  /// Tell the framework not to report the frame it is building as a "useful"
  /// first frame until there is a corresponding call to [allowFirstFrameReport].
  ///
  /// This is used by [WidgetsApp] to report the first frame.
  //
  // TODO(ianh): This method should only be available in debug and profile modes.
  void deferFirstFrameReport() {
    assert(_deferFirstFrameReportCount >= 0);
    _deferFirstFrameReportCount += 1;
  }

  /// When called after [deferFirstFrameReport]: tell the framework to report
  /// the frame it is building as a "useful" first frame.
  ///
  /// This method may only be called once for each corresponding call
  /// to [deferFirstFrameReport].
  ///
  /// This is used by [WidgetsApp] to report the first frame.
  //
  // TODO(ianh): This method should only be available in debug and profile modes.
  void allowFirstFrameReport() {
    assert(_deferFirstFrameReportCount >= 1);
    _deferFirstFrameReportCount -= 1;
  }

  void _handleBuildScheduled() {
    // If we're in the process of building dirty elements, then changes
    // should not trigger a new frame.
    assert(() {
      if (debugBuildingDirtyElements) {
        throw FlutterError(
          'Build scheduled during frame.\n'
          'While the widget tree was being built, laid out, and painted, '
          'a new frame was scheduled to rebuild the widget tree. '
          'This might be because setState() was called from a layout or '
          'paint callback. '
          'If a change is needed to the widget tree, it should be applied '
          'as the tree is being built. Scheduling a change for the subsequent '
          'frame instead results in an interface that lags behind by one frame. '
          'If this was done to make your build dependent on a size measured at '
          'layout time, consider using a LayoutBuilder, CustomSingleChildLayout, '
          'or CustomMultiChildLayout. If, on the other hand, the one frame delay '
          'is the desired effect, for example because this is an '
          'animation, consider scheduling the frame in a post-frame callback '
          'using SchedulerBinding.addPostFrameCallback or '
          'using an AnimationController to trigger the animation.'
        );
      }
      return true;
    }());
    ensureVisualUpdate();
  }

  /// Whether we are currently in a frame. This is used to verify
  /// that frames are not scheduled redundantly.
  ///
  /// This is public so that test frameworks can change it.
  ///
  /// This flag is not used in release builds.
  @protected
  bool debugBuildingDirtyElements = false;

  /// Pump the build and rendering pipeline to generate a frame.
  ///
  /// This method is called by [handleDrawFrame], which itself is called
  /// automatically by the engine when when it is time to lay out and paint a
  /// frame.
  ///
  /// Each frame consists of the following phases:
  ///
  /// 1. The animation phase: The [handleBeginFrame] method, which is registered
  /// with [Window.onBeginFrame], invokes all the transient frame callbacks
  /// registered with [scheduleFrameCallback], in
  /// registration order. This includes all the [Ticker] instances that are
  /// driving [AnimationController] objects, which means all of the active
  /// [Animation] objects tick at this point.
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
  /// 3. The build phase: All the dirty [Element]s in the widget tree are
  /// rebuilt (see [State.build]). See [State.setState] for further details on
  /// marking a widget dirty for building. See [BuildOwner] for more information
  /// on this step.
  ///
  /// 4. The layout phase: All the dirty [RenderObject]s in the system are laid
  /// out (see [RenderObject.performLayout]). See [RenderObject.markNeedsLayout]
  /// for further details on marking an object dirty for layout.
  ///
  /// 5. The compositing bits phase: The compositing bits on any dirty
  /// [RenderObject] objects are updated. See
  /// [RenderObject.markNeedsCompositingBitsUpdate].
  ///
  /// 6. The paint phase: All the dirty [RenderObject]s in the system are
  /// repainted (see [RenderObject.paint]). This generates the [Layer] tree. See
  /// [RenderObject.markNeedsPaint] for further details on marking an object
  /// dirty for paint.
  ///
  /// 7. The compositing phase: The layer tree is turned into a [Scene] and
  /// sent to the GPU.
  ///
  /// 8. The semantics phase: All the dirty [RenderObject]s in the system have
  /// their semantics updated (see [RenderObject.semanticsAnnotator]). This
  /// generates the [SemanticsNode] tree. See
  /// [RenderObject.markNeedsSemanticsUpdate] for further details on marking an
  /// object dirty for semantics.
  ///
  /// For more details on steps 4-8, see [PipelineOwner].
  ///
  /// 9. The finalization phase in the widgets layer: The widgets tree is
  /// finalized. This causes [State.dispose] to be invoked on any objects that
  /// were removed from the widgets tree this frame. See
  /// [BuildOwner.finalizeTree] for more details.
  ///
  /// 10. The finalization phase in the scheduler layer: After [drawFrame]
  /// returns, [handleDrawFrame] then invokes post-frame callbacks (registered
  /// with [addPostFrameCallback]).
  //
  // When editing the above, also update rendering/binding.dart's copy.
  @override
  void drawFrame() {
    assert(!debugBuildingDirtyElements);
    assert(() {
      debugBuildingDirtyElements = true;
      return true;
    }());
    try {
      if (renderViewElement != null)
        buildOwner.buildScope(renderViewElement);
      super.drawFrame();
      buildOwner.finalizeTree();
    } finally {
      assert(() {
        debugBuildingDirtyElements = false;
        return true;
      }());
    }
    // TODO(ianh): Following code should not be included in release mode, only profile and debug modes.
    // See https://github.com/dart-lang/sdk/issues/27192
    if (_needToReportFirstFrame && _reportFirstFrame) {
      developer.Timeline.instantSync('Widgets completed first useful frame');
      developer.postEvent('Flutter.FirstFrame', <String, dynamic>{});
      _needToReportFirstFrame = false;
    }
  }

  /// The [Element] that is at the root of the hierarchy (and which wraps the
  /// [RenderView] object at the root of the rendering hierarchy).
  ///
  /// This is initialized the first time [runApp] is called.
  Element get renderViewElement => _renderViewElement;
  Element _renderViewElement;

  /// Takes a widget and attaches it to the [renderViewElement], creating it if
  /// necessary.
  ///
  /// This is called by [runApp] to configure the widget tree.
  ///
  /// See also [RenderObjectToWidgetAdapter.attachToRenderTree].
  void attachRootWidget(Widget rootWidget) {
    _renderViewElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: renderView,
      debugShortDescription: '[root]',
      child: rootWidget
    ).attachToRenderTree(buildOwner, renderViewElement);
  }

  @override
  Future<void> performReassemble() {
    assert(() {
      WidgetInspectorService.instance.performReassemble();
      return true;
    }());

    deferFirstFrameReport();
    if (renderViewElement != null)
      buildOwner.reassemble(renderViewElement);
    return super.performReassemble().then((void value) {
      allowFirstFrameReport();
    });
  }
}

/// Inflate the given widget and attach it to the screen.
///
/// The widget is given constraints during layout that force it to fill the
/// entire screen. If you wish to align your widget to one side of the screen
/// (e.g., the top), consider using the [Align] widget. If you wish to center
/// your widget, you can also use the [Center] widget
///
/// Calling [runApp] again will detach the previous root widget from the screen
/// and attach the given widget in its place. The new widget tree is compared
/// against the previous widget tree and any differences are applied to the
/// underlying render tree, similar to what happens when a [StatefulWidget]
/// rebuilds after calling [State.setState].
///
/// Initializes the binding using [WidgetsFlutterBinding] if necessary.
///
/// See also:
///
/// * [WidgetsBinding.attachRootWidget], which creates the root widget for the
///   widget hierarchy.
/// * [RenderObjectToWidgetAdapter.attachToRenderTree], which creates the root
///   element for the element hierarchy.
/// * [WidgetsBinding.handleBeginFrame], which pumps the widget pipeline to
///   ensure the widget, element, and render trees are all built.
void runApp(Widget app) {
  WidgetsFlutterBinding.ensureInitialized()
    ..attachRootWidget(app)
    ..scheduleWarmUpFrame();
}

/// Print a string representation of the currently running app.
void debugDumpApp() {
  assert(WidgetsBinding.instance != null);
  String mode = 'RELEASE MODE';
  assert(() { mode = 'CHECKED MODE'; return true; }());
  debugPrint('${WidgetsBinding.instance.runtimeType} - $mode');
  if (WidgetsBinding.instance.renderViewElement != null) {
    debugPrint(WidgetsBinding.instance.renderViewElement.toStringDeep());
  } else {
    debugPrint('<no tree currently mounted>');
  }
}

/// A bridge from a [RenderObject] to an [Element] tree.
///
/// The given container is the [RenderObject] that the [Element] tree should be
/// inserted into. It must be a [RenderObject] that implements the
/// [RenderObjectWithChildMixin] protocol. The type argument `T` is the kind of
/// [RenderObject] that the container expects as its child.
///
/// Used by [runApp] to bootstrap applications.
class RenderObjectToWidgetAdapter<T extends RenderObject> extends RenderObjectWidget {
  /// Creates a bridge from a [RenderObject] to an [Element] tree.
  ///
  /// Used by [WidgetsBinding] to attach the root widget to the [RenderView].
  RenderObjectToWidgetAdapter({
    this.child,
    this.container,
    this.debugShortDescription
  }) : super(key: GlobalObjectKey(container));

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The [RenderObject] that is the parent of the [Element] created by this widget.
  final RenderObjectWithChildMixin<T> container;

  /// A short description of this widget used by debugging aids.
  final String debugShortDescription;

  @override
  RenderObjectToWidgetElement<T> createElement() => RenderObjectToWidgetElement<T>(this);

  @override
  RenderObjectWithChildMixin<T> createRenderObject(BuildContext context) => container;

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) { }

  /// Inflate this widget and actually set the resulting [RenderObject] as the
  /// child of [container].
  ///
  /// If `element` is null, this function will create a new element. Otherwise,
  /// the given element will have an update scheduled to switch to this widget.
  ///
  /// Used by [runApp] to bootstrap applications.
  RenderObjectToWidgetElement<T> attachToRenderTree(BuildOwner owner, [RenderObjectToWidgetElement<T> element]) {
    if (element == null) {
      owner.lockState(() {
        element = createElement();
        assert(element != null);
        element.assignOwner(owner);
      });
      owner.buildScope(element, () {
        element.mount(null, null);
      });
    } else {
      element._newWidget = this;
      element.markNeedsBuild();
    }
    return element;
  }

  @override
  String toStringShort() => debugShortDescription ?? super.toStringShort();
}

/// A [RootRenderObjectElement] that is hosted by a [RenderObject].
///
/// This element class is the instantiation of a [RenderObjectToWidgetAdapter]
/// widget. It can be used only as the root of an [Element] tree (it cannot be
/// mounted into another [Element]; it's parent must be null).
///
/// In typical usage, it will be instantiated for a [RenderObjectToWidgetAdapter]
/// whose container is the [RenderView] that connects to the Flutter engine. In
/// this usage, it is normally instantiated by the bootstrapping logic in the
/// [WidgetsFlutterBinding] singleton created by [runApp].
class RenderObjectToWidgetElement<T extends RenderObject> extends RootRenderObjectElement {
  /// Creates an element that is hosted by a [RenderObject].
  ///
  /// The [RenderObject] created by this element is not automatically set as a
  /// child of the hosting [RenderObject]. To actually attach this element to
  /// the render tree, call [RenderObjectToWidgetAdapter.attachToRenderTree].
  RenderObjectToWidgetElement(RenderObjectToWidgetAdapter<T> widget) : super(widget);

  @override
  RenderObjectToWidgetAdapter<T> get widget => super.widget;

  Element _child;

  static const Object _rootChildSlot = Object();

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    assert(parent == null);
    super.mount(parent, newSlot);
    _rebuild();
  }

  @override
  void update(RenderObjectToWidgetAdapter<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _rebuild();
  }

  // When we are assigned a new widget, we store it here
  // until we are ready to update to it.
  Widget _newWidget;

  @override
  void performRebuild() {
    if (_newWidget != null) {
      // _newWidget can be null if, for instance, we were rebuilt
      // due to a reassemble.
      final Widget newWidget = _newWidget;
      _newWidget = null;
      update(newWidget);
    }
    super.performRebuild();
    assert(_newWidget == null);
  }

  void _rebuild() {
    try {
      _child = updateChild(_child, widget.child, _rootChildSlot);
      assert(_child != null);
    } catch (exception, stack) {
      final FlutterErrorDetails details = FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets library',
        context: 'attaching to the render tree'
      );
      FlutterError.reportError(details);
      final Widget error = ErrorWidget.builder(details);
      _child = updateChild(null, error, _rootChildSlot);
    }
  }

  @override
  RenderObjectWithChildMixin<T> get renderObject => super.renderObject;

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(slot == _rootChildSlot);
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(renderObject.child == child);
    renderObject.child = null;
  }
}

/// A concrete binding for applications based on the Widgets framework.
///
/// This is the glue that binds the framework to the Flutter engine.
class WidgetsFlutterBinding extends BindingBase with GestureBinding, ServicesBinding, SchedulerBinding, PaintingBinding, SemanticsBinding, RendererBinding, WidgetsBinding {

  /// Returns an instance of the [WidgetsBinding], creating and
  /// initializing it if necessary. If one is created, it will be a
  /// [WidgetsFlutterBinding]. If one was previously initialized, then
  /// it will at least implement [WidgetsBinding].
  ///
  /// You only need to call this method if you need the binding to be
  /// initialized before calling [runApp].
  ///
  /// In the `flutter_test` framework, [testWidgets] initializes the
  /// binding instance to a [TestWidgetsFlutterBinding], not a
  /// [WidgetsFlutterBinding].
  static WidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null)
      WidgetsFlutterBinding();
    return WidgetsBinding.instance;
  }
}
