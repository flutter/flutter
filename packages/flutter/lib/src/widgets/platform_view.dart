// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'debug.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';

/// Embeds an Android view in the Widget hierarchy.
///
/// Requires Android API level 20 or greater.
///
/// Embedding Android views is an expensive operation and should be avoided when a Flutter
/// equivalent is possible.
///
/// The embedded Android view is painted just like any other Flutter widget and transformations
/// apply to it as well.
///
/// {@template flutter.widgets.platformViews.layout}
/// The widget fills all available space, the parent of this object must provide bounded layout
/// constraints.
/// {@endtemplate}
///
/// {@template flutter.widgets.platformViews.gestures}
/// The widget participates in Flutter's gesture arenas, and dispatches touch events to the
/// platform view iff it won the arena. Specific gestures that should be dispatched to the platform
/// view can be specified in the `gestureRecognizers` constructor parameter. If
/// the set of gesture recognizers is empty, a gesture will be dispatched to the platform
/// view iff it was not claimed by any other gesture recognizer.
/// {@endtemplate}
///
/// The Android view object is created using a [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html).
/// Plugins can register platform view factories with [PlatformViewRegistry#registerViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewRegistry.html#registerViewFactory-java.lang.String-io.flutter.plugin.platform.PlatformViewFactory-).
///
/// Registration is typically done in the plugin's registerWith method, e.g:
///
/// ```java
///   public static void registerWith(Registrar registrar) {
///     registrar.platformViewRegistry().registerViewFactory("webview", WebViewFactory(registrar.messenger()));
///   }
/// ```
///
/// {@template flutter.widgets.platformViews.lifetime}
/// The platform view's lifetime is the same as the lifetime of the [State] object for this widget.
/// When the [State] is disposed the platform view (and auxiliary resources) are lazily
/// released (some resources are immediately released and some by platform garbage collector).
/// A stateful widget's state is disposed when the widget is removed from the tree or when it is
/// moved within the tree. If the stateful widget has a key and it's only moved relative to its siblings,
/// or it has a [GlobalKey] and it's moved within the tree, it will not be disposed.
/// {@endtemplate}
class AndroidView extends StatefulWidget {
  /// Creates a widget that embeds an Android view.
  ///
  /// {@template flutter.widgets.platformViews.constructorParams}
  /// The `viewType` and `hitTestBehavior` parameters must not be null.
  /// If `creationParams` is not null then `creationParamsCodec` must not be null.
  /// {@endtemplate}
  const AndroidView({
    Key key,
    @required this.viewType,
    this.onPlatformViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.layoutDirection,
    this.gestureRecognizers,
    this.creationParams,
    this.creationParamsCodec,
  }) : assert(viewType != null),
       assert(hitTestBehavior != null),
       assert(creationParams == null || creationParamsCodec != null),
       super(key: key);

  /// The unique identifier for Android view type to be embedded by this widget.
  ///
  /// A [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html)
  /// for this type must have been registered.
  ///
  /// See also:
  ///
  ///  * [AndroidView] for an example of registering a platform view factory.
  final String viewType;

  /// {@template flutter.widgets.platformViews.createdParam}
  /// Callback to invoke after the platform view has been created.
  ///
  /// May be null.
  /// {@endtemplate}
  final PlatformViewCreatedCallback onPlatformViewCreated;

  /// {@template flutter.widgets.platformViews.hittestParam}
  /// How this widget should behave during hit testing.
  ///
  /// This defaults to [PlatformViewHitTestBehavior.opaque].
  /// {@endtemplate}
  final PlatformViewHitTestBehavior hitTestBehavior;

  /// {@template flutter.widgets.platformViews.directionParam}
  /// The text direction to use for the embedded view.
  ///
  /// If this is null, the ambient [Directionality] is used instead.
  /// {@endtemplate}
  final TextDirection layoutDirection;

