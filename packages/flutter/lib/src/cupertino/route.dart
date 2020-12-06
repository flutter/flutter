// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble, ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/animation.dart' show Curves;

import 'colors.dart';
import 'interface_level.dart';
import 'localizations.dart';

const double _kBackGestureWidth = 20.0;
const double _kMinFlingVelocity = 1.0; // Screen widths per second.

// An eyeballed value for the maximum time it takes for a page to animate forward
// if the user releases a page mid swipe.
const int _kMaxDroppedSwipePageForwardAnimationTime = 800; // Milliseconds.

// The maximum time for a page to get reset to it's original position if the
// user releases a page mid swipe.
const int _kMaxPageBackAnimationTime = 300; // Milliseconds.

// Barrier color for a Cupertino modal barrier.
// Extracted from https://developer.apple.com/design/resources/.
const Color _kModalBarrierColor = CupertinoDynamicColor.withBrightness(
  color: Color(0x33000000),
  darkColor: Color(0x7A000000),
);

// The duration of the transition used when a modal popup is shown.
const Duration _kModalPopupTransitionDuration = Duration(milliseconds: 335);

// Offset from offscreen to the right to fully on screen.
final Animatable<Offset> _kRightMiddleTween = Tween<Offset>(
  begin: const Offset(1.0, 0.0),
  end: Offset.zero,
);

// Offset from fully on screen to 1/3 offscreen to the left.
final Animatable<Offset> _kMiddleLeftTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(-1.0/3.0, 0.0),
);

// Offset from offscreen below to fully on screen.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: Offset.zero,
);

// Custom decoration from no shadow to page shadow mimicking iOS page
// transitions using gradients.
final DecorationTween _kGradientShadowTween = DecorationTween(
  begin: _CupertinoEdgeShadowDecoration.none, // No decoration initially.
  end: const _CupertinoEdgeShadowDecoration(
    edgeGradient: LinearGradient(
      // Spans 5% of the page.
      begin: AlignmentDirectional(0.90, 0.0),
      end: AlignmentDirectional.centerEnd,
      // Eyeballed gradient used to mimic a drop shadow on the start side only.
      colors: <Color>[
        Color(0x00000000),
        Color(0x04000000),
        Color(0x12000000),
        Color(0x38000000),
      ],
      stops: <double>[0.0, 0.3, 0.6, 1.0],
    ),
  ),
);

