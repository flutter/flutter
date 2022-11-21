// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'binding.dart';
import 'debug.dart';
import 'framework.dart';
import 'inherited_model.dart';

// Examples can assume:
// late BuildContext context;

/// Whether in portrait or landscape.
enum Orientation {
  /// Taller than wide.
  portrait,

  /// Wider than tall.
  landscape
}

enum _ViewQueryAspect {
  size,
  orientation,
  devicePixelRatio,
  padding,
  viewInsets,
  systemGestureInsets,
  viewPadding,
  gestureSettings,
  displayFeatures,
}

/// Information about a view.
///
/// For example, the [ViewQueryData.size] property contains the width and
/// height of the current view.
///
/// To obtain the current [ViewQueryData] for a given [BuildContext], use the
/// [ViewQuery.of] function. For example, to obtain the size of the current
/// window, use `ViewQuery.of(context).size`.
///
/// If no [ViewQuery] is in scope then the [ViewQuery.of] method will throw an
/// exception. Alternatively, [ViewQuery.maybeOf] may be used, which returns
/// null instead of throwing if no [ViewQuery] is in scope.
///
/// ## Insets and Padding
///
/// ![A diagram of padding, viewInsets, and viewPadding in correlation with each
/// other](https://flutter.github.io/assets-for-api-docs/assets/widgets/media_query.png)
///
/// This diagram illustrates how [padding] relates to [viewPadding] and
/// [viewInsets], shown here in its simplest configuration, as the difference
/// between the two. In cases when the viewInsets exceed the viewPadding, like
/// when a software keyboard is shown below, padding goes to zero rather than a
/// negative value. Therefore, padding is calculated by taking
/// `max(0.0, viewPadding - viewInsets)`.
///
/// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/widgets/window_padding.mp4}
///
/// In this diagram, the black areas represent system UI that the app cannot
/// draw over. The red area represents view padding that the application may not
/// be able to detect gestures in and may not want to draw in. The grey area
/// represents the system keyboard, which can cover over the bottom view padding
/// when visible.
///
/// ViewQueryData includes three [EdgeInsets] values:
/// [padding], [viewPadding], and [viewInsets]. These values reflect the
/// configuration of the device and are used and optionally consumed by widgets
/// that position content within these insets. The padding value defines areas
/// that might not be completely visible, like the display "notch" on the iPhone
/// X. The viewInsets value defines areas that aren't visible at all, typically
/// because they're obscured by the device's keyboard. Similar to viewInsets,
/// viewPadding does not differentiate padding in areas that may be obscured.
/// For example, by using the viewPadding property, padding would defer to the
/// iPhone "safe area" regardless of whether a keyboard is showing.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ceCo8U0XHqw}
///
/// The viewInsets and viewPadding are independent values, they're
/// measured from the edges of the ViewQuery widget's bounds. Together they
/// inform the [padding] property. The bounds of the top level ViewQuery
/// created by [WidgetsApp] are the same as the window that contains the app.
///
/// Widgets whose layouts consume space defined by [viewInsets], [viewPadding],
/// or [padding] should enclose their children in secondary ViewQuery
/// widgets that reduce those properties by the same amount.
/// The [removePadding], [removeViewPadding], and [removeViewInsets] methods are
/// useful for this.
///
/// See also:
///
///  * [Scaffold], [SafeArea], [CupertinoTabScaffold], and
///    [CupertinoPageScaffold], all of which are informed by [padding],
///    [viewPadding], and [viewInsets].
@immutable
class ViewQueryData {
  /// Creates data for a media query with explicit values.
  ///
  /// Consider using [ViewQueryData.fromView] to create data based on a
  /// [dart:ui.FlutterView].
  const ViewQueryData({
    this.size = Size.zero,
    this.devicePixelRatio = 1.0,
    this.padding = EdgeInsets.zero,
    this.viewInsets = EdgeInsets.zero,
    this.systemGestureInsets = EdgeInsets.zero,
    this.viewPadding = EdgeInsets.zero,
    this.gestureSettings = const DeviceGestureSettings(touchSlop: kTouchSlop),
    this.displayFeatures = const <ui.DisplayFeature>[],
  }) : assert(size != null),
       assert(devicePixelRatio != null),
       assert(padding != null),
       assert(viewInsets != null),
       assert(systemGestureInsets != null),
       assert(viewPadding != null),
       assert(gestureSettings != null),
       assert(displayFeatures != null);