  /// Which gestures should be forwarded to the Android view.
  ///
  /// {@template flutter.widgets.platformViews.gestureRecognizersDescHead}
  /// The gesture recognizers built by factories in this set participate in the gesture arena for
  /// each pointer that was put down on the widget. If any of these recognizers win the
  /// gesture arena, the entire pointer event sequence starting from the pointer down event
  /// will be dispatched to the platform view.
  ///
  /// When null, an empty set of gesture recognizer factories is used, in which case a pointer event sequence
  /// will only be dispatched to the platform view if no other member of the arena claimed it.
  /// {@endtemplate}
  ///
  /// For example, with the following setup vertical drags will not be dispatched to the Android
  /// view as the vertical drag gesture is claimed by the parent [GestureDetector].
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails d) {},
  ///   child: AndroidView(
  ///     viewType: 'webview',
  ///   ),
  /// )
  /// ```
  ///
  /// To get the [AndroidView] to claim the vertical drag gestures we can pass a vertical drag
  /// gesture recognizer factory in [gestureRecognizers] e.g:
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: SizedBox(
  ///     width: 200.0,
  ///     height: 100.0,
  ///     child: AndroidView(
  ///       viewType: 'webview',
  ///       gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
  ///         new Factory<OneSequenceGestureRecognizer>(
  ///           () => new EagerGestureRecognizer(),
  ///         ),
  ///       ].toSet(),
  ///     ),
  ///   ),
  /// )
  /// ```
  ///
  /// {@template flutter.widgets.platformViews.gestureRecognizersDescFoot}
  /// A platform view can be configured to consume all pointers that were put down in its bounds
  /// by passing a factory for an [EagerGestureRecognizer] in [gestureRecognizers].
  /// [EagerGestureRecognizer] is a special gesture recognizer that immediately claims the gesture
  /// after a pointer down event.
  ///
  /// The `gestureRecognizers` property must not contain more than one factory with the same [Factory.type].
  ///
  /// Changing `gestureRecognizers` results in rejection of any active gesture arenas (if the
  /// platform view is actively participating in an arena).
  /// {@endtemplate}
  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  // TODO(amirh): get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// Passed as the args argument of [PlatformViewFactory#create](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html#create-android.content.Context-int-java.lang.Object-)
  ///
  /// This can be used by plugins to pass constructor parameters to the embedded Android view.
  final dynamic creationParams;

  /// The codec used to encode `creationParams` before sending it to the
  /// platform side. It should match the codec passed to the constructor of [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html#PlatformViewFactory-io.flutter.plugin.common.MessageCodec-).
  ///
  /// This is typically one of: [StandardMessageCodec], [JSONMessageCodec], [StringCodec], or [BinaryCodec].
  ///
  /// This must not be null if [creationParams] is not null.
  final MessageCodec<dynamic> creationParamsCodec;

  @override
  State<AndroidView> createState() => _AndroidViewState();
}

// TODO(amirh): describe the embedding mechanism.
// TODO(ychris): remove the documentation for conic path not supported once https://github.com/flutter/flutter/issues/35062 is resolved.
/// Embeds an iOS view in the Widget hierarchy.
///
/// {@macro flutter.rendering.platformView.preview}
///
/// Embedding iOS views is an expensive operation and should be avoided when a Flutter
/// equivalent is possible.
///
/// {@macro flutter.widgets.platformViews.layout}
///
/// {@macro flutter.widgets.platformViews.gestures}
///
/// {@macro flutter.widgets.platformViews.lifetime}
///
/// Construction of UIViews is done asynchronously, before the UIView is ready this widget paints
/// nothing while maintaining the same layout constraints.
///
/// If a conic path clipping is applied to a UIKitView,
/// a quad path is used to approximate the clip due to limitation of Quartz.
class UiKitView extends StatefulWidget {
  /// Creates a widget that embeds an iOS view.
  ///
  /// {@macro flutter.widgets.platformViews.constructorParams}
  const UiKitView({
    Key key,
    @required this.viewType,
    this.onPlatformViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.layoutDirection,
    this.creationParams,
    this.creationParamsCodec,
    this.gestureRecognizers,
  }) : assert(viewType != null),
       assert(hitTestBehavior != null),
       assert(creationParams == null || creationParamsCodec != null),
       super(key: key);

  // TODO(amirh): reference the iOS API doc once available.
  /// The unique identifier for iOS view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  /// {@macro flutter.widgets.platformViews.createdParam}
  final PlatformViewCreatedCallback onPlatformViewCreated;

  /// {@macro flutter.widgets.platformViews.hittestParam}
  final PlatformViewHitTestBehavior hitTestBehavior;

  /// {@macro flutter.widgets.platformViews.directionParam}
  final TextDirection layoutDirection;

