// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;
import 'dart:async';

import 'package:flutter/widgets.dart';

import 'shadows.dart';

/// Base class for modal routes in material design applications.
///
/// See also:
///
///  * [MaterialPageRoute], which does a vertical fade and slide transition
///  * [IrisWipeMaterialPageRoute], which does a circle clip transition
class MaterialPageRouteBase<T> extends PageRoute<T> {
  /// Creates a material page route.
  ///
  /// The [builder] must be non-null and must return a non-null value.
  MaterialPageRouteBase({
    this.builder,
    Completer<T> completer,
    RouteSettings settings: const RouteSettings()
  }) : super(completer: completer, settings: settings) {
    assert(builder != null);
    assert(opaque);
  }

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Color get barrierColor => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) => false;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
    Widget result = builder(context);
    assert(() {
      if (result == null) {
        throw new FlutterError(
          'The builder for route "${settings.name}" returned null.\n'
          'Route builders must never return null.'
        );
      }
      return true;
    });
    return result;
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}


class _FadeWipePageTransition extends AnimatedWidget {
  _FadeWipePageTransition({
    Key key,
    Animation<double> animation,
    this.child
  }) : super(
    key: key,
    animation: new CurvedAnimation(parent: animation, curve: Curves.easeOut)
  );

  final Widget child;

  final Tween<Point> _position = new Tween<Point>(
    begin: const Point(0.0, 75.0),
    end: Point.origin
  );

  @override
  Widget build(BuildContext context) {
    Point position = _position.evaluate(animation);
    Matrix4 transform = new Matrix4.identity()
      ..translate(position.x, position.y);
    return new Transform(
      transform: transform,
      // TODO(ianh): tell the transform to be un-transformed for hit testing
      child: new Opacity(
        opacity: animation.value,
        child: child
      )
    );
  }
}

/// Modal route that replaces the entire screen using a fade and vertical
/// slide transition.
///
/// The entrance transition for the page slides the page upwards as it fades in.
/// The exit transition is the same, but in reverse.
///
/// [MaterialApp] creates material page routes for entries in the
/// [MaterialApp.routes] map.
///
/// See also:
///
///  * [IrisWipeMaterialPageRoute], which does a circle clip transition
class MaterialPageRoute<T> extends MaterialPageRouteBase<T> {
  /// Creates a page route that uses a fade and vertical slide transition.
  MaterialPageRoute({
    WidgetBuilder builder,
    Completer<T> completer,
    RouteSettings settings: const RouteSettings()
  }) : super(builder: builder, completer: completer, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation, Widget child) {
    return new _FadeWipePageTransition(
      animation: animation,
      child: child
    );
  }
}


class _IrisWipePageTransition extends AnimatedWidget {
  // This is conceptually very similar to IrisWipeTransition, but instead
  // of just doing an iris wipe, it also has a shadow.
  _IrisWipePageTransition({
    Key key,
    Animation<double> animation,
    this.childKey,
    this.center: FractionalOffset.center,
    this.elevation: 0,
    this.child
  }) : super(key: key, animation: animation);

  @override
  Animation<double> get animation => super.animation;

  final GlobalKey childKey;
  final FractionalOffset center;
  final int elevation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget result = new RepaintBoundary(key: childKey, child: child);
    if (animation.status == AnimationStatus.completed)
      return result;
    result = new ClipOval(
      clipper: new _IrisWipePageTransitionClipperDelegate(
        center: center,
        position: animation.value
      ),
      child: result
    );
    if (elevation > 0) {
      result = new CustomPaint(
        painter: new _IrisWipePageTransitionShadowDelegate(
          center: center,
          elevation: elevation,
          position: animation.value
        ),
        child: result
      );
    }
    return result;
  }
}

Rect _computeIrisCircleBounds(Size bounds, FractionalOffset fractionalCenter, double position) {
  final Offset center = fractionalCenter.alongSize(bounds);
  final double radius = fractionalCenter.distanceToFurthestCorner(bounds);
  return new Rect.fromCircle(
    center: center.toPoint(),
    radius: ui.lerpDouble(0.0, radius, position)
  );
}

class _IrisWipePageTransitionShadowDelegate extends CustomPainter {
  _IrisWipePageTransitionShadowDelegate({
    this.center,
    int elevation: 0,
    this.position
  }) : elevation = elevation,
       decoration = new BoxDecoration(
         boxShadow: elevation > 0 ? kElevationToShadow[elevation] : null,
         shape: BoxShape.circle
       );

  final FractionalOffset center;
  final int elevation;
  final double position;
  final Decoration decoration;

  BoxPainter _painter;

  @override
  void paint(Canvas canvas, Size size) {
    _painter ??= decoration.createBoxPainter();
    _painter.paint(canvas, _computeIrisCircleBounds(size, center, position));
  }

  @override
  bool shouldRepaint(_IrisWipePageTransitionShadowDelegate oldDelegate) {
    return oldDelegate.center != center
        || oldDelegate.elevation != elevation
        || oldDelegate.position != position;
  }
}

class _IrisWipePageTransitionClipperDelegate extends CustomClipper<Rect> {
  _IrisWipePageTransitionClipperDelegate({
    this.center,
    this.position
  });

  final FractionalOffset center;
  final double position;

  @override
  Rect getClip(Size size) {
    return _computeIrisCircleBounds(size, center, position);
  }

  @override
  bool shouldRepaint(_IrisWipePageTransitionClipperDelegate oldDelegate) {
    return oldDelegate.center != center
        || oldDelegate.position != position;
  }
}

/// Modal route that replaces the entire screen using an iris wipe transition.
///
/// The entrance transition for the page reveals the new page by growing a
/// circle clip until the whole page is visible. The exit transition is the
/// reverse.
///
/// The [center] of the transition can be specified using a [FractionalOffset], 
/// as can the precise [elevation] of the transition.
///
/// See also:
///
///  * [MaterialPageRoute], which does a fade-and-slide transition
///  * <https://www.google.com/design/spec/animation/meaningful-transitions.html#meaningful-transitions-visual-continuity>
class IrisWipeMaterialPageRoute<T> extends MaterialPageRouteBase<T> {
  /// Creates a material page route that uses an iris wipe transition.
  ///
  /// The [builder] must be non-null and must return a non-null value.
  IrisWipeMaterialPageRoute({
    WidgetBuilder builder,
    this.center: FractionalOffset.center,
    this.elevation: 0, // TODO(ianh): should be something like 4 once https://bugs.chromium.org/p/skia/issues/detail?id=5224 is fixed
    Completer<T> completer,
    RouteSettings settings: const RouteSettings()
  }) : super(builder: builder, completer: completer, settings: settings);

  /// Center of the iris wipe transition, relative to the [Navigator]'s
  /// boundaries.
  final FractionalOffset center;

  /// Shadow to apply to the circle wipe effect.
  final int elevation;

  final GlobalKey _childKey = new GlobalKey();

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation, Widget child) {
    return new _IrisWipePageTransition(
      animation: animation,
      childKey: _childKey,
      center: center,
      elevation: elevation,
      child: child
    );
  }
}