/// A mixin that replaces the entire screen with an iOS transition for a
/// [PageRoute].
///
/// {@template flutter.cupertino.cupertinoRouteTransitionMixin}
/// The page slides in from the right and exits in reverse. The page also shifts
/// to the left in parallax when another page enters to cover it.
///
/// The page slides in from the bottom and exits in reverse with no parallax
/// effect for fullscreen dialogs.
/// {@endtemplate}
///
/// See also:
///
///  * [MaterialRouteTransitionMixin], which is a mixin that provides
///    platform-appropriate transitions for a [PageRoute]
///  * [CupertinoPageRoute], which is a [PageRoute] that leverages this mixin.
mixin CupertinoRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  /// {@template flutter.cupertino.cupertinoRouteTransitionMixin.title}
  /// A title string for this route.
  ///
  /// Used to auto-populate [CupertinoNavigationBar] and
  /// [CupertinoSliverNavigationBar]'s `middle`/`largeTitle` widgets when
  /// one is not manually supplied.
  /// {@endtemplate}
  String get title;


  ValueNotifier<String> _previousTitle;

  /// The title string of the previous [CupertinoPageRoute].
  ///
  /// The [ValueListenable]'s value is readable after the route is installed
  /// onto a [Navigator]. The [ValueListenable] will also notify its listeners
  /// if the value changes (such as by replacing the previous route).
  ///
  /// The [ValueListenable] itself will be null before the route is installed.
  /// Its content value will be null if the previous route has no title or
  /// is not a [CupertinoPageRoute].
  ///
  /// See also:
  ///
  ///  * [ValueListenableBuilder], which can be used to listen and rebuild
  ///    widgets based on a ValueListenable.
  ValueListenable<String> get previousTitle {
    assert(
      _previousTitle != null,
      'Cannot read the previousTitle for a route that has not yet been installed',
    );
    return _previousTitle;
  }

  @override
  void didChangePrevious(Route<dynamic> previousRoute) {
    final String previousTitleString = previousRoute is CupertinoRouteTransitionMixin
      ? previousRoute.title
      : null;
    if (_previousTitle == null) {
      _previousTitle = ValueNotifier<String>(previousTitleString);
    } else {
      _previousTitle.value = previousTitleString;
    }
    super.didChangePrevious(previousRoute);
  }

  @override
  // A relatively rigorous eyeball estimation.
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return nextRoute is CupertinoRouteTransitionMixin && !nextRoute.fullscreenDialog;
  }

  /// True if an iOS-style back swipe pop gesture is currently underway for [route].
  ///
  /// This just check the route's [NavigatorState.userGestureInProgress].
  ///
  /// See also:
  ///
  ///  * [popGestureEnabled], which returns true if a user-triggered pop gesture
  ///    would be allowed.
  static bool isPopGestureInProgress(PageRoute<dynamic> route) {
    return route.navigator.userGestureInProgress;
  }

  /// True if an iOS-style back swipe pop gesture is currently underway for this route.
  ///
  /// See also:
  ///
  ///  * [isPopGestureInProgress], which returns true if a Cupertino pop gesture
  ///    is currently underway for specific route.
  ///  * [popGestureEnabled], which returns true if a user-triggered pop gesture
  ///    would be allowed.
  bool get popGestureInProgress => isPopGestureInProgress(this);

  /// Whether a pop gesture can be started by the user.
  ///
  /// Returns true if the user can edge-swipe to a previous route.
  ///
  /// Returns false once [isPopGestureInProgress] is true, but
  /// [isPopGestureInProgress] can only become true if [popGestureEnabled] was
  /// true first.
  ///
  /// This should only be used between frames, not during build.
  bool get popGestureEnabled => _isPopGestureEnabled(this);

  static bool _isPopGestureEnabled<T>(PageRoute<T> route) {
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
    // Fullscreen dialogs aren't dismissible by back swipe.
    if (route.fullscreenDialog)
      return false;
    // If we're in an animation already, we cannot be manually swiped.
    if (route.animation.status != AnimationStatus.completed)
      return false;
    // If we're being popped into, we also cannot be swiped until the pop above
    // it completes. This translates to our secondary animation being
    // dismissed.
    if (route.secondaryAnimation.status != AnimationStatus.dismissed)
      return false;
    // If we're in a gesture already, we cannot start another.
    if (isPopGestureInProgress(route))
      return false;

    // Looks like a back gesture would be welcome!
    return true;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget child = buildContent(context);
    final Widget result = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: child,
    );
    assert(() {
      if (child == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('The builder for route "${settings.name}" returned null.'),
          ErrorDescription('Route builders must never return null.'),
        ]);
      }
      return true;
    }());
    return result;
  }

  // Called by _CupertinoBackGestureDetector when a pop ("back") drag start
  // gesture is detected. The returned controller handles all of the subsequent
  // drag events.
  static _CupertinoBackGestureController<T> _startPopGesture<T>(PageRoute<T> route) {
    assert(_isPopGestureEnabled(route));

    return _CupertinoBackGestureController<T>(
      navigator: route.navigator,
      controller: route.controller, // protected access
    );
  }

  /// Returns a [CupertinoFullscreenDialogTransition] if [route] is a full
  /// screen dialog, otherwise a [CupertinoPageTransition] is returned.
  ///
  /// Used by [CupertinoPageRoute.buildTransitions].
  ///
  /// This method can be applied to any [PageRoute], not just
  /// [CupertinoPageRoute]. It's typically used to provide a Cupertino style
  /// horizontal transition for material widgets when the target platform
  /// is [TargetPlatform.iOS].
  ///
  /// See also:
  ///
  ///  * [CupertinoPageTransitionsBuilder], which uses this method to define a
  ///    [PageTransitionsBuilder] for the [PageTransitionsTheme].
  static Widget buildPageTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Check if the route has an animation that's currently participating
    // in a back swipe gesture.
    //
    // In the middle of a back gesture drag, let the transition be linear to
    // match finger motions.
    final bool linearTransition = isPopGestureInProgress(route);
    if (route.fullscreenDialog) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        child: child,
        linearTransition: linearTransition,
      );
    } else {
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: _CupertinoBackGestureDetector<T>(
          enabledCallback: () => _isPopGestureEnabled<T>(route),
          onStartPopGesture: () => _startPopGesture<T>(route),
          child: child,
        ),
      );
    }
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
}

