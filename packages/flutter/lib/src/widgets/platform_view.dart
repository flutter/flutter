// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'debug.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';

/// The function to build a `PlatformViewSurface`.
///
/// It is used when constructing a `PlatformViewControllerWidget`.
/// A sample implementation could be:
/// ```dart
/// (BuildContext context, int id, PlatformViewController controller) {
///        return PlatformViewSurface(
///            context: context,
///            id: id,
///            gestureRecognizers: gestureRecognizers,
///             controller: controller,
///        );
///       }
/// ```
///
/// See also:
/// * `PlatformViewSurface` for more details.
typedef PlatformViewSurfaceBuilder = PlatformViewSurface Function(BuildContext context, int id, PlatformViewController controller);

/// The function to create a `PlatformViewController`.
///
/// The implementer of a new platform view is responsible to implement this method when constructing a `PlatformViewControllerWidget`.
/// See `PlatformViewControllerWidget.createPlatformView` for a sample implementation.
typedef CreatePlatformView = PlatformViewController Function(PlatformViewCreationParams params);

/// The implementer of a new platform view need to implement this.
///
/// An instance of the implemented subclass should be returned in [PlatformViewControllerWidget.createPlatformView].
abstract class PlatformViewController {

  /// Implement this if the new platform view needs to handle focus(Android for example).
  /// e.g.
  /// ```dart
  /// Future<void> dispose() async {
  ///   await SystemChannels.platform_views.invokeMethod<void>('clearFocus', id);
  /// }
  /// ```
  /// See `SystemChannels.platform_views` for more details.
  // TODO(cyanglaz): Invoke this method after figuring out how to handle focus, https://github.com/flutter/flutter/issues/36779
  Future<void> clearFocus();

  /// Implement this if the new platform view cannot receive gesture directly and
  /// needs the framework to dispatch pointer events to the platform(Android for example).
  // TODO(cyanglaz): Invoke this method after implementing `PlatformViewSurface`, https://github.com/flutter/flutter/issues/36779
  void dispatchPointerEvent(PointerEvent event);

  /// Invoked when the state of `PlatformViewControllerWidget` is disposed. Implement this to properly dispose resources of the new platform view from the platform.
  ///
  /// e.g.
  /// ```dart
  /// Future<void> dispose() async {
  ///   await SystemChannels.platform_views.invokeMethod<void>('dispose', id);
  /// }
  /// ```
  /// See `SystemChannels.platform_views` for more details.
  void dispose();
}

/// The widget responsible for handling the life cycle and focus for implementing platform view widget.
///
/// To implement a new platform view widget, return this widget in the `build` method.
/// e.g:
/// ```dart
/// class FooPlatformView extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return PlatformViewControllerWidget(
///       createCallback: createFooWebView,
///      builder: (BuildContext context, int id, PlatformViewController controller) {
///        return PlatformViewSurface(
///            context: context,
///            id: id,
///            gestureRecognizers: gestureRecognizers,
///             controller: controller,
///        );
///       },
///    );
///   }
/// }
/// ```
class PlatformViewControllerWidget extends StatefulWidget {

  /// Construct a `PlatformViewControllerWidget` widget.
  ///
  /// The [builder] and the [createPlatformView] must not be null. In most cases, the [onPlatformViewCreated] should not be null and you should expose it
  /// to your widget that is building the `PlatformViewControllerWidget`; it lets the developers who uses your widget be able to get notified when the underlying
  /// platform view is created.
  const PlatformViewControllerWidget({
    @required this.builder,
    @required this.createPlatformView,
    this.onPlatformViewCreated}): assert(builder != null),
                                  assert(createPlatformView != null);

  /// The method that returns a `PlatformViewSurface` widget.
  ///
  /// The implementer of a new platform view is responsible to implement this method,
  /// A simple example would be:
  /// ```dart
  /// builder: (BuildContext context, int id, PlatformViewController controller) {
  ///   return PlatformViewSurface(
  ///        context: context,
  ///        id: id,
  ///        gestureRecognizers: gestureRecognizers,
  ///        controller: controller,
  ///    );
  /// },
  /// ```
  /// See also:
  /// * `PlatformViewSurface` for more details.
  final PlatformViewSurfaceBuilder builder;

  /// The method to create the platform view.
  ///
  /// The implementer of a new platform view is responsible to define this method and pass it
  /// to the constructor of `PlatformViewControllerWidget`.
  /// This method will get invoked when the state of `PlatformViewControllerWidget` is initialized.
  ///
  /// A simple example of implementing this function for foo platform can be:
  /// ```dart
  /// FooPlatformViewController createPlatformView(PlatformViewCreationParams params) {
  ///   final FooPlatformViewController controller = FooPlatformViewController(id: params.id);
  ///   params.onPlatformViewCreated(id);
  ///   return controller;
  /// }
  ///```
  final CreatePlatformView createPlatformView;

  /// Invoked when the platform view is created.
  ///
  /// The `createPlatformView` is responsible to invoke the `onPlatformViewCreated` in one of its parameters at the appropriate time.
  /// This should be propagated to the implementing platform view so the developer who uses the platform view have access to this callback.
  /// See also
  /// * `createPlatformView` for a sample of implementing `createPlatformView`, which also provides a sample on how to call `onPlatformViewCreated`.
  final PlatformViewCreatedCallback onPlatformViewCreated;

  @override
  State<StatefulWidget> createState() {
    return _PlatformViewControllerWidgetState();
  }
}