  /// Creates data for a media query based on the given window.
  ///
  /// If you use this, you should ensure that you also register for
  /// notifications so that you can update your [ViewQueryData] when the
  /// window's metrics change. For example, see
  /// [WidgetsBindingObserver.didChangeMetrics] or
  /// [dart:ui.PlatformDispatcher.onMetricsChanged].
  ViewQueryData.fromView(ui.FlutterView view)
      : size = view.physicalSize / view.devicePixelRatio,
        devicePixelRatio = view.devicePixelRatio,
        padding = EdgeInsets.fromWindowPadding(view.padding, view.devicePixelRatio),
        viewPadding = EdgeInsets.fromWindowPadding(view.viewPadding, view.devicePixelRatio),
        viewInsets = EdgeInsets.fromWindowPadding(view.viewInsets, view.devicePixelRatio),
        systemGestureInsets = EdgeInsets.fromWindowPadding(view.systemGestureInsets, view.devicePixelRatio),
        gestureSettings = DeviceGestureSettings.fromWindow(view), // ???
        displayFeatures = view.displayFeatures;

  /// The size of the media in logical pixels (e.g, the size of the screen).
  ///
  /// Logical pixels are roughly the same visual size across devices. Physical
  /// pixels are the size of the actual hardware pixels on the device. The
  /// number of physical pixels per logical pixel is described by the
  /// [devicePixelRatio].
  ///
  /// ## Troubleshooting
  ///
  /// It is considered bad practice to cache and later use the size returned
  /// by `ViewQuery.of(context).size`. It will make the application non responsive
  /// and might lead to unexpected behaviors.
  /// For instance, during startup, especially in release mode, the first returned
  /// size might be (0,0). The size will be updated when the native platform
  /// reports the actual resolution.
  ///
  /// See the article on [Creating responsive and adaptive
  /// apps](https://docs.flutter.dev/development/ui/layout/adaptive-responsive)
  /// for an introduction.
  ///
  /// See also:
  ///
  ///  * [FlutterView.physicalSize], which returns the size in physical pixels.
  ///  * [ViewQuery.sizeOf], a method to find and depend on the size defined
  ///    for a [BuildContext].
  final Size size;

  /// The number of device pixels for each logical pixel. This number might not
  /// be a power of two. Indeed, it might not even be an integer. For example,
  /// the Nexus 6 has a device pixel ratio of 3.5.
  final double devicePixelRatio;

  /// The parts of the display that are completely obscured by system UI,
  /// typically by the device's keyboard.
  ///
  /// When a mobile device's keyboard is visible `viewInsets.bottom`
  /// corresponds to the top of the keyboard.
  ///
  /// This value is independent of the [padding] and [viewPadding]. viewPadding
  /// is measured from the edges of the [ViewQuery] widget's bounds. Padding is
  /// calculated based on the viewPadding and viewInsets. The bounds of the top
  /// level ViewQuery created by [WidgetsApp] are the same as the window
  /// (often the mobile device screen) that contains the app.
  ///
  /// See also:
  ///
  ///  * [ui.window], which provides some additional detail about this property
  ///    and how it relates to [padding] and [viewPadding].
  final EdgeInsets viewInsets;

  /// The parts of the display that are partially obscured by system UI,
  /// typically by the hardware display "notches" or the system status bar.
  ///
  /// If you consumed this padding (e.g. by building a widget that envelops or
  /// accounts for this padding in its layout in such a way that children are
  /// no longer exposed to this padding), you should remove this padding
  /// for subsequent descendants in the widget tree by inserting a new
  /// [ViewQuery] widget using the [ViewQuery.removePadding] factory.
  ///
  /// Padding is derived from the values of [viewInsets] and [viewPadding].
  ///
  /// See also:
  ///
  ///  * [ui.window], which provides some additional detail about this
  ///    property and how it relates to [viewInsets] and [viewPadding].
  ///  * [SafeArea], a widget that consumes this padding with a [Padding] widget
  ///    and automatically removes it from the [ViewQuery] for its child.
  final EdgeInsets padding;