/// A modal route that replaces the entire screen with an iOS transition.
///
/// {@macro flutter.cupertino.cupertinoRouteTransitionMixin}
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
///  * [CupertinoRouteTransitionMixin], for a mixin that provides iOS transition
///    for this modal route.
///  * [MaterialPageRoute], for an adaptive [PageRoute] that uses a
///    platform-appropriate transition.
///  * [CupertinoPageScaffold], for applications that have one page with a fixed
///    navigation bar on top.
///  * [CupertinoTabScaffold], for applications that have a tab bar at the
///    bottom with multiple pages.
///  * [CupertinoPage], for a [Page] version of this class.
class CupertinoPageRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin<T> {
  /// Creates a page route for use in an iOS designed app.
  ///
  /// The [builder], [maintainState], and [fullscreenDialog] arguments must not
  /// be null.
  CupertinoPageRoute({
    @required this.builder,
    this.title,
    RouteSettings settings,
    this.maintainState = true,
    bool fullscreenDialog = false,
  }) : assert(builder != null),
       assert(maintainState != null),
       assert(fullscreenDialog != null),
       assert(opaque),
       super(settings: settings, fullscreenDialog: fullscreenDialog);

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  final String title;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  final bool maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

// A page-based version of CupertinoPageRoute.
//
// This route uses the builder from the page to build its content. This ensures
// the content is up to date after page updates.
class _PageBasedCupertinoPageRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin<T> {
  _PageBasedCupertinoPageRoute({
    @required CupertinoPage<T> page,
  }) : assert(page != null),
       assert(opaque),
       super(settings: page);

  CupertinoPage<T> get _page => settings as CupertinoPage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  String get title => _page.title;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

/// A page that creates a cupertino style [PageRoute].
///
/// {@macro flutter.cupertino.cupertinoRouteTransitionMixin}
///
/// By default, when a created modal route is replaced by another, the previous
/// route remains in memory. To free all the resources when this is not
/// necessary, set [maintainState] to false.
///
/// The type `T` specifies the return type of the route which can be supplied as
/// the route is popped from the stack via [Navigator.transitionDelegate] by
/// providing the optional `result` argument to the
/// [RouteTransitionRecord.markForPop] in the [TransitionDelegate.resolve].
///
/// See also:
///
///  * [CupertinoPageRoute], for a [PageRoute] version of this class.
class CupertinoPage<T> extends Page<T> {
  /// Creates a cupertino page.
  const CupertinoPage({
    @required this.child,
    this.maintainState = true,
    this.title,
    this.fullscreenDialog = false,
    LocalKey key,
    String name,
    Object arguments,
  }) : assert(child != null),
       assert(maintainState != null),
       assert(fullscreenDialog != null),
       super(key: key, name: name, arguments: arguments);

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.cupertino.cupertinoRouteTransitionMixin.title}
  final String title;

