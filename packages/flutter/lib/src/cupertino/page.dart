// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const double _kMinFlingVelocity = 1.0;  // screen width per second.

// Fractional offset from offscreen to the right to fully on screen.
final FractionalOffsetTween _kRightMiddleTween = new FractionalOffsetTween(
  begin: FractionalOffset.topRight,
  end: FractionalOffset.topLeft,
);

// Fractional offset from fully on screen to 1/3 offscreen to the left.
final FractionalOffsetTween _kMiddleLeftTween = new FractionalOffsetTween(
  begin: FractionalOffset.topLeft,
  end: const FractionalOffset(-1.0/3.0, 0.0),
);

// Fractional offset from offscreen below to fully on screen.
final FractionalOffsetTween _kBottomUpTween = new FractionalOffsetTween(
  begin: FractionalOffset.bottomLeft,
  end: FractionalOffset.topLeft,
);

// Custom decoration from no shadow to page shadow mimicking iOS page
// transitions using gradients.
final DecorationTween _kGradientShadowTween = new DecorationTween(
  begin: _CupertinoEdgeShadowDecoration.none, // No decoration initially.
  end: const _CupertinoEdgeShadowDecoration(
    edgeGradient: const LinearGradient(
      // Spans 5% of the page.
      begin: const FractionalOffset(0.95, 0.0),
      end: FractionalOffset.topRight,
      // Eyeballed gradient used to mimic a drop shadow on the left side only.
      colors: const <Color>[
        const Color(0x00000000),
        const Color(0x04000000),
        const Color(0x12000000),
        const Color(0x38000000)
      ],
      stops: const <double>[0.0, 0.3, 0.6, 1.0],
    ),
  ),
);

/// A modal route that replaces the entire screen with an iOS transition.
///
/// The page slides in from the right and exits in reverse.
/// The page also shifts to the left in parallax when another page enters to cover it.
///
/// The page slides in from the bottom and exits in reverse with no parallax effect
/// for fullscreen dialogs.
///
/// By default, when a modal route is replaced by another, the previous route
/// remains in memory. To free all the resources when this is not necessary, set
/// [maintainState] to false.
///
/// See also:
///
///  * [MaterialPageRoute] for an adaptive [PageRoute] that uses a platform appropriate transition.
class CupertinoPageRoute<T> extends PageRoute<T> {
  /// Creates a page route for use in an iOS designed app.
  CupertinoPageRoute({
    @required this.builder,
    RouteSettings settings: const RouteSettings(),
    this.maintainState: true,
    bool fullscreenDialog: false,
  }) : assert(builder != null),
       assert(opaque),
       super(settings: settings, fullscreenDialog: fullscreenDialog);

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Color get barrierColor => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is CupertinoPageRoute<dynamic>;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return nextRoute is CupertinoPageRoute && !nextRoute.fullscreenDialog;
  }

  @override
  void dispose() {
    _backGestureController?.dispose();
    // If the route is never installed (i.e. pushed into a Navigator) such as the
    // case when [MaterialPageRoute] delegates transition building to [CupertinoPageRoute],
    // don't dispose super.
    if (overlayEntries.isNotEmpty)
      super.dispose();
  }

  CupertinoBackGestureController _backGestureController;

  /// Support for dismissing this route with a horizontal swipe.
  ///
  /// Swiping will be disabled if the page is a fullscreen dialog or if
  /// dismissals can be overriden because a [WillPopCallback] was
  /// defined for the route.
  ///
  /// See also:
  ///
  ///  * [hasScopedWillPopCallback], which is true if a `willPop` callback
  ///    is defined for this route.
  @override
  NavigationGestureController startPopGesture() {
    return startPopGestureForRoute(this);
  }

  /// Create a CupertinoBackGestureController using a specific PageRoute.
  ///
  /// Used when [MaterialPageRoute] delegates the back gesture to [CupertinoPageRoute]
  /// since the [CupertinoPageRoute] is not actually inserted into the Navigator.
  NavigationGestureController startPopGestureForRoute(PageRoute<T> hostRoute) {
    // If attempts to dismiss this route might be vetoed such as in a page
    // with forms, then do not allow the user to dismiss the route with a swipe.
    if (hostRoute.hasScopedWillPopCallback)
      return null;
    // Fullscreen dialogs aren't dismissable by back swipe.
    if (fullscreenDialog)
      return null;
    if (hostRoute.controller.status != AnimationStatus.completed)
      return null;
    assert(_backGestureController == null);
    _backGestureController = new CupertinoBackGestureController(
      navigator: hostRoute.navigator,
      controller: hostRoute.controller,
    );

    Function handleBackGestureEnded;
    handleBackGestureEnded = (AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _backGestureController?.dispose();
        _backGestureController = null;
        hostRoute.controller.removeStatusListener(handleBackGestureEnded);
      }
    };

    hostRoute.controller.addStatusListener(handleBackGestureEnded);
    return _backGestureController;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget result = builder(context);
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
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (fullscreenDialog)
      return new CupertinoFullscreenDialogTransition(
        animation: animation,
        child: child,
      );
    else
      return new CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        child: child,
        // In the middle of a back gesture drag, let the transition be linear to match finger
        // motions.
        linearTransition: _backGestureController != null,
      );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