  /// The parts of the display that are partially obscured by system UI,
  /// typically by the hardware display "notches" or the system status bar.
  ///
  /// This value remains the same regardless of whether the system is reporting
  /// other obstructions in the same physical area of the screen. For example, a
  /// software keyboard on the bottom of the screen that may cover and consume
  /// the same area that requires bottom padding will not affect this value.
  ///
  /// This value is independent of the [padding] and [viewInsets]: their values
  /// are measured from the edges of the [ViewQuery] widget's bounds. The
  /// bounds of the top level ViewQuery created by [WidgetsApp] are the
  /// same as the window that contains the app. On mobile devices, this will
  /// typically be the full screen.
  ///
  /// See also:
  ///
  ///  * [ui.window], which provides some additional detail about this
  ///    property and how it relates to [padding] and [viewInsets].
  final EdgeInsets viewPadding;

  /// The areas along the edges of the display where the system consumes
  /// certain input events and blocks delivery of those events to the app.
  ///
  /// Starting with Android Q, simple swipe gestures that start within the
  /// [systemGestureInsets] areas are used by the system for page navigation
  /// and may not be delivered to the app. Taps and swipe gestures that begin
  /// with a long-press are delivered to the app, but simple press-drag-release
  /// swipe gestures which begin within the area defined by [systemGestureInsets]
  /// may not be.
  ///
  /// Apps should avoid locating gesture detectors within the system gesture
  /// insets area. Apps should feel free to put visual elements within
  /// this area.
  ///
  /// This property is currently only expected to be set to a non-default value
  /// on Android starting with version Q.
  ///
  /// {@tool dartpad}
  /// For apps that might be deployed on Android Q devices with full gesture
  /// navigation enabled, use [systemGestureInsets] with [Padding]
  /// to avoid having the left and right edges of the [Slider] from appearing
  /// within the area reserved for system gesture navigation.
  ///
  /// By default, [Slider]s expand to fill the available width. So, we pad the
  /// left and right sides.
  ///
  /// ** See code in examples/api/lib/widgets/media_query/media_query_data.system_gesture_insets.0.dart **
  /// {@end-tool}
  final EdgeInsets systemGestureInsets;

  /// The gesture settings for the view this media query is derived from.
  ///
  /// This contains platform specific configuration for gesture behavior,
  /// such as touch slop. These settings should be favored for configuring
  /// gesture behavior over the framework constants.
  final DeviceGestureSettings gestureSettings;

  /// {@macro dart.ui.ViewConfiguration.displayFeatures}
  ///
  /// See also:
  ///
  ///  * [dart:ui.DisplayFeatureType], which lists the different types of
  ///  display features and explains the differences between them.
  ///  * [dart:ui.DisplayFeatureState], which lists the possible states for
  ///  folding features ([dart:ui.DisplayFeatureType.fold] and
  ///  [dart:ui.DisplayFeatureType.hinge]).
  final List<ui.DisplayFeature> displayFeatures;

  /// The orientation of the media (e.g., whether the device is in landscape or
  /// portrait mode).
  Orientation get orientation {
    return size.width > size.height ? Orientation.landscape : Orientation.portrait;
  }

  /// Creates a copy of this media query data but with the given fields replaced
  /// with the new values.
  ViewQueryData copyWith({
    Size? size,
    double? devicePixelRatio,
    EdgeInsets? padding,
    EdgeInsets? viewPadding,
    EdgeInsets? viewInsets,
    EdgeInsets? systemGestureInsets,
    DeviceGestureSettings? gestureSettings,
    List<ui.DisplayFeature>? displayFeatures,
  }) {
    return ViewQueryData(
      size: size ?? this.size,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      padding: padding ?? this.padding,
      viewPadding: viewPadding ?? this.viewPadding,
      viewInsets: viewInsets ?? this.viewInsets,
      systemGestureInsets: systemGestureInsets ?? this.systemGestureInsets,
      gestureSettings: gestureSettings ?? this.gestureSettings,
      displayFeatures: displayFeatures ?? this.displayFeatures,
    );
  }

  /// Creates a copy of this media query data but with the given [padding]s
  /// replaced with zero.
  ///
  /// The `removeLeft`, `removeTop`, `removeRight`, and `removeBottom` arguments
  /// must not be null. If all four are false (the default) then this
  /// [ViewQueryData] is returned unmodified.
  ///
  /// See also:
  ///
  ///  * [ViewQuery.removePadding], which uses this method to remove [padding]
  ///    from the ambient [ViewQuery].
  ///  * [SafeArea], which both removes the padding from the [ViewQuery] and
  ///    adds a [Padding] widget.
  ///  * [removeViewInsets], the same thing but for [viewInsets].
  ///  * [removeViewPadding], the same thing but for [viewPadding].
  ViewQueryData removePadding({
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
  }) {
    if (!(removeLeft || removeTop || removeRight || removeBottom)) {
      return this;
    }
    return copyWith(
      padding: padding.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
      viewPadding: viewPadding.copyWith(
        left: removeLeft ? math.max(0.0, viewPadding.left - padding.left) : null,
        top: removeTop ? math.max(0.0, viewPadding.top - padding.top) : null,
        right: removeRight ? math.max(0.0, viewPadding.right - padding.right) : null,
        bottom: removeBottom ? math.max(0.0, viewPadding.bottom - padding.bottom) : null,
      ),
    );
  }