class _PlatformViewControllerWidgetState extends State<PlatformViewControllerWidget> {

  int _id;

  PlatformViewController _controller;

  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox.expand();
    }
    return widget.builder(context, _id, _controller);
  }

  void _initializeOnce() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _id = platformViewsRegistry.getNextPlatformViewId();
    _controller = widget.createPlatformView(PlatformViewCreationParams._(id:_id, onPlatformViewCreated:_onPlatformViewCreated, onFocusChanged: _onFocusChanged));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeOnce();
  }

  void _onFocusChanged(bool isFocused) {
    //TODO(cyanglaz): impl, https://github.com/flutter/flutter/issues/36779
  }

  void _onPlatformViewCreated(int id) {
    widget.onPlatformViewCreated(id);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// The widget responsible to handle painting, gestures and semantics of the `PlatformViewControllerWidget`.
///
/// This widget should be constructed and returned in the `PlatformViewControllerWidget.builder`.
class PlatformViewSurface extends LeafRenderObjectWidget {

  /// Construct a `PlatformViewSurface`. Usually returned from `PlatformViewControllerWidget.builder`.
  ///
  /// The [context], the [id] and the [controller] must not be null.
  /// The `PlatformViewControllerWidget.builder` should provide [context], [id] and [controller];
  /// normally, you would use those directly when constructing the `PlatformViewSurface`.
  ///
  /// See also
  /// * `PlatformViewControllerWidget.builder` for how to construct a `PlatformViewSurface` inside the builder.
  const PlatformViewSurface({
    @required this.context,
    @required this.id,
    @required this.controller,
    this.gestureRecognizers}):assert(context != null),
                                assert(id != null),
                                assert(controller != null);

  /// The context which the widget is built with.
  final BuildContext context;

  /// The id of the platform view that is associate with this `PlatformViewSurface`.
  final int id;

  /// Which gestures should be forwarded to the platform view.
  ///
  /// {@macro flutter.widgets.platformViews.gestureRecognizersDescHead}
  ///
  /// The below example uses a [FooPlatformView] which is a implementation of a platform view with the help of `PlatformViewControllerWidget`.
  /// With the following setup vertical drags will not be dispatched to the platform
  /// view as the vertical drag gesture is claimed by the parent [GestureDetector].
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: FooPlatformView(
  ///   ),
  /// )
  /// ```
  ///
  /// To get the [FooPlatformView] to claim the vertical drag gestures we can pass a vertical drag
  /// gesture recognizer factory in [gestureRecognizers] e.g:
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: SizedBox(
  ///     width: 200.0,
  ///     height: 100.0,
  ///     child: FooPlatformView(
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
  ///
  /// See also:
  /// * `PlatformViewControllerWidget` for how to implement a platform view.
  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The controller that is implemented by the platform view implementer.
  ///
  /// The controller is responsible for:
  /// * handling clearing focus
  /// * dispatching pointer events
  /// * dispose
  /// Some of these are not applicable to certain platforms. For example, iOS does not require
  /// dispatching the pointer events.
  ///
  /// See `PlatformViewController` for how to implement a new PlatformViewController.
  final PlatformViewController controller;

  @override
  RenderObject createRenderObject(BuildContext context) {
    // TODO(cyanglaz): implement createRenderObject, https://github.com/flutter/flutter/issues/36779
    return null;
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    // TODO(cyanglaz): implement updateRenderObject, https://github.com/flutter/flutter/issues/36779
  }
}

/// The parameters used for creating a [FooPlatformViewController] that is a subclass of `PlatformViewController`.
class PlatformViewCreationParams {

  const PlatformViewCreationParams._({
    @required this.id,
    @required this.onPlatformViewCreated,
    this.onFocusChanged}):assert(id != null),
                          assert(onPlatformViewCreated != null);

  /// The auto generated id for the newly created platform view.
  ///
  /// Use the auto generated id lets the framework handles things like semantics for you.
  /// The implementer of a new platform view should almost never manually create an id for a new platform view.
  final int id;

  /// The implementer of a new platform view must call this when the platform view is created and ready from the platform.
  ///
  /// For example, on iOS, this has to be called when we know the UIView is initialized.
  final PlatformViewCreatedCallback onPlatformViewCreated;

  /// The implementer is responsible to invoke this method when the focus is changed.
  ///
  /// For example, if the `PlatformViewControllerWidget` is wrapped around a `FocusNode` widget inside the [build] method of the implemented
  /// [FooPlatformView] widget, this can be passed to the `FocusNode`'s constructor.
  /// e.g.
  /// e.g:
  /// ```dart
  /// class FooPlatformView extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return FocusNode(
  ///       onFocusChange: onFocusChanged,
  ///       child: PlatformViewControllerWidget(
  ///         createCallback: createFooWebView,
  ///       builder: (BuildContext context, int id, PlatformViewController controller) {
  ///         return PlatformViewSurface(
  ///             context: context,
  ///             id: id,
  ///             gestureRecognizers: gestureRecognizers,
  ///             controller: controller,
  ///        );
  ///       },
  ///    );
  ///   }
  /// }
  /// ```
  ///
  /// If your platform view doesn't need to handle focus, you can ignore this.
  final ValueChanged<bool> onFocusChanged;
}

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
/// The widget participates in Flutter's [GestureArena]s, and dispatches touch events to the
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
/// or it has a [GlobalKey] and it's moved within the tree, it will not be disposed.x
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
  /// See also: [AndroidView] for an example of registering a platform view factory.
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
      }
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