/// Provides an iOS-style page transition animation.
///
/// The page slides in from the right and exits in reverse. It also shifts to the left in
/// a parallax motion when another page enters to cover it.
class CupertinoPageTransition extends StatelessWidget {
  /// Creates an iOS-style page transition.
  ///
  ///  * `primaryRouteAnimation` is a linear route animation from 0.0 to 1.0
  ///    when this screen is being pushed.
  ///  * `secondaryRouteAnimation` is a linear route animation from 0.0 to 1.0
  ///    when another screen is being pushed on top of this one.
  ///  * `linearTransition` is whether to perform primary transition linearly.
  ///    Used to precisely track back gesture drags.
  CupertinoPageTransition({
    Key key,
    @required Animation<double> primaryRouteAnimation,
    @required Animation<double> secondaryRouteAnimation,
    @required this.child,
    bool linearTransition,
  }) :
      _primaryPositionAnimation = linearTransition
        ? _kRightMiddleTween.animate(primaryRouteAnimation)
        : _kRightMiddleTween.animate(
            new CurvedAnimation(
              parent: primaryRouteAnimation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            )
          ),
      _secondaryPositionAnimation = _kMiddleLeftTween.animate(
        new CurvedAnimation(
          parent: secondaryRouteAnimation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        )
      ),
      _primaryShadowAnimation = _kGradientShadowTween.animate(
        new CurvedAnimation(
          parent: primaryRouteAnimation,
          curve: Curves.easeOut,
        )
      ),
      super(key: key);

  // When this page is coming in to cover another page.
  final Animation<FractionalOffset> _primaryPositionAnimation;
  // When this page is becoming covered by another page.
  final Animation<FractionalOffset> _secondaryPositionAnimation;
  final Animation<Decoration> _primaryShadowAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(ianh): tell the transform to be un-transformed for hit testing
    // but not while being controlled by a gesture.
    return new SlideTransition(
      position: _secondaryPositionAnimation,
      child: new SlideTransition(
        position: _primaryPositionAnimation,
        child: new DecoratedBoxTransition(
          decoration: _primaryShadowAnimation,
          child: child,
        ),
      ),
    );
  }
}

/// An iOS-style transition used for summoning fullscreen dialogs.
///
/// For example, used when creating a new calendar event by bringing in the next
/// screen from the bottom.
class CupertinoFullscreenDialogTransition extends StatelessWidget {
  /// Creates an iOS-style transition used for summoning fullscreen dialogs.
  CupertinoFullscreenDialogTransition({
    Key key,
    @required Animation<double> animation,
    @required this.child,
  }) : _positionAnimation = _kBottomUpTween.animate(
         new CurvedAnimation(
           parent: animation,
           curve: Curves.easeInOut,
         )
       ),
       super(key: key);

  final Animation<FractionalOffset> _positionAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new SlideTransition(
      position: _positionAnimation,
      child: child,
    );
  }
}

/// A controller for an iOS-style back gesture.
///
/// Uses a drag gesture to control the route's transition animation progress.
class CupertinoBackGestureController extends NavigationGestureController {
  /// Creates a controller for an iOS-style back gesture.
  ///
  /// The [navigator] and [controller] arguments must not be null.
  CupertinoBackGestureController({
    @required NavigatorState navigator,
    @required this.controller,
  }) : assert(controller != null),
       super(navigator);

  /// The animation controller that the route uses to drive its transition
  /// animation.
  final AnimationController controller;

  @override
  void dispose() {
    controller.removeStatusListener(_handleStatusChanged);
    super.dispose();
  }