  /// Passed as the `arguments` argument of [-\[FlutterPlatformViewFactory createWithFrame:viewIdentifier:arguments:\]](/objcdoc/Protocols/FlutterPlatformViewFactory.html#/c:objc(pl)FlutterPlatformViewFactory(im)createWithFrame:viewIdentifier:arguments:)
  ///
  /// This can be used by plugins to pass constructor parameters to the embedded iOS view.
  final dynamic creationParams;

  /// The codec used to encode `creationParams` before sending it to the
  /// platform side. It should match the codec returned by [-\[FlutterPlatformViewFactory createArgsCodec:\]](/objcdoc/Protocols/FlutterPlatformViewFactory.html#/c:objc(pl)FlutterPlatformViewFactory(im)createArgsCodec)
  ///
  /// This is typically one of: [StandardMessageCodec], [JSONMessageCodec], [StringCodec], or [BinaryCodec].
  ///
  /// This must not be null if [creationParams] is not null.
  final MessageCodec<dynamic> creationParamsCodec;

  /// Which gestures should be forwarded to the UIKit view.
  ///
  /// {@macro flutter.widgets.platformViews.gestureRecognizersDescHead}
  ///
  /// For example, with the following setup vertical drags will not be dispatched to the UIKit
  /// view as the vertical drag gesture is claimed by the parent [GestureDetector].
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: UiKitView(
  ///     viewType: 'webview',
  ///   ),
  /// )
  /// ```
  ///
  /// To get the [UiKitView] to claim the vertical drag gestures we can pass a vertical drag
  /// gesture recognizer factory in [gestureRecognizers] e.g:
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: SizedBox(
  ///     width: 200.0,
  ///     height: 100.0,
  ///     child: UiKitView(
  ///       viewType: 'webview',
  ///       gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
  ///         new Factory<OneSequenceGestureRecognizer>(
  ///           () => new EagerGestureRecognizer(),
  ///         ),
  ///       ].toSet(),
  ///     ),
  ///   ),
  /// )
  /// ```
  ///
  /// {@macro flutter.widgets.platformViews.gestureRecognizersDescFoot}
  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  // TODO(amirh): get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  State<UiKitView> createState() => _UiKitViewState();
}

/// Embeds an HTML element in the Widget hierarchy in Flutter Web.
///
/// *NOTE*: This only works in Flutter Web. To embed web content on other
/// platforms, consider using the `flutter_webview` plugin.
///
/// Embedding HTML is an expensive operation and should be avoided when a
/// Flutter equivalent is possible.
///
/// The embedded HTML is painted just like any other Flutter widget and
/// transformations apply to it as well. This widget should only be used in
/// Flutter Web.
///
/// {@macro flutter.widgets.platformViews.layout}
///
/// Due to security restrictions with cross-origin `<iframe>` elements, Flutter
/// cannot dispatch pointer events to an HTML view. If an `<iframe>` is the
/// target of an event, the window containing the `<iframe>` is not notified
/// of the event. In particular, this means that any pointer events which land
/// on an `<iframe>` will not be seen by Flutter, and so the HTML view cannot
/// participate in gesture detection with other widgets.
///
/// The way we enable accessibility on Flutter for web is to have a full-page
/// button which waits for a double tap. Placing this full-page button in front
/// of the scene would cause platform views not to receive pointer events. The
/// tradeoff is that by placing the scene in front of the semantics placeholder
/// will cause platform views to block pointer events from reaching the
/// placeholder. This means that in order to enable accessibility, you must
/// double tap the app *outside of a platform view*. As a consequence, a
/// full-screen platform view will make it impossible to enable accessibility.
/// Make sure that your HTML views are sized no larger than necessary, or you
/// may cause difficulty for users trying to enable accessibility.
///
/// {@macro flutter.widgets.platformViews.lifetime}
class HtmlElementView extends StatelessWidget {
  /// Creates a platform view for Flutter Web.
  ///
  /// `viewType` identifies the type of platform view to create.
  const HtmlElementView({
    Key key,
    @required this.viewType,
  }) : assert(viewType != null),
       assert(kIsWeb, 'HtmlElementView is only available on Flutter Web.'),
       super(key: key);

  /// The unique identifier for the HTML view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      onCreatePlatformView: _createHtmlElementView,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return PlatformViewSurface(
          controller: controller,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
    );
  }