  /// Creates a copy of this media query data but with the given [viewInsets]
  /// replaced with zero.
  ///
  /// The `removeLeft`, `removeTop`, `removeRight`, and `removeBottom` arguments
  /// must not be null. If all four are false (the default) then this
  /// [ViewQueryData] is returned unmodified.
  ///
  /// See also:
  ///
  ///  * [ViewQuery.removeViewInsets], which uses this method to remove
  ///    [viewInsets] from the ambient [ViewQuery].
  ///  * [removePadding], the same thing but for [padding].
  ///  * [removeViewPadding], the same thing but for [viewPadding].
  ViewQueryData removeViewInsets({
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
  }) {
    if (!(removeLeft || removeTop || removeRight || removeBottom)) {
      return this;
    }
    return copyWith(
      viewPadding: viewPadding.copyWith(
        left: removeLeft ? math.max(0.0, viewPadding.left - viewInsets.left) : null,
        top: removeTop ? math.max(0.0, viewPadding.top - viewInsets.top) : null,
        right: removeRight ? math.max(0.0, viewPadding.right - viewInsets.right) : null,
        bottom: removeBottom ? math.max(0.0, viewPadding.bottom - viewInsets.bottom) : null,
      ),
      viewInsets: viewInsets.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
    );
  }

  /// Creates a copy of this media query data but with the given [viewPadding]
  /// replaced with zero.
  ///
  /// The `removeLeft`, `removeTop`, `removeRight`, and `removeBottom` arguments
  /// must not be null. If all four are false (the default) then this
  /// [ViewQueryData] is returned unmodified.
  ///
  /// See also:
  ///
  ///  * [ViewQuery.removeViewPadding], which uses this method to remove
  ///    [viewPadding] from the ambient [ViewQuery].
  ///  * [removePadding], the same thing but for [padding].
  ///  * [removeViewInsets], the same thing but for [viewInsets].
  ViewQueryData removeViewPadding({
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
  }) {
    if (!(removeLeft || removeTop || removeRight || removeBottom)) {
      return this;
    }
    return copyWith(
      padding: padding.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
      viewPadding: viewPadding.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
    );
  }