  /// {@macro flutter.widgets.modalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.pageRoute.fullscreenDialog}
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedCupertinoPageRoute<T>(page: this);
  }
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
  ///  * `linearTransition` is whether to perform the transitions linearly.
  ///    Used to precisely track back gesture drags.
  CupertinoPageTransition({
    Key key,
    @required Animation<double> primaryRouteAnimation,
    @required Animation<double> secondaryRouteAnimation,
    @required this.child,
    @required bool linearTransition,
  }) : assert(linearTransition != null),
       _primaryPositionAnimation =
           (linearTransition
             ? primaryRouteAnimation
             : CurvedAnimation(
                 // The curves below have been rigorously derived from plots of native
                 // iOS animation frames. Specifically, a video was taken of a page
                 // transition animation and the distance in each frame that the page
                 // moved was measured. A best fit bezier curve was the fitted to the
                 // point set, which is linearToEaseIn. Conversely, easeInToLinear is the
                 // reflection over the origin of linearToEaseIn.
                 parent: primaryRouteAnimation,
                 curve: Curves.linearToEaseOut,
                 reverseCurve: Curves.easeInToLinear,
               )
           ).drive(_kRightMiddleTween),
       _secondaryPositionAnimation =
           (linearTransition
             ? secondaryRouteAnimation
             : CurvedAnimation(
                 parent: secondaryRouteAnimation,
                 curve: Curves.linearToEaseOut,
                 reverseCurve: Curves.easeInToLinear,
               )
           ).drive(_kMiddleLeftTween),
       _primaryShadowAnimation =
           (linearTransition
             ? primaryRouteAnimation
             : CurvedAnimation(
                 parent: primaryRouteAnimation,
                 curve: Curves.linearToEaseOut,
               )
           ).drive(_kGradientShadowTween),
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
    return SlideTransition(
      position: _secondaryPositionAnimation,
      textDirection: textDirection,
      transformHitTests: false,
      child: SlideTransition(
        position: _primaryPositionAnimation,
        textDirection: textDirection,
        child: DecoratedBoxTransition(
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
  ///
  ///  * `primaryRouteAnimation` is a linear route animation from 0.0 to 1.0
  ///    when this screen is being pushed.
  ///  * `secondaryRouteAnimation` is a linear route animation from 0.0 to 1.0
  ///    when another screen is being pushed on top of this one.
  ///  * `linearTransition` is whether to perform the secondary transition linearly.
  ///    Used to precisely track back gesture drags.
  CupertinoFullscreenDialogTransition({
    Key key,
    @required Animation<double> primaryRouteAnimation,
    @required Animation<double> secondaryRouteAnimation,
    @required this.child,
    @required bool linearTransition,
  }) : _positionAnimation = CurvedAnimation(
         parent: primaryRouteAnimation,
         curve: Curves.linearToEaseOut,
         // The curve must be flipped so that the reverse animation doesn't play
         // an ease-in curve, which iOS does not use.
         reverseCurve: Curves.linearToEaseOut.flipped,
       ).drive(_kBottomUpTween),
       _secondaryPositionAnimation =
           (linearTransition
             ? secondaryRouteAnimation
             : CurvedAnimation(
                 parent: secondaryRouteAnimation,
                 curve: Curves.linearToEaseOut,
                 reverseCurve: Curves.easeInToLinear,
               )
           ).drive(_kMiddleLeftTween),
       super(key: key);

  final Animation<Offset> _positionAnimation;
  // When this page is becoming covered by another page.
  final Animation<Offset> _secondaryPositionAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final TextDirection textDirection = Directionality.of(context);
    return SlideTransition(
      position: _secondaryPositionAnimation,
      textDirection: textDirection,
      transformHitTests: false,
      child: SlideTransition(
        position: _positionAnimation,
        child: child,
      ),
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
///
/// The type `T` specifies the return type of the route with which this gesture
/// detector is associated.
class _CupertinoBackGestureDetector<T> extends StatefulWidget {
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

  final ValueGetter<_CupertinoBackGestureController<T>> onStartPopGesture;

  @override
  _CupertinoBackGestureDetectorState<T> createState() => _CupertinoBackGestureDetectorState<T>();
}

class _CupertinoBackGestureDetectorState<T> extends State<_CupertinoBackGestureDetector<T>> {
  _CupertinoBackGestureController<T> _backGestureController;

  HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
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
    // For devices with notches, the drag area needs to be larger on the side
    // that has the notch.
    double dragAreaWidth = Directionality.of(context) == TextDirection.ltr ?
                           MediaQuery.of(context).padding.left :
                           MediaQuery.of(context).padding.right;
    dragAreaWidth = max(dragAreaWidth, _kBackGestureWidth);
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: dragAreaWidth,
          top: 0.0,
          bottom: 0.0,
          child: Listener(
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
///
/// The type `T` specifies the return type of the route with which this gesture
/// detector controller is associated.
class _CupertinoBackGestureController<T> {
  /// Creates a controller for an iOS-style back gesture.
  ///
  /// The [navigator] and [controller] arguments must not be null.
  _CupertinoBackGestureController({
    @required this.navigator,
    @required this.controller,
  }) : assert(navigator != null),
       assert(controller != null) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;

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
    //
    // This curve has been determined through rigorously eyeballing native iOS
    // animations.
    const Curve animationCurve = Curves.fastLinearToSlowEaseIn;
    bool animateForward;

    // If the user releases the page before mid screen with sufficient velocity,
    // or after mid screen, we should animate the page out. Otherwise, the page
    // should be animated back in.
    if (velocity.abs() >= _kMinFlingVelocity)
      animateForward = velocity <= 0;
    else
      animateForward = controller.value > 0.5;

    if (animateForward) {
      // The closer the panel is to dismissing, the shorter the animation is.
      // We want to cap the animation time, but we want to use a linear curve
      // to determine it.
      final int droppedPageForwardAnimationTime = min(
        lerpDouble(_kMaxDroppedSwipePageForwardAnimationTime, 0, controller.value).floor(),
        _kMaxPageBackAnimationTime,
      );
      controller.animateTo(1.0, duration: Duration(milliseconds: droppedPageForwardAnimationTime), curve: animationCurve);
    } else {
      // This route is destined to pop at this point. Reuse navigator's pop.
      navigator.pop();

      // The popping may have finished inline if already at the target destination.
      if (controller.isAnimating) {
        // Otherwise, use a custom popping animation duration and curve.
        final int droppedPageBackAnimationTime = lerpDouble(0, _kMaxDroppedSwipePageForwardAnimationTime, controller.value).floor();
        controller.animateBack(0.0, duration: Duration(milliseconds: droppedPageBackAnimationTime), curve: animationCurve);
      }
    }

    if (controller.isAnimating) {
      // Keep the userGestureInProgress in true state so we don't change the
      // curve of the page transition mid-flight since CupertinoPageTransition
      // depends on userGestureInProgress.
      AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
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
      _CupertinoEdgeShadowDecoration();

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
    return _CupertinoEdgeShadowDecoration(
      edgeGradient: LinearGradient.lerp(a?.edgeGradient, b?.edgeGradient, t),
    );
  }

  @override
  _CupertinoEdgeShadowDecoration lerpFrom(Decoration a, double t) {
    if (a is _CupertinoEdgeShadowDecoration)
      return _CupertinoEdgeShadowDecoration.lerp(a, this, t);
    return _CupertinoEdgeShadowDecoration.lerp(null, this, t);
  }

  @override
  _CupertinoEdgeShadowDecoration lerpTo(Decoration b, double t) {
    if (b is _CupertinoEdgeShadowDecoration)
      return _CupertinoEdgeShadowDecoration.lerp(this, b, t);
    return _CupertinoEdgeShadowDecoration.lerp(this, null, t);
  }

  @override
  _CupertinoEdgeShadowPainter createBoxPainter([ VoidCallback onChanged ]) {
    return _CupertinoEdgeShadowPainter(this, onChanged);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is _CupertinoEdgeShadowDecoration
        && other.edgeGradient == edgeGradient;
  }

  @override
  int get hashCode => edgeGradient.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LinearGradient>('edgeGradient', edgeGradient));
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
    final Paint paint = Paint()
      ..shader = gradient.createShader(rect, textDirection: textDirection);

    canvas.drawRect(rect, paint);
  }
}

class _CupertinoModalPopupRoute<T> extends PopupRoute<T> {
  _CupertinoModalPopupRoute({
    this.barrierColor,
    this.barrierLabel,
    this.builder,
    bool semanticsDismissible,
    ImageFilter filter,
    RouteSettings settings,
  }) : super(
         filter: filter,
         settings: settings,
       ) {
    _semanticsDismissible = semanticsDismissible;
  }

  final WidgetBuilder builder;
  bool _semanticsDismissible;

  @override
  final String barrierLabel;

  @override
  final Color barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  bool get semanticsDismissible => _semanticsDismissible ?? false;

  @override
  Duration get transitionDuration => _kModalPopupTransitionDuration;

  Animation<double> _animation;

  Tween<Offset> _offsetTween;

  @override
  Animation<double> createAnimation() {
    assert(_animation == null);
    _animation = CurvedAnimation(
      parent: super.createAnimation(),

      // These curves were initially measured from native iOS horizontal page
      // route animations and seemed to be a good match here as well.
      curve: Curves.linearToEaseOut,
      reverseCurve: Curves.linearToEaseOut.flipped,
    );
    _offsetTween = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: const Offset(0.0, 0.0),
    );
    return _animation;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return CupertinoUserInterfaceLevel(
      data: CupertinoUserInterfaceLevelData.elevated,
      child: Builder(builder: builder),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionalTranslation(
        translation: _offsetTween.evaluate(_animation),
        child: child,
      ),
    );
  }
}

/// Shows a modal iOS-style popup that slides up from the bottom of the screen.
///
/// Such a popup is an alternative to a menu or a dialog and prevents the user
/// from interacting with the rest of the app.
///
/// The `context` argument is used to look up the [Navigator] for the popup.
/// It is only used when the method is called. Its corresponding widget can be
/// safely removed from the tree before the popup is closed.
///
/// The `useRootNavigator` argument is used to determine whether to push the
/// popup to the [Navigator] furthest from or nearest to the given `context`. It
/// is `false` by default.
///
/// The `semanticsDismissible` argument is used to determine whether the
/// semantics of the modal barrier are included in the semantics tree.
///
/// The `builder` argument typically builds a [CupertinoActionSheet] widget.
/// Content below the widget is dimmed with a [ModalBarrier]. The widget built
/// by the `builder` does not share a context with the location that
/// `showCupertinoModalPopup` is originally called from. Use a
/// [StatefulBuilder] or a custom [StatefulWidget] if the widget needs to
/// update dynamically.
///
/// Returns a `Future` that resolves to the value that was passed to
/// [Navigator.pop] when the popup was closed.
///
/// See also:
///
///  * [CupertinoActionSheet], which is the widget usually returned by the
///    `builder` argument to [showCupertinoModalPopup].
///  * <https://developer.apple.com/design/human-interface-guidelines/ios/views/action-sheets/>
Future<T> showCupertinoModalPopup<T>({
  @required BuildContext context,
  @required WidgetBuilder builder,
  ImageFilter filter,
  bool useRootNavigator = true,
  bool semanticsDismissible,
}) {
  assert(useRootNavigator != null);
  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    _CupertinoModalPopupRoute<T>(
      barrierColor: CupertinoDynamicColor.resolve(_kModalBarrierColor, context),
      barrierLabel: 'Dismiss',
      builder: builder,
      filter: filter,
      semanticsDismissible: semanticsDismissible,
    ),
  );
}

// The curve and initial scale values were mostly eyeballed from iOS, however
// they reuse the same animation curve that was modeled after native page
// transitions.
final Animatable<double> _dialogScaleTween = Tween<double>(begin: 1.3, end: 1.0)
  .chain(CurveTween(curve: Curves.linearToEaseOut));

Widget _buildCupertinoDialogTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  final CurvedAnimation fadeAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOut,
  );
  if (animation.status == AnimationStatus.reverse) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: child,
    );
  }
  return FadeTransition(
    opacity: fadeAnimation,
    child: ScaleTransition(
      child: child,
      scale: animation.drive(_dialogScaleTween),
    ),
  );
}