  /// Creates the controller and kicks off its initialization.
  _HtmlElementViewController _createHtmlElementView(PlatformViewCreationParams params) {
    final _HtmlElementViewController controller = _HtmlElementViewController(params.id, viewType);
    controller._initialize().then((_) { params.onPlatformViewCreated(params.id); });
    return controller;
  }
}

class _HtmlElementViewController extends PlatformViewController {
  _HtmlElementViewController(
    this.viewId,
    this.viewType,
  );

  @override
  final int viewId;

  /// The unique identifier for the HTML view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  bool _initialized = false;

  Future<void> _initialize() async {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': viewType,
    };
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    _initialized = true;
  }

  @override
  Future<void> clearFocus() async {
    // Currently this does nothing on Flutter Web.
    // TODO(het): Implement this. See https://github.com/flutter/flutter/issues/39496
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    // We do not dispatch pointer events to HTML views because they may contain
    // cross-origin iframes, which only accept user-generated events.
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      await SystemChannels.platform_views.invokeMethod<void>('dispose', viewId);
    }
  }
}

class _AndroidViewState extends State<AndroidView> {
  int _id;
  AndroidViewController _controller;
  TextDirection _layoutDirection;
  bool _initialized = false;
  FocusNode _focusNode;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
    <Factory<OneSequenceGestureRecognizer>>{};

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: _onFocusChange,
      child: _AndroidPlatformView(
        controller: _controller,
        hitTestBehavior: widget.hitTestBehavior,
        gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizersSet,
      ),
    );
  }

  void _initializeOnce() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _createNewAndroidView();
    _focusNode = FocusNode(debugLabel: 'AndroidView(id: $_id)');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    _initializeOnce();
    if (didChangeLayoutDirection) {
      // The native view will update asynchronously, in the meantime we don't want
      // to block the framework. (so this is intentionally not awaiting).
      _controller.setLayoutDirection(_layoutDirection);
    }
  }

  @override
  void didUpdateWidget(AndroidView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (widget.viewType != oldWidget.viewType) {
      _controller.dispose();
      _createNewAndroidView();
      return;
    }

    if (didChangeLayoutDirection) {
      _controller.setLayoutDirection(_layoutDirection);
    }
  }

  TextDirection _findLayoutDirection() {
    assert(widget.layoutDirection != null || debugCheckHasDirectionality(context));
    return widget.layoutDirection ?? Directionality.of(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createNewAndroidView() {
    _id = platformViewsRegistry.getNextPlatformViewId();
    _controller = PlatformViewsService.initAndroidView(
      id: _id,
      viewType: widget.viewType,
      layoutDirection: _layoutDirection,
      creationParams: widget.creationParams,
      creationParamsCodec: widget.creationParamsCodec,
      onFocus: () {
        _focusNode.requestFocus();
      },
    );
    if (widget.onPlatformViewCreated != null) {
      _controller.addOnPlatformViewCreatedListener(widget.onPlatformViewCreated);
    }
  }

  void _onFocusChange(bool isFocused) {
    if (!_controller.isCreated) {
      return;
    }
    if (!isFocused) {
      _controller.clearFocus().catchError((dynamic e) {
        if (e is MissingPluginException) {
          // We land the framework part of Android platform views keyboard
          // support before the engine part. There will be a commit range where
          // clearFocus isn't implemented in the engine. When that happens we
          // just swallow the error here. Once the engine part is rolled to the
          // framework I'll remove this.
          // TODO(amirh): remove this once the engine's clearFocus is rolled.
          return;
        }
      });
      return;
    }
    SystemChannels.textInput.invokeMethod<void>(
      'TextInput.setPlatformViewClient',
      _id,
    ).catchError((dynamic e) {
      if (e is MissingPluginException) {
        // We land the framework part of Android platform views keyboard
        // support before the engine part. There will be a commit range where
        // setPlatformViewClient isn't implemented in the engine. When that
        // happens we just swallow the error here. Once the engine part is
        // rolled to the framework I'll remove this.
        // TODO(amirh): remove this once the engine's clearFocus is rolled.
        return;
      }
    });
  }
}

class _UiKitViewState extends State<UiKitView> {
  UiKitViewController _controller;
  TextDirection _layoutDirection;
  bool _initialized = false;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
    <Factory<OneSequenceGestureRecognizer>>{};

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox.expand();
    }
    return _UiKitPlatformView(
      controller: _controller,
      hitTestBehavior: widget.hitTestBehavior,
      gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizersSet,
    );
  }

  void _initializeOnce() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _createNewUiKitView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    _initializeOnce();
    if (didChangeLayoutDirection) {
      // The native view will update asynchronously, in the meantime we don't want
      // to block the framework. (so this is intentionally not awaiting).
      _controller?.setLayoutDirection(_layoutDirection);
    }
  }

  @override
  void didUpdateWidget(UiKitView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (widget.viewType != oldWidget.viewType) {
      _controller?.dispose();
      _createNewUiKitView();
      return;
    }

    if (didChangeLayoutDirection) {
      _controller?.setLayoutDirection(_layoutDirection);
    }
  }

  TextDirection _findLayoutDirection() {
    assert(widget.layoutDirection != null || debugCheckHasDirectionality(context));
    return widget.layoutDirection ?? Directionality.of(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _createNewUiKitView() async {
    final int id = platformViewsRegistry.getNextPlatformViewId();
    final UiKitViewController controller = await PlatformViewsService.initUiKitView(
      id: id,
      viewType: widget.viewType,
      layoutDirection: _layoutDirection,
      creationParams: widget.creationParams,
      creationParamsCodec: widget.creationParamsCodec,
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    if (widget.onPlatformViewCreated != null) {
      widget.onPlatformViewCreated(id);
    }
    setState(() { _controller = controller; });
  }
}

class _AndroidPlatformView extends LeafRenderObjectWidget {
  const _AndroidPlatformView({
    Key key,
    @required this.controller,
    @required this.hitTestBehavior,
    @required this.gestureRecognizers,
  }) : assert(controller != null),
       assert(hitTestBehavior != null),
       assert(gestureRecognizers != null),
       super(key: key);

  final AndroidViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderAndroidView(
        viewController: controller,
        hitTestBehavior: hitTestBehavior,
        gestureRecognizers: gestureRecognizers,
      );

  @override
  void updateRenderObject(BuildContext context, RenderAndroidView renderObject) {
    renderObject.viewController = controller;
    renderObject.hitTestBehavior = hitTestBehavior;
    renderObject.updateGestureRecognizers(gestureRecognizers);
  }
}

class _UiKitPlatformView extends LeafRenderObjectWidget {
  const _UiKitPlatformView({
    Key key,
    @required this.controller,
    @required this.hitTestBehavior,
    @required this.gestureRecognizers,
  }) : assert(controller != null),
       assert(hitTestBehavior != null),
       assert(gestureRecognizers != null),
       super(key: key);

  final UiKitViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderUiKitView(
      viewController: controller,
      hitTestBehavior: hitTestBehavior,
      gestureRecognizers: gestureRecognizers,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderUiKitView renderObject) {
    renderObject.viewController = controller;
    renderObject.hitTestBehavior = hitTestBehavior;
    renderObject.updateGestureRecognizers(gestureRecognizers);
  }
}

/// The parameters used to create a [PlatformViewController].
///
/// See also:
///
///  * [CreatePlatformViewCallback] which uses this object to create a [PlatformViewController].
class PlatformViewCreationParams {

  const PlatformViewCreationParams._({
    @required this.id,
    @required this.viewType,
    @required this.onPlatformViewCreated,
    @required this.onFocusChanged,
  }) : assert(id != null),
       assert(onPlatformViewCreated != null);

  /// The unique identifier for the new platform view.
  ///
  /// [PlatformViewController.viewId] should match this id.
  final int id;

  /// The unique identifier for the type of platform view to be embedded.
  ///
  /// This viewType is used to tell the platform which type of view to
  /// associate with the [id].
  final String viewType;

  /// Callback invoked after the platform view has been created.
  final PlatformViewCreatedCallback onPlatformViewCreated;

  /// Callback invoked when the platform view's focus is changed on the platform side.
  ///
  /// The value is true when the platform view gains focus and false when it loses focus.
  final ValueChanged<bool> onFocusChanged;
}

/// A factory for a surface presenting a platform view as part of the widget hierarchy.
///
/// The returned widget should present the platform view associated with `controller`.
///
/// See also:
///
///  * [PlatformViewSurface], a common widget for presenting platform views.
typedef PlatformViewSurfaceFactory = Widget Function(BuildContext context, PlatformViewController controller);

/// Constructs a [PlatformViewController].
///
/// The [PlatformViewController.viewId] field of the created controller must match the value of the
/// params [PlatformViewCreationParams.id] field.
///
/// See also:
///
///  * [PlatformViewLink], which links a platform view with the Flutter framework.
typedef CreatePlatformViewCallback = PlatformViewController Function(PlatformViewCreationParams params);

/// Links a platform view with the Flutter framework.
///
/// Provides common functionality for embedding a platform view (e.g an android.view.View on Android)
/// with the Flutter framework.
///
/// {@macro flutter.widgets.platformViews.lifetime}
///
/// To implement a new platform view widget, return this widget in the `build` method.
/// For example:
/// ```dart
/// class FooPlatformView extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return PlatformViewLink(
///       viewType: 'webview',
///       onCreatePlatformView: createFooWebView,
///       surfaceFactory: (BuildContext context, PlatformViewController controller) {
///        return PlatformViewSurface(
///            gestureRecognizers: gestureRecognizers,
///            controller: controller,
///            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
///        );
///       },
///    );
///   }
/// }
/// ```
///
/// The `surfaceFactory` and the `onCreatePlatformView` are only called when the
/// state of this widget is initialized, or when the `viewType` changes.
class PlatformViewLink extends StatefulWidget {

  /// Construct a [PlatformViewLink] widget.
  ///
  /// The `surfaceFactory` and the `onCreatePlatformView` must not be null.
  ///
  /// See also:
  ///
  ///  * [PlatformViewSurface] for details on the widget returned by `surfaceFactory`.
  ///  * [PlatformViewCreationParams] for how each parameter can be used when implementing `createPlatformView`.
  const PlatformViewLink({
    Key key,
    @required PlatformViewSurfaceFactory surfaceFactory,
    @required CreatePlatformViewCallback onCreatePlatformView,
    @required this.viewType,
    }) : assert(surfaceFactory != null),
         assert(onCreatePlatformView != null),
         assert(viewType != null),
         _surfaceFactory = surfaceFactory,
         _onCreatePlatformView = onCreatePlatformView,
         super(key: key);


  final PlatformViewSurfaceFactory _surfaceFactory;
  final CreatePlatformViewCallback _onCreatePlatformView;

  /// The unique identifier for the view type to be embedded.
  ///
  /// Typically, this viewType has already been registered on the platform side.
  final String viewType;

  @override
  State<StatefulWidget> createState() => _PlatformViewLinkState();
}

class _PlatformViewLinkState extends State<PlatformViewLink> {

  int _id;
  PlatformViewController _controller;
  bool _platformViewCreated = false;
  Widget _surface;
  FocusNode _focusNode;

  @override
  Widget build(BuildContext context) {
    if (!_platformViewCreated) {
      return const SizedBox.expand();
    }
    _surface ??= widget._surfaceFactory(context, _controller);
    return Focus(
      focusNode: _focusNode,
      onFocusChange: _handleFrameworkFocusChanged,
      child: _surface,
    );
  }

  @override
  void initState() {
    _focusNode = FocusNode(debugLabel: 'PlatformView(id: $_id)',);
    _initialize();
    super.initState();
  }

  @override
  void didUpdateWidget(PlatformViewLink oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.viewType != oldWidget.viewType) {
      _controller?.dispose();
      // The _surface has to be recreated as its controller is disposed.
      // Setting _surface to null will trigger its creation in build().
      _surface = null;

      // We are about to create a new platform view.
      _platformViewCreated = false;
      _initialize();
    }
  }

  void _initialize() {
    _id = platformViewsRegistry.getNextPlatformViewId();
    _controller = widget._onCreatePlatformView(
      PlatformViewCreationParams._(
        id: _id,
        viewType: widget.viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        onFocusChanged: _handlePlatformFocusChanged,
      ),
    );
  }

  void _onPlatformViewCreated(int id) {
    setState(() { _platformViewCreated = true; });
  }

  void _handleFrameworkFocusChanged(bool isFocused) {
    if (!isFocused) {
      _controller?.clearFocus();
    }
  }

  void _handlePlatformFocusChanged(bool isFocused){
    if (isFocused) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

/// Integrates a platform view with Flutter's compositor, touch, and semantics subsystems.
///
/// The compositor integration is done by adding a [PlatformViewLayer] to the layer tree. [PlatformViewSurface]
/// isn't supported on all platforms (e.g on Android platform views can be composited by using a [TextureLayer] or
/// [AndroidViewSurface]).
/// Custom Flutter embedders can support [PlatformViewLayer]s by implementing a SystemCompositor.
///
/// The widget fills all available space, the parent of this object must provide bounded layout
/// constraints.
///
/// If the associated platform view is not created the [PlatformViewSurface] does not paint any contents.
///
/// See also:
///
///  * [AndroidView] which embeds an Android platform view in the widget hierarchy using a [TextureLayer].
///  * [UiKitView] which embeds an iOS platform view in the widget hierarchy.
// TODO(amirh): Link to the embedder's system compositor documentation once available.
class PlatformViewSurface extends LeafRenderObjectWidget {

  /// Construct a `PlatformViewSurface`.
  ///
  /// The [controller] must not be null.
  const PlatformViewSurface({
    Key key,
    @required this.controller,
    @required this.hitTestBehavior,
    @required this.gestureRecognizers,
  }) : assert(controller != null),
       assert(hitTestBehavior != null),
       assert(gestureRecognizers != null),
       super(key: key);

  /// The controller for the platform view integrated by this [PlatformViewSurface].
  ///
  /// [PlatformViewController] is used for dispatching touch events to the platform view.
  /// [PlatformViewController.viewId] identifies the platform view whose contents are painted by this widget.
  final PlatformViewController controller;

  /// Which gestures should be forwarded to the PlatformView.
  ///
  /// {@macro flutter.widgets.platformViews.gestureRecognizersDescHead}
  ///
  /// For example, with the following setup vertical drags will not be dispatched to the platform view
  /// as the vertical drag gesture is claimed by the parent [GestureDetector].
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: PlatformViewSurface(
  ///   ),
  /// )
  /// ```
  ///
  /// To get the [PlatformViewSurface] to claim the vertical drag gestures we can pass a vertical drag
  /// gesture recognizer factory in [gestureRecognizers] e.g:
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: SizedBox(
  ///     width: 200.0,
  ///     height: 100.0,
  ///     child: PlatformViewSurface(
  ///       gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
  ///         new Factory<OneSequenceGestureRecognizer>(
  ///           () => new EagerGestureRecognizer(),
  ///         ),
  ///       ].toSet(),
  ///     ),
  ///   ),
  /// )
  /// ```
  ///
  /// {@macro flutter.widgets.platformViews.gestureRecognizersDescFoot}
  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  // TODO(amirh): get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// {@macro flutter.widgets.platformViews.hittestParam}
  final PlatformViewHitTestBehavior hitTestBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return PlatformViewRenderBox(controller: controller, gestureRecognizers: gestureRecognizers, hitTestBehavior: hitTestBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, PlatformViewRenderBox renderObject) {
    renderObject
      ..controller = controller
      ..hitTestBehavior = hitTestBehavior
      ..updateGestureRecognizers(gestureRecognizers);
  }
}

/// Integrates an Android view with Flutter's compositor, touch, and semantics subsystems.
///
/// The compositor integration is done by adding a [PlatformViewLayer] to the layer tree. [PlatformViewLayer]
/// isn't supported on all platforms. Custom Flutter embedders can support
/// [PlatformViewLayer]s by implementing a SystemCompositor.
///
/// The widget fills all available space, the parent of this object must provide bounded layout
/// constraints.
///
/// If the associated platform view is not created, the [AndroidViewSurface] does not paint any contents.
///
/// See also:
///
///  * [AndroidView] which embeds an Android platform view in the widget hierarchy using a [TextureLayer].
///  * [UiKitView] which embeds an iOS platform view in the widget hierarchy.
class AndroidViewSurface extends PlatformViewSurface {
  /// Construct an `AndroidPlatformViewSurface`.
  const AndroidViewSurface({
    Key key,
    @required AndroidViewController controller,
    @required PlatformViewHitTestBehavior hitTestBehavior,
    @required Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  }) : assert(controller != null),
       assert(hitTestBehavior != null),
       assert(gestureRecognizers != null),
       super(
          key: key,
          controller: controller,
          hitTestBehavior: hitTestBehavior,
          gestureRecognizers: gestureRecognizers);

  @override
  RenderObject createRenderObject(BuildContext context) {
    final PlatformViewRenderBox renderBox =
        super.createRenderObject(context) as PlatformViewRenderBox;

    (controller as AndroidViewController).pointTransformer =
        (Offset position) => renderBox.globalToLocal(position);

    return renderBox;
  }
}