  /// Creates a copy of this media query data by removing [displayFeatures] that
  /// are completely outside the given sub-screen and adjusting the [padding],
  /// [viewInsets] and [viewPadding] to be zero on the sides that are not
  /// included in the sub-screen.
  ///
  /// Returns unmodified [ViewQueryData] if the sub-screen coincides with the
  /// available screen space.
  ///
  /// Asserts in debug mode, if the given sub-screen is outside the available
  /// screen space.
  ///
  /// See also:
  ///
  ///  * [DisplayFeatureSubScreen], which removes the display features that
  ///    split the screen, from the [ViewQuery] and adds a [Padding] widget to
  ///    position the child to match the selected sub-screen.
  ViewQueryData removeDisplayFeatures(Rect subScreen) {
    assert(subScreen.left >= 0.0 && subScreen.top >= 0.0 &&
        subScreen.right <= size.width && subScreen.bottom <= size.height,
    "'subScreen' argument cannot be outside the bounds of the screen");
    if (subScreen.size == size && subScreen.topLeft == Offset.zero) {
      return this;
    }
    final double rightInset = size.width - subScreen.right;
    final double bottomInset = size.height - subScreen.bottom;
    return copyWith(
      padding: EdgeInsets.only(
        left: math.max(0.0, padding.left - subScreen.left),
        top: math.max(0.0, padding.top - subScreen.top),
        right: math.max(0.0, padding.right - rightInset),
        bottom: math.max(0.0, padding.bottom - bottomInset),
      ),
      viewPadding: EdgeInsets.only(
        left: math.max(0.0, viewPadding.left - subScreen.left),
        top: math.max(0.0, viewPadding.top - subScreen.top),
        right: math.max(0.0, viewPadding.right - rightInset),
        bottom: math.max(0.0, viewPadding.bottom - bottomInset),
      ),
      viewInsets: EdgeInsets.only(
        left: math.max(0.0, viewInsets.left - subScreen.left),
        top: math.max(0.0, viewInsets.top - subScreen.top),
        right: math.max(0.0, viewInsets.right - rightInset),
        bottom: math.max(0.0, viewInsets.bottom - bottomInset),
      ),
      displayFeatures: displayFeatures.where(
              (ui.DisplayFeature displayFeature) => subScreen.overlaps(displayFeature.bounds)
      ).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ViewQueryData
        && other.size == size
        && other.devicePixelRatio == devicePixelRatio
        && other.padding == padding
        && other.viewPadding == viewPadding
        && other.viewInsets == viewInsets
        && other.gestureSettings == gestureSettings
        && listEquals(other.displayFeatures, displayFeatures);
  }

  @override
  int get hashCode => Object.hash(
    size,
    devicePixelRatio,
    padding,
    viewPadding,
    viewInsets,
    gestureSettings,
    Object.hashAll(displayFeatures),
  );

  @override
  String toString() {
    final List<String> properties = <String>[
      'size: $size',
      'devicePixelRatio: ${devicePixelRatio.toStringAsFixed(1)}',
      'padding: $padding',
      'viewPadding: $viewPadding',
      'viewInsets: $viewInsets',
      'gestureSettings: $gestureSettings',
      'displayFeatures: $displayFeatures',
    ];
    return '${objectRuntimeType(this, 'ViewQueryData')}(${properties.join(', ')})';
  }
}

/// Establishes a subtree in which view queries resolve to the given data.
///
/// For example, to learn the size of the current view (e.g., the window
/// containing your app), you can read the [ViewQueryData.size] property from
/// the [ViewQueryData] returned by [ViewQuery.of]:
/// `ViewQuery.of(context).size`.
///
/// Querying the current view using [ViewQuery.of] will cause your widget to
/// rebuild automatically whenever the [ViewQueryData] changes (e.g., if the
/// user rotates their device).
///
/// If no [ViewQuery] is in scope then the [ViewQuery.of] method will throw an
/// exception. Alternatively, [ViewQuery.maybeOf] may be used, which returns
/// null instead of throwing if no [ViewQuery] is in scope.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=A3WrA4zAaPw}
///
/// See also:
///
///  * [WidgetsApp] and [MaterialApp], which introduce a [ViewQuery] and keep
///    it up to date with the current screen metrics as they change.
///  * [ViewQueryData], the data structure that represents the metrics.
class ViewQuery extends InheritedModel<_ViewQueryAspect> {
  /// Creates a widget that provides [ViewQueryData] to its descendants.
  ///
  /// The [data] and [child] arguments must not be null.
  const ViewQuery({
    super.key,
    required this.data,
    required super.child,
  }) : assert(child != null),
       assert(data != null);

  /// Creates a new [ViewQuery] that inherits from the ambient [ViewQuery]
  /// from the given context, but removes the specified padding.
  ///
  /// This should be inserted into the widget tree when the [ViewQuery] padding
  /// is consumed by a widget in such a way that the padding is no longer
  /// exposed to the widget's descendants or siblings.
  ///
  /// The [context] argument is required, must not be null, and must have a
  /// [ViewQuery] in scope.
  ///
  /// The `removeLeft`, `removeTop`, `removeRight`, and `removeBottom` arguments
  /// must not be null. If all four are false (the default) then the returned
  /// [ViewQuery] reuses the ambient [ViewQueryData] unmodified, which is not
  /// particularly useful.
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// See also:
  ///
  ///  * [SafeArea], which both removes the padding from the [ViewQuery] and
  ///    adds a [Padding] widget.
  ///  * [ViewQueryData.padding], the affected property of the
  ///    [ViewQueryData].
  ///  * [removeViewInsets], the same thing but for [ViewQueryData.viewInsets].
  ///  * [removeViewPadding], the same thing but for
  ///    [ViewQueryData.viewPadding].
  factory ViewQuery.removePadding({
    Key? key,
    required BuildContext context,
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
    required Widget child,
  }) {
    return ViewQuery(
      key: key,
      data: ViewQuery.of(context).removePadding(
        removeLeft: removeLeft,
        removeTop: removeTop,
        removeRight: removeRight,
        removeBottom: removeBottom,
      ),
      child: child,
    );
  }

