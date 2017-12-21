// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const double _kBackGestureWidth = 20.0;
const double _kMinFlingVelocity = 1.0; // Screen widths per second.

// Offset from offscreen to the right to fully on screen.
final Tween<Offset> _kRightMiddleTween = new Tween<Offset>(
  begin: const Offset(1.0, 0.0),
  end: Offset.zero,
);

// Offset from fully on screen to 1/3 offscreen to the left.
final Tween<Offset> _kMiddleLeftTween = new Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(-1.0/3.0, 0.0),
);

// Offset from offscreen below to fully on screen.
final Tween<Offset> _kBottomUpTween = new Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: Offset.zero,
);

// Custom decoration from no shadow to page shadow mimicking iOS page
// transitions using gradients.
final DecorationTween _kGradientShadowTween = new DecorationTween(
  begin: _CupertinoEdgeShadowDecoration.none, // No decoration initially.
  end: const _CupertinoEdgeShadowDecoration(
    edgeGradient: const LinearGradient(
      // Spans 5% of the page.
      begin: const AlignmentDirectional(0.90, 0.0),
      end: AlignmentDirectional.centerEnd,
      // Eyeballed gradient used to mimic a drop shadow on the start side only.
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
/// The page slides in from the right and exits in reverse. The page also shifts
/// to the left in parallax when another page enters to cover it.
///
/// The page slides in from the bottom and exits in reverse with no parallax
/// effect for fullscreen dialogs.
///
/// By default, when a modal route is replaced by another, the previous route
/// remains in memory. To free all the resources when this is not necessary, set
/// [maintainState] to false.
///
/// The type `T` specifies the return type of the route which can be supplied as
/// the route is popped from the stack via [Navigator.pop] when an optional
/// `result` can be provided.
///
/// See also:
///
///  * [MaterialPageRoute], for an adaptive [PageRoute] that uses a
///    platform-appropriate transition.
///  * [CupertinoPageScaffold], for applications that have one page with a fixed
///    navigation bar on top.
///  * [CupertinoTabScaffold], for applications that have a tab bar at the
///    bottom with multiple pages.
class CupertinoPageRoute<T> extends PageRoute<T> {
  /// Creates a page route for use in an iOS designed app.
  ///
  /// The [builder], [settings], [maintainState], and [fullscreenDialog]
  /// arguments must not be null.
  CupertinoPageRoute({
    @required this.builder,
    RouteSettings settings: const RouteSettings(),
    this.maintainState: true,
    bool fullscreenDialog: false,
    this.hostRoute,
  }) : assert(builder != null),
       assert(settings != null),
       assert(maintainState != null),
       assert(fullscreenDialog != null),
       super(settings: settings, fullscreenDialog: fullscreenDialog) {
    // ignore: prefer_asserts_in_initializer_lists , https://github.com/dart-lang/sdk/issues/31223
    assert(opaque); // PageRoute makes it return true.
  }

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  /// The route that owns this one.
  ///
  /// The [MaterialPageRoute] creates a [CupertinoPageRoute] to handle iOS-style
  /// navigation. When this happens, the [MaterialPageRoute] is the [hostRoute]
  /// of this [CupertinoPageRoute].
  ///
  /// The [hostRoute] is responsible for calling [dispose] on the route. When
  /// there is a [hostRoute], the [CupertinoPageRoute] must not be [install]ed.
  final PageRoute<T> hostRoute;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is CupertinoPageRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return nextRoute is CupertinoPageRoute && !nextRoute.fullscreenDialog;
  }

  @override
  void install(OverlayEntry insertionPoint) {
    assert(() {
      if (hostRoute == null)
        return true;
      throw new FlutterError(
        'Cannot install a subsidiary route (one with a hostRoute).\n'
        'This route ($this) cannot be installed, because it has a host route ($hostRoute).'
      );
    }());
    super.install(insertionPoint);
  }

  @override
  void dispose() {
    _backGestureController?.dispose();
    _backGestureController = null;
    super.dispose();
  }

  _CupertinoBackGestureController _backGestureController;

  /// Whether a pop gesture is currently underway.
  ///
  /// This starts returning true when pop gesture is started by the user. It
  /// returns false if that has not yet occurred or if the most recent such
  /// gesture has completed.
  ///
  /// See also:
  ///
  ///  * [popGestureEnabled], which returns whether a pop gesture is appropriate
  ///    in the first place.
  bool get popGestureInProgress => _backGestureController != null;

  /// Whether a pop gesture can be started by the user.
  ///
  /// This returns true if the user can edge-swipe to a previous route,
  /// otherwise false.
  ///
  /// This will return false once [popGestureInProgress] is true, but
  /// [popGestureInProgress] can only become true if [popGestureEnabled] was
  /// true first.
  ///
  /// This should only be used between frames, not during build.
  bool get popGestureEnabled {
    final PageRoute<T> route = hostRoute ?? this;
    // If there's nothing to go back to, then obviously we don't support
    // the back gesture.
    if (route.isFirst)
      return false;
    // If the route wouldn't actually pop if we popped it, then the gesture
    // would be really confusing (or would skip internal routes), so disallow it.
    if (route.willHandlePopInternally)
      return false;
    // If attempts to dismiss this route might be vetoed such as in a page
    // with forms, then do not allow the user to dismiss the route with a swipe.
    if (route.hasScopedWillPopCallback)
      return false;
    // Fullscreen dialogs aren't dismissable by back swipe.
    if (fullscreenDialog)
      return false;
    // If we're in an animation already, we cannot be manually swiped.
    if (route.controller.status != AnimationStatus.completed)
      return false;
    // If we're in a gesture already, we cannot start another.
    if (popGestureInProgress)
      return false;
    // Looks like a back gesture would be welcome!
    return true;
  }

  /// Begin dismissing this route from a horizontal swipe, if appropriate.
  ///
  /// Swiping will be disabled if the page is a fullscreen dialog or if
  /// dismissals can be overridden because a [WillPopCallback] was
  /// defined for the route.
  ///
  /// When this method decides a pop gesture is appropriate, it returns a
  /// [CupertinoBackGestureController].
  ///
  /// See also:
  ///
  ///  * [hasScopedWillPopCallback], which is true if a `willPop` callback
  ///    is defined for this route.
  ///  * [popGestureEnabled], which returns whether a pop gesture is
  ///    appropriate.
  ///  * [Route.startPopGesture], which describes the contract that this method
  ///    must implement.
  _CupertinoBackGestureController _startPopGesture() {
    assert(!popGestureInProgress);
    assert(popGestureEnabled);
    final PageRoute<T> route = hostRoute ?? this;
    _backGestureController = new _CupertinoBackGestureController(
      navigator: route.navigator,
      controller: route.controller,
      onEnded: _endPopGesture,
    );
    return _backGestureController;
  }

  void _endPopGesture() {
    // In practice this only gets called if for some reason popping the route
    // did not cause this route to get disposed.
    _backGestureController?.dispose();
    _backGestureController = null;
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
    }());
    return result;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (fullscreenDialog) {
      return new CupertinoFullscreenDialogTransition(
        animation: animation,
        child: child,
      );
    } else {
      return new CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        // In the middle of a back gesture drag, let the transition be linear to
        // match finger motions.
        linearTransition: popGestureInProgress,
        child: new _CupertinoBackGestureDetector(
          enabledCallback: () => popGestureEnabled,
          onStartPopGesture: _startPopGesture,
          child: child,
        ),
      );
    }
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
    @required bool linearTransition,
  }) : assert(linearTransition != null),
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
  final Animation<Offset> _primaryPositionAnimation;
  // When this page is becoming covered by another page.
  final Animation<Offset> _secondaryPositionAnimation;
  final Animation<Decoration> _primaryShadowAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final TextDirection textDirection = Directionality.of(context);
    // TODO(ianh): tell the transform to be un-transformed for hit testing
    // but not while being controlled by a gesture.
    return new SlideTransition(
      position: _secondaryPositionAnimation,
      textDirection: textDirection,
      child: new SlideTransition(
        position: _primaryPositionAnimation,
        textDirection: textDirection,
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

  final Animation<Offset> _positionAnimation;

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

/// This is the widget side of [_CupertinoBackGestureController].
///
/// This widget provides a gesture recognizer which, when it determines the
/// route can be closed with a back gesture, creates the controller and
/// feeds it the input from the gesture recognizer.
///
/// The gesture data is converted from absolute coordinates to logical
/// coordinates by this widget.
class _CupertinoBackGestureDetector extends StatefulWidget {
  const _CupertinoBackGestureDetector({
    Key key,
    @required this.enabledCallback,
    @required this.onStartPopGesture,
    @required this.child,
  }) : assert(enabledCallback != null),
       assert(onStartPopGesture != null),
       assert(child != null),
       super(key: key);

  final Widget child;

  final ValueGetter<bool> enabledCallback;

  final ValueGetter<_CupertinoBackGestureController> onStartPopGesture;

  @override
  _CupertinoBackGestureDetectorState createState() => new _CupertinoBackGestureDetectorState();
}

class _CupertinoBackGestureDetectorState extends State<_CupertinoBackGestureDetector> {
  _CupertinoBackGestureController _backGestureController;

  HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = new HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController.dragUpdate(_convertToLogical(details.primaryDelta / context.size.width));
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController.dragEnd(_convertToLogical(details.velocity.pixelsPerSecond.dx / context.size.width));
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    // This can be called even if start is not called, paired with the "down" event
    // that we don't consider here.
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback())
      _recognizer.addPointer(event);
  }

  double _convertToLogical(double value) {
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return -value;
      case TextDirection.ltr:
        return value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return new Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        new PositionedDirectional(
          start: 0.0,
          width: _kBackGestureWidth,
          top: 0.0,
          bottom: 0.0,
          child: new Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}


/// A controller for an iOS-style back gesture.
///
/// This is created by a [CupertinoPageRoute] in response from a gesture caught
/// by a [_CupertinoBackGestureDetector] widget, which then also feeds it input
/// from the gesture. It controls the animation controller owned by the route,
/// based on the input provided by the gesture detector.
///
/// This class works entirely in logical coordinates (0.0 is new page dismissed,
/// 1.0 is new page on top).
class _CupertinoBackGestureController {
  /// Creates a controller for an iOS-style back gesture.
  ///
  /// The [navigator] and [controller] arguments must not be null.
  _CupertinoBackGestureController({
    @required this.navigator,
    @required this.controller,
    @required this.onEnded,
  }) : assert(navigator != null),
       assert(controller != null),
       assert(onEnded != null) {
    navigator.didStartUserGesture();
  }

  /// The navigator that this object is controlling.
  final NavigatorState navigator;

  /// The animation controller that the route uses to drive its transition
  /// animation.
  final AnimationController controller;

  final VoidCallback onEnded;

  bool _animating = false;

  /// The drag gesture has changed by [fractionalDelta]. The total range of the
  /// drag should be 0.0 to 1.0.
  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  /// The drag gesture has ended with a horizontal motion of
  /// [fractionalVelocity] as a fraction of screen width per second.
  void dragEnd(double velocity) {
    // Fling in the appropriate direction.
    // AnimationController.fling is guaranteed to
    // take at least one frame.
    if (velocity.abs() >= _kMinFlingVelocity) {
      controller.fling(velocity: -velocity);
    } else if (controller.value <= 0.5) {
      controller.fling(velocity: -1.0);
    } else {
      controller.fling(velocity: 1.0);
    }
    assert(controller.isAnimating);
    assert(controller.status != AnimationStatus.completed);
    assert(controller.status != AnimationStatus.dismissed);

    // Don't end the gesture until the transition completes.
    _animating = true;
    controller.addStatusListener(_handleStatusChanged);
  }

  void _handleStatusChanged(AnimationStatus status) {
    assert(_animating);
    controller.removeStatusListener(_handleStatusChanged);
    _animating = false;
    if (status == AnimationStatus.dismissed)
      navigator.pop(); // this will cause the route to get disposed, which will dispose us
    onEnded(); // this will call dispose if popping the route failed to do so
  }

  void dispose() {
    if (_animating)
      controller.removeStatusListener(_handleStatusChanged);
    navigator.didStopUserGesture();
  }
}

// A custom [Decoration] used to paint an extra shadow on the start edge of the
// box it's decorating. It's like a [BoxDecoration] with only a gradient except
// it paints on the start side of the box instead of behind the box.
//
// The [edgeGradient] will be given a [TextDirection] when its shader is
// created, and so can be direction-sensitive; in this file we set it to a
// gradient that uses an AlignmentDirectional to position the gradient on the
// end edge of the gradient's box (which will be the edge adjacent to the start
// edge of the actual box we're supposed to paint in).
class _CupertinoEdgeShadowDecoration extends Decoration {
  const _CupertinoEdgeShadowDecoration({ this.edgeGradient });

  // An edge shadow decoration where the shadow is null. This is used
  // for interpolating from no shadow.
  static const _CupertinoEdgeShadowDecoration none =
      const _CupertinoEdgeShadowDecoration();

  // A gradient to draw to the left of the box being decorated.
  // Alignments are relative to the original box translated one box
  // width to the left.
  final LinearGradient edgeGradient;

  // Linearly interpolate between two edge shadow decorations decorations.
  //
  // The `t` argument represents position on the timeline, with 0.0 meaning
  // that the interpolation has not started, returning `a` (or something
  // equivalent to `a`), 1.0 meaning that the interpolation has finished,
  // returning `b` (or something equivalent to `b`), and values in between
  // meaning that the interpolation is at the relevant point on the timeline
  // between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  // 1.0, so negative values and values greater than 1.0 are valid (and can
  // easily be generated by curves such as [Curves.elasticInOut]).
  //
  // Values for `t` are usually obtained from an [Animation<double>], such as
  // an [AnimationController].
  //
  // See also:
  //
  //  * [Decoration.lerp].
  static _CupertinoEdgeShadowDecoration lerp(
    _CupertinoEdgeShadowDecoration a,
    _CupertinoEdgeShadowDecoration b,
    double t,
  ) {
    assert(t != null);
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
    if (runtimeType != other.runtimeType)
      return false;
    final _CupertinoEdgeShadowDecoration typedOther = other;
    return edgeGradient == typedOther.edgeGradient;
  }

  @override
  int get hashCode => edgeGradient.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new DiagnosticsProperty<LinearGradient>('edgeGradient', edgeGradient));
  }
}

/// A [BoxPainter] used to draw the page transition shadow using gradients.
class _CupertinoEdgeShadowPainter extends BoxPainter {
  _CupertinoEdgeShadowPainter(
    this._decoration,
    VoidCallback onChange,
  ) : assert(_decoration != null),
      super(onChange);

  final _CupertinoEdgeShadowDecoration _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final LinearGradient gradient = _decoration.edgeGradient;
    if (gradient == null)
      return;
    // The drawable space for the gradient is a rect with the same size as
    // its parent box one box width on the start side of the box.
    final TextDirection textDirection = configuration.textDirection;
    assert(textDirection != null);
    double deltaX;
    switch (textDirection) {
      case TextDirection.rtl:
        deltaX = configuration.size.width;
        break;
      case TextDirection.ltr:
        deltaX = -configuration.size.width;
        break;
    }
    final Rect rect = (offset & configuration.size).translate(deltaX, 0.0);
    final Paint paint = new Paint()
      ..shader = gradient.createShader(rect, textDirection: textDirection);

    canvas.drawRect(rect, paint);
  }
}