  @override
  void dragUpdate(double delta) {
    // This assert can be triggered the Scaffold is reparented out of the route
    // associated with this gesture controller and continues to feed it events.
    // TODO(abarth): Change the ownership of the gesture controller so that the
    // object feeding it these events (e.g., the Scaffold) is responsible for
    // calling dispose on it as well.
    assert(controller != null);
    controller.value -= delta;
  }

  @override
  bool dragEnd(double velocity) {
    // This assert can be triggered the Scaffold is reparented out of the route
    // associated with this gesture controller and continues to feed it events.
    // TODO(abarth): Change the ownership of the gesture controller so that the
    // object feeding it these events (e.g., the Scaffold) is responsible for
    // calling dispose on it as well.
    assert(controller != null);

    if (velocity.abs() >= _kMinFlingVelocity) {
      controller.fling(velocity: -velocity);
    } else if (controller.value <= 0.5) {
      controller.fling(velocity: -1.0);
    } else {
      controller.fling(velocity: 1.0);
    }

    // Don't end the gesture until the transition completes.
    final AnimationStatus status = controller.status;
    _handleStatusChanged(status);
    controller?.addStatusListener(_handleStatusChanged);

    return (status == AnimationStatus.reverse || status == AnimationStatus.dismissed);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed)
      navigator.pop();
  }
}

/// A custom [Decoration] used to paint an extra shadow on the left edge of the
/// box it's decorating. It's like a [BoxDecoration] with only a gradient except
/// it paints to the left of the box instead of behind the box.
class _CupertinoEdgeShadowDecoration extends Decoration {
  const _CupertinoEdgeShadowDecoration({ this.edgeGradient });

  /// A Decoration with no decorating properties.
  static const _CupertinoEdgeShadowDecoration none =
      const _CupertinoEdgeShadowDecoration();

  /// A gradient to draw to the left of the box being decorated.
  /// FractionalOffsets are relative to the original box translated one box
  /// width to the left.
  final LinearGradient edgeGradient;

  /// Linearly interpolate between two edge shadow decorations decorations.
  ///
  /// See also [Decoration.lerp].
  static _CupertinoEdgeShadowDecoration lerp(
    _CupertinoEdgeShadowDecoration a,
    _CupertinoEdgeShadowDecoration b,
    double t
  ) {
    if (a == null && b == null)
      return null;
    return new _CupertinoEdgeShadowDecoration(
      edgeGradient: LinearGradient.lerp(a?.edgeGradient, b?.edgeGradient, t),
    );
  }

  @override
  _CupertinoEdgeShadowDecoration lerpFrom(Decoration a, double t) {
    if (a is! _CupertinoEdgeShadowDecoration)
      return _CupertinoEdgeShadowDecoration.lerp(null, this, t);
    return _CupertinoEdgeShadowDecoration.lerp(a, this, t);
  }

  @override
  _CupertinoEdgeShadowDecoration lerpTo(Decoration b, double t) {
    if (b is! _CupertinoEdgeShadowDecoration)
      return _CupertinoEdgeShadowDecoration.lerp(this, null, t);
    return _CupertinoEdgeShadowDecoration.lerp(this, b, t);
  }

  @override
  _CupertinoEdgeShadowPainter createBoxPainter([VoidCallback onChanged]) {
    return new _CupertinoEdgeShadowPainter(this, onChanged);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != _CupertinoEdgeShadowDecoration)
      return false;
    final _CupertinoEdgeShadowDecoration typedOther = other;
    return edgeGradient == typedOther.edgeGradient;
  }

  @override
  int get hashCode {
    return edgeGradient.hashCode;
  }
}

/// A [BoxPainter] used to draw the page transition shadow using gradients.
class _CupertinoEdgeShadowPainter extends BoxPainter {
  _CupertinoEdgeShadowPainter(
    this._decoration,
    VoidCallback onChange
  ) : assert(_decoration != null),
      super(onChange);

  final _CupertinoEdgeShadowDecoration _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final LinearGradient gradient = _decoration.edgeGradient;
    if (gradient == null)
      return;
    // The drawable space for the gradient is a rect with the same size as
    // its parent box one box width to the left of the box.
    final Rect rect =
        (offset & configuration.size).translate(-configuration.size.width, 0.0);
    final Paint paint = new Paint()
      ..shader = gradient.createShader(rect);

    canvas.drawRect(rect, paint);
  }
}