  /// Creates a new [ViewQuery] that inherits from the ambient [ViewQuery]
  /// from the given context, but removes the specified view insets.
  ///
  /// This should be inserted into the widget tree when the [ViewQuery] view
  /// insets are consumed by a widget in such a way that the view insets are no
  /// longer exposed to the widget's descendants or siblings.
  ///
  /// The [context] argument is required, must not be null, and must have a
  /// [ViewQuery] in scope.
  ///
  /// The `removeLeft`, `removeTop`, `removeRight`, and `removeBottom` arguments
  /// must not be null. If all four are false (the default) then the returned
  /// [ViewQuery] reuses the ambient [ViewQueryData] unmodified, which is not
  /// particularly useful.
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// See also:
  ///
  ///  * [ViewQueryData.viewInsets], the affected property of the
  ///    [ViewQueryData].
  ///  * [removePadding], the same thing but for [ViewQueryData.padding].
  ///  * [removeViewPadding], the same thing but for
  ///    [ViewQueryData.viewPadding].
  factory ViewQuery.removeViewInsets({
    Key? key,
    required BuildContext context,
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
    required Widget child,
  }) {
    return ViewQuery(
      key: key,
      data: ViewQuery.of(context).removeViewInsets(
        removeLeft: removeLeft,
        removeTop: removeTop,
        removeRight: removeRight,
        removeBottom: removeBottom,
      ),
      child: child,
    );
  }

  /// Creates a new [ViewQuery] that inherits from the ambient [ViewQuery]
  /// from the given context, but removes the specified view padding.
  ///
  /// This should be inserted into the widget tree when the [ViewQuery] view
  /// padding is consumed by a widget in such a way that the view padding is no
  /// longer exposed to the widget's descendants or siblings.
  ///
  /// The [context] argument is required, must not be null, and must have a
  /// [ViewQuery] in scope.
  ///
  /// The `removeLeft`, `removeTop`, `removeRight`, and `removeBottom` arguments
  /// must not be null. If all four are false (the default) then the returned
  /// [ViewQuery] reuses the ambient [ViewQueryData] unmodified, which is not
  /// particularly useful.
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// See also:
  ///
  ///  * [ViewQueryData.viewPadding], the affected property of the
  ///    [ViewQueryData].
  ///  * [removePadding], the same thing but for [ViewQueryData.padding].
  ///  * [removeViewInsets], the same thing but for [ViewQueryData.viewInsets].
  factory ViewQuery.removeViewPadding({
    Key? key,
    required BuildContext context,
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
    required Widget child,
  }) {
    return ViewQuery(
      key: key,
      data: ViewQuery.of(context).removeViewPadding(
        removeLeft: removeLeft,
        removeTop: removeTop,
        removeRight: removeRight,
        removeBottom: removeBottom,
      ),
      child: child,
    );
  }

  /// Provides a [ViewQuery] which is built and updated using the provided
  /// [FlutterView].
  ///
  /// The [ViewQuery] is wrapped in a separate widget to ensure that only it
  /// and its dependents are updated when [view] changes, instead of
  /// rebuilding the whole widget tree.
  ///
  /// The [child] and [view] argument is required and must not be null.
  static Widget fromView({
    Key? key,
    required FlutterView view,
    required Widget child,
  }) {
    return _ViewQueryFromView(
      key: key,
      view: view,
      child: child,
    );
  }

  /// Contains information about the current media.
  ///
  /// For example, the [ViewQueryData.size] property contains the width and
  /// height of the current window.
  final ViewQueryData data;

  /// The data from the closest instance of this class that encloses the given
  /// context.
  ///
  /// You can use this function to query the size and orientation of the screen,
  /// as well as other media parameters (see [ViewQueryData] for more
  /// examples). When that information changes, your widget will be scheduled to
  /// be rebuilt, keeping your widget up-to-date.
  ///
  /// If the widget only requires a subset of properties of the [ViewQueryData]
  /// object, it is preferred to use the specific methods (for example:
  /// [ViewQuery.sizeOf] and [ViewQuery.paddingOf]), as those methods will not
  /// cause a widget to rebuild when unrelated properties are updated.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ViewQueryData media = ViewQuery.of(context);
  /// ```
  ///
  /// If there is no [ViewQuery] in scope, this will throw a [TypeError]
  /// exception in release builds, and throw a descriptive [FlutterError] in
  /// debug builds.
  ///
  /// See also:
  ///
  ///  * [maybeOf], which doesn't throw or assert if it doesn't find a
  ///    [ViewQuery] ancestor, it returns null instead.
  static ViewQueryData of(BuildContext context) {
    assert(context != null);
    return _of(context);
  }