/// Displays an iOS-style dialog above the current contents of the app, with
/// iOS-style entrance and exit animations, modal barrier color, and modal
/// barrier behavior (by default, the dialog is not dismissible with a tap on
/// the barrier).
///
/// This function takes a `builder` which typically builds a [CupertinoDialog]
/// or [CupertinoAlertDialog] widget. Content below the dialog is dimmed with a
/// [ModalBarrier]. The widget returned by the `builder` does not share a
/// context with the location that `showCupertinoDialog` is originally called
/// from. Use a [StatefulBuilder] or a custom [StatefulWidget] if the dialog
/// needs to update dynamically.
///
/// The `context` argument is used to look up the [Navigator] for the dialog.
/// It is only used when the method is called. Its corresponding widget can
/// be safely removed from the tree before the dialog is closed.
///
/// The `useRootNavigator` argument is used to determine whether to push the
/// dialog to the [Navigator] furthest from or nearest to the given `context`.
/// By default, `useRootNavigator` is `true` and the dialog route created by
/// this method is pushed to the root navigator.
///
/// If the application has multiple [Navigator] objects, it may be necessary to
/// call `Navigator.of(context, rootNavigator: true).pop(result)` to close the
/// dialog rather than just `Navigator.pop(context, result)`.
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the dialog was closed.
///
/// See also:
///
///  * [CupertinoDialog], an iOS-style dialog.
///  * [CupertinoAlertDialog], an iOS-style alert dialog.
///  * [showDialog], which displays a Material-style dialog.
///  * [showGeneralDialog], which allows for customization of the dialog popup.
///  * <https://developer.apple.com/ios/human-interface-guidelines/views/alerts/>
Future<T> showCupertinoDialog<T>({
  @required BuildContext context,
  @required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool barrierDismissible = false,
  RouteSettings routeSettings,
}) {
  assert(builder != null);
  assert(useRootNavigator != null);
  return showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: CupertinoLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: CupertinoDynamicColor.resolve(_kModalBarrierColor, context),
    // This transition duration was eyeballed comparing with iOS
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: _buildCupertinoDialogTransitions,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}