  static ViewQueryData _of(BuildContext context, [_ViewQueryAspect? aspect]) {
    assert(debugCheckHasViewQuery(context));
    return InheritedModel.inheritFrom<ViewQuery>(context, aspect: aspect)!.data;
  }

  /// The data from the closest instance of this class that encloses the given
  /// context, if any.
  ///
  /// Use this function if you want to allow situations where no [ViewQuery] is
  /// in scope. Prefer using [ViewQuery.of] in situations where a media query
  /// is always expected to exist.
  ///
  /// If there is no [ViewQuery] in scope, then this function will return null.
  ///
  /// You can use this function to query the size and orientation of the screen,
  /// as well as other media parameters (see [ViewQueryData] for more
  /// examples). When that information changes, your widget will be scheduled to
  /// be rebuilt, keeping your widget up-to-date.
  ///
  /// If the widget only requires a subset of properties of the [ViewQueryData]
  /// object, it is preferred to use the specific methods (for example:
  /// [ViewQuery.maybeSizeOf] and [ViewQuery.maybePaddingOf]), as those methods
  /// will not cause a widget to rebuild when unrelated properties are updated.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ViewQueryData? ViewQuery = ViewQuery.maybeOf(context);
  /// if (ViewQuery == null) {
  ///   // Do something else instead.
  /// }
  /// ```
  ///
  /// See also:
  ///
  ///  * [of], which will throw if it doesn't find a [ViewQuery] ancestor,
  ///    instead of returning null.
  static ViewQueryData? maybeOf(BuildContext context) {
    assert(context != null);
    return _maybeOf(context);
  }

  static ViewQueryData? _maybeOf(BuildContext context, [_ViewQueryAspect? aspect]) {
    return InheritedModel.inheritFrom<ViewQuery>(context, aspect: aspect)?.data;
  }

  /// Returns size for the nearest ViewQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.size] property of the ancestor [ViewQuery] changes.
  static Size sizeOf(BuildContext context) => _of(context, _ViewQueryAspect.size).size;

  /// Returns size for the nearest ViewQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.size] property of the ancestor [ViewQuery] changes.
  static Size? maybeSizeOf(BuildContext context) => _maybeOf(context, _ViewQueryAspect.size)?.size;

  /// Returns orientation for the nearest ViewQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.orientation] property of the ancestor [ViewQuery] changes.
  static Orientation orientationOf(BuildContext context) => _of(context, _ViewQueryAspect.orientation).orientation;

  /// Returns orientation for the nearest ViewQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.orientation] property of the ancestor [ViewQuery] changes.
  static Orientation? maybeOrientationOf(BuildContext context) => _maybeOf(context, _ViewQueryAspect.orientation)?.orientation;

  /// Returns devicePixelRatio for the nearest ViewQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.devicePixelRatio] property of the ancestor [ViewQuery] changes.
  static double devicePixelRatioOf(BuildContext context) => _of(context, _ViewQueryAspect.devicePixelRatio).devicePixelRatio;

  /// Returns devicePixelRatio for the nearest ViewQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.devicePixelRatio] property of the ancestor [ViewQuery] changes.
  static double? maybeDevicePixelRatioOf(BuildContext context) => _maybeOf(context, _ViewQueryAspect.devicePixelRatio)?.devicePixelRatio;

  /// Returns padding for the nearest ViewQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.padding] property of the ancestor [ViewQuery] changes.
  static EdgeInsets paddingOf(BuildContext context) => _of(context, _ViewQueryAspect.padding).padding;

  /// Returns viewInsets for the nearest ViewQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.viewInsets] property of the ancestor [ViewQuery] changes.
  static EdgeInsets? maybePaddingOf(BuildContext context) => _maybeOf(context, _ViewQueryAspect.padding)?.padding;

  /// Returns viewInsets for the nearest ViewQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.viewInsets] property of the ancestor [ViewQuery] changes.
  static EdgeInsets viewInsetsOf(BuildContext context) => _of(context, _ViewQueryAspect.viewInsets).viewInsets;

  /// Returns viewInsets for the nearest ViewQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.viewInsets] property of the ancestor [ViewQuery] changes.
  static EdgeInsets? maybeViewInsetsOf(BuildContext context) => _maybeOf(context, _ViewQueryAspect.viewInsets)?.viewInsets;

  /// Returns systemGestureInsets for the nearest ViewQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.systemGestureInsets] property of the ancestor [ViewQuery] changes.
  static EdgeInsets systemGestureInsetsOf(BuildContext context) => _of(context, _ViewQueryAspect.systemGestureInsets).systemGestureInsets;

  /// Returns systemGestureInsets for the nearest ViewQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.systemGestureInsets] property of the ancestor [ViewQuery] changes.
  static EdgeInsets? maybeSystemGestureInsetsOf(BuildContext context) => _maybeOf(context, _ViewQueryAspect.systemGestureInsets)?.systemGestureInsets;

  /// Returns viewPadding for the nearest ViewQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.viewPadding] property of the ancestor [ViewQuery] changes.
  static EdgeInsets viewPaddingOf(BuildContext context) => _of(context, _ViewQueryAspect.viewPadding).viewPadding;

  /// Returns viewPadding for the nearest ViewQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.viewPadding] property of the ancestor [ViewQuery] changes.
  static EdgeInsets? maybeViewPaddingOf(BuildContext context) => _maybeOf(context, _ViewQueryAspect.viewPadding)?.viewPadding;

  /// Returns gestureSettings for the nearest ViewQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.gestureSettings] property of the ancestor [ViewQuery] changes.
  static DeviceGestureSettings gestureSettingsOf(BuildContext context) => _of(context, _ViewQueryAspect.gestureSettings).gestureSettings;

  /// Returns gestureSettings for the nearest ViewQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.gestureSettings] property of the ancestor [ViewQuery] changes.
  static DeviceGestureSettings? maybeGestureSettingsOf(BuildContext context) => _maybeOf(context, _ViewQueryAspect.gestureSettings)?.gestureSettings;

  /// Returns displayFeatures for the nearest ViewQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.displayFeatures] property of the ancestor [ViewQuery] changes.
  static List<ui.DisplayFeature> displayFeaturesOf(BuildContext context) => _of(context, _ViewQueryAspect.displayFeatures).displayFeatures;

  /// Returns displayFeatures for the nearest ViewQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [ViewQueryData.displayFeatures] property of the ancestor [ViewQuery] changes.
  static List<ui.DisplayFeature>? maybeDisplayFeaturesOf(BuildContext context) => _maybeOf(context, _ViewQueryAspect.displayFeatures)?.displayFeatures;

  @override
  bool updateShouldNotify(ViewQuery oldWidget) => data != oldWidget.data;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ViewQueryData>('data', data, showName: false));
  }

  @override
  bool updateShouldNotifyDependent(ViewQuery oldWidget, Set<Object> dependencies) {
    return (data.size != oldWidget.data.size && dependencies.contains(_ViewQueryAspect.size))
        || (data.orientation != oldWidget.data.orientation && dependencies.contains(_ViewQueryAspect.orientation))
        || (data.devicePixelRatio != oldWidget.data.devicePixelRatio && dependencies.contains(_ViewQueryAspect.devicePixelRatio))
        || (data.viewInsets != oldWidget.data.viewInsets && dependencies.contains(_ViewQueryAspect.viewInsets))
        || (data.systemGestureInsets != oldWidget.data.systemGestureInsets && dependencies.contains(_ViewQueryAspect.systemGestureInsets))
        || (data.viewPadding != oldWidget.data.viewPadding && dependencies.contains(_ViewQueryAspect.viewPadding))
        || (data.gestureSettings != oldWidget.data.gestureSettings && dependencies.contains(_ViewQueryAspect.gestureSettings))
        || (data.displayFeatures != oldWidget.data.displayFeatures && dependencies.contains(_ViewQueryAspect.displayFeatures));
  }
}

class _ViewQueryFromView extends StatefulWidget {
  const _ViewQueryFromView({
    super.key,
    required this.view,
    required this.child,
  });

  final FlutterView view;
  final Widget child;

  @override
  State<_ViewQueryFromView> createState() => _ViewQueryFromViewState();
}

class _ViewQueryFromViewState extends State<_ViewQueryFromView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    setState(() {
      // The properties of view have changed. We use them in our build
      // function, so we need setState(), but we don't cache anything locally.
    });
  }

  @override
  Widget build(BuildContext context) {
    return ViewQuery(
      data: ViewQueryData.fromView(widget.view),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
