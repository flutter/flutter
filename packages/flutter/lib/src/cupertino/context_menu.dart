// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart' show kMinFlingVelocity;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'colors.dart';

// The scale of the child at the time that the ContextMenu opens.
const double _kOpenScale = 1.2;

typedef _DismissCallback = void Function(
  BuildContext context,
  double scale,
  double opacity,
);

// Given a GlobalKey, return the Rect of the corresponding RenderBox's
// paintBounds.
Rect _getRect(GlobalKey globalKey) {
  assert(globalKey.currentContext != null);
  final RenderBox renderBoxContainer = globalKey.currentContext.findRenderObject();
  final Offset containerOffset = renderBoxContainer.localToGlobal(renderBoxContainer.paintBounds.topLeft);
  return containerOffset & renderBoxContainer.paintBounds.size;
}

// The context menu arranges itself slightly differently based on the location
// on the screen of the original child.
enum _ContextMenuOrientation {
  center,
  left,
  right,
}

/// A full-screen menu that can be activated for the given child.
///
/// Long pressing or 3d touching on the child will open in up in a full-screen
/// overlay menu.
class ContextMenu extends StatefulWidget {
  /// Create a context menu.
  ContextMenu({
    Key key,
    @required this.actions,
    @required this.child,
    this.onTap,
    this.preview,
  }) : assert(actions != null && actions.isNotEmpty),
       assert(child != null),
       super(key: key);

  /// The widget that can be opened in a ContextMenu.
  ///
  /// This widget will be displayed at its normal position in the widget tree,
  /// but long pressing or 3d touching on it will cause the ContextMenu to open.
  final Widget child;

  /// The actions that are shown in the menu.
  final List<ContextMenuSheetAction> actions;

  /// The callback to call when tapping on the child when the ContextMenu is
  /// open.
  final VoidCallback onTap;

  /// The widget to show when the ContextMenu is open.
  ///
  /// If not specified, [child] will be shown.
  ///
  /// This can be used to shown an entirely different widget than the preview,
  /// but it can also show a slight variation of the child. As a simple example,
  /// the child could be given rounded corners in the preview but have sharp
  /// corners when in the page.
  final Widget preview;

  @override
  _ContextMenuState createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> with TickerProviderStateMixin {
  // TODO(justinmc): Replace with real system colors when dark mode is
  // supported for iOS.
  //static const Color _darkModeMaskColor = Color(0xAAFFFFFF);
  static const Color _lightModeMaskColor = Color(0xAAAAAAAA);
  static const Color _masklessColor = Color(0xFFFFFFFF);

  final GlobalKey _childGlobalKey = GlobalKey();
  AnimationController _decoyController;
  Rect _decoyChildEndRect;

  OverlayEntry _lastOverlayEntry;
  double _childOpacity = 1.0;
  _ContextMenuRoute<void> _route;

  @override
  void initState() {
    super.initState();
    _decoyController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _decoyController.addStatusListener(_onDecoyAnimationStatusChange);
  }

  // Determine the _ContextMenuOrientation based on the location of the original
  // child in the screen.
  _ContextMenuOrientation get _contextMenuOrientation {
    final Rect childRect = _getRect(_childGlobalKey);
    final double screenWidth = MediaQuery.of(context).size.width;

    final double center = screenWidth / 2;
    final bool centerDividesChild = childRect.left < center && childRect.right > center;
    final double minCenterWidth = screenWidth / 4;
    final double maxCenterWidth = screenWidth / 3;
    final bool isCenterWidth = childRect.width >= minCenterWidth
      && childRect.width <= maxCenterWidth;
    if (centerDividesChild && isCenterWidth) {
      return _ContextMenuOrientation.center;
    }

    if (childRect.center.dx > center) {
      return _ContextMenuOrientation.right;
    }

    return _ContextMenuOrientation.left;
  }

  // Push the new route and open the ContextMenu overlay.
  void _openContextMenu() {
    HapticFeedback.lightImpact();

    setState(() {
      _childOpacity = 0.0;
    });

    _route = _ContextMenuRoute<void>(
      actions: widget.actions,
      barrierLabel: 'Dismiss',
      filter: ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ),
      onTap: widget.onTap,
      contextMenuOrientation: _contextMenuOrientation,
      previousChildRect: _decoyChildEndRect,
      builder: (BuildContext context) {
        return widget.preview ?? widget.child;
      },
    );
    Navigator.of(context, rootNavigator: true).push<void>(_route);
    _route.animation.addStatusListener(_routeAnimationStatusListener);
  }

  // The OverlayEntry that positions widget.child directly on top of its
  // original position in this widget.
  OverlayEntry get _overlayEntry {
    final Rect childRect = _getRect(_childGlobalKey);
    _decoyChildEndRect = Rect.fromCenter(
      center: childRect.center,
      width: childRect.width * _kOpenScale,
      height: childRect.height * _kOpenScale,
    );

    // TODO(justinmc): This overlay pops above things like the appbar when it
    // shouldn't. Can be solved for Route in the by fading in/out, but not here.
    return OverlayEntry(
      opaque: false,
      builder: (BuildContext context) {
        return _DecoyChild(
          beginRect: childRect,
          child: widget.child,
          controller: _decoyController,
          endRect: _decoyChildEndRect,
        );
      },
    );
  }

  void _onDecoyAnimationStatusChange(AnimationStatus animationStatus) {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
        if (_route == null) {
          setState(() {
            _childOpacity = 1.0;
          });
        }
        _lastOverlayEntry?.remove();
        _lastOverlayEntry = null;
        break;

      case AnimationStatus.completed:
        setState(() {
          _childOpacity = 0.0;
        });
        _openContextMenu();
        // TODO(justinmc): Without this, flashes white. I think due to rendering 1
        // frame offscreen?
        Future<void>.delayed(const Duration(milliseconds: 1)).then((_) {
          _lastOverlayEntry?.remove();
          _lastOverlayEntry = null;
          _decoyController.reset();
        });
        break;

      default:
        return;
    }
  }

  // Watch for when _ContextMenuRoute is closed.
  void _routeAnimationStatusListener(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) {
      return;
    }
    setState(() {
      _childOpacity = 1.0;
    });
    _route.animation.removeStatusListener(_routeAnimationStatusListener);
    _route = null;
  }

  void _onTap() {
    if (_decoyController.isAnimating) {
      _decoyController.reverse();
    }
  }

  void _onTapCancel() {
    if (_decoyController.isAnimating) {
      _decoyController.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_decoyController.isAnimating) {
      _decoyController.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _childOpacity = 0.0;
    });
    _lastOverlayEntry = _overlayEntry;
    Overlay.of(context).insert(_lastOverlayEntry);
    _decoyController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapCancel: _onTapCancel,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTap: _onTap,
      child: Opacity(
        opacity: _childOpacity,
        key: _childGlobalKey,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _decoyController.dispose();
    super.dispose();
  }
}

// A floating copy of the child.
class _DecoyChild extends StatefulWidget {
  const _DecoyChild({
    Key key,
    this.beginRect,
    this.child,
    this.controller,
    this.endRect,
  }) : super(key: key);

  final Rect beginRect;
  final Widget child;
  final AnimationController controller;
  final Rect endRect;

  @override
  _DecoyChildState createState() => _DecoyChildState();
}

class _DecoyChildState extends State<_DecoyChild> with TickerProviderStateMixin {
  // TODO(justinmc): Replace with real system colors when dark mode is
  // supported for iOS.
  //static const Color _darkModeMaskColor = Color(0xAAFFFFFF);
  static const Color _lightModeMaskColor = Color(0xFF888888);
  static const Color _masklessColor = Color(0xFFFFFFFF);

  final GlobalKey _childGlobalKey = GlobalKey();
  Animation<Color> _mask;
  Animation<Rect> _rect;

  @override
  void initState() {
    super.initState();
    _mask = _OnOffAnimation<Color>(
      controller: widget.controller,
      onValue: _lightModeMaskColor,
      offValue: _masklessColor,
      intervalOn: 0.0,
      intervalOff: 0.4,
    );
    _rect = RectTween(
      begin: widget.beginRect,
      end: widget.endRect,
    ).animate(
      CurvedAnimation(
        parent: widget.controller,
        // TODO(justinmc): This curve is close but not quite right. Should I
        // hack some delay and amplitude changes, or write a new curve?
        curve: Curves.easeInBack,
      ),
    );
  }

  Widget _buildAnimation(BuildContext context, Widget child) {
    final Color color = widget.controller.status == AnimationStatus.reverse
      ? _masklessColor
      : _mask.value;
    return Positioned.fromRect(
      rect: _rect.value,
      child: ShaderMask(
        key: _childGlobalKey,
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[color, color],
          ).createShader(bounds);
        },
        child: widget.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedBuilder(
          builder: _buildAnimation,
          animation: widget.controller,
        ),
      ],
    );
  }
}

/// The open ContextMenu modal.
class _ContextMenuRoute<T> extends PopupRoute<T> {
  /// Build a _ContextMenuRoute.
  _ContextMenuRoute({
    this.barrierLabel,
    @required List<ContextMenuSheetAction> actions,
    WidgetBuilder builder,
    ui.ImageFilter filter,
    VoidCallback onTap,
    @required _ContextMenuOrientation contextMenuOrientation,
    Rect previousChildRect,
    RouteSettings settings,
  }) : assert(actions != null && actions.isNotEmpty),
       assert(contextMenuOrientation != null),
       _actions = actions,
       _builder = builder,
       _onTap = onTap,
       _contextMenuOrientation = contextMenuOrientation,
       _previousChildRect = previousChildRect,
       super(
         filter: filter,
         settings: settings,
       );

  // The Rect of the child at the moment that the ContextMenu opens.
  final Rect _previousChildRect;

  final _ContextMenuOrientation _contextMenuOrientation;
  Orientation _lastOrientation;

  // Barrier color for a Cupertino modal barrier.
  static const Color _kModalBarrierColor = Color(0x6604040F);
  // The duration of the transition used when a modal popup is shown.
  static const Duration _kModalPopupTransitionDuration = Duration(milliseconds: 335);

  final List<ContextMenuSheetAction> _actions;
  final WidgetBuilder _builder;
  final VoidCallback _onTap;
  double _scale = 1.0;

  final RectTween _rectTween = RectTween();
  final RectTween _rectTweenReverse = RectTween();
  final RectTween _sheetRectTween = RectTween();
  final Tween<double> _sheetScaleTween = Tween<double>();
  final Tween<double> _opacityTween = Tween<double>(begin: 0.0, end: 1.0);
  Animation<double> _sheetOpacity;
  Animation<double> _sheetScale;

  final GlobalKey _childGlobalKey = GlobalKey();
  final GlobalKey _sheetGlobalKey = GlobalKey();

  bool _externalOffstage = false;
  bool _internalOffstage = false;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => _kModalBarrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  bool get semanticsDismissible => false;

  @override
  Duration get transitionDuration => _kModalPopupTransitionDuration;

  // Getting the RenderBox doesn't include the scale from the Transform.scale,
  // so it's manually accounted for here.
  static Rect _getScaledRect(GlobalKey globalKey, double scale) {
    final Rect childRect = _getRect(globalKey);
    final Size sizeScaled = childRect.size * scale;
    final Offset offsetScaled = Offset(
      childRect.left + (childRect.size.width - sizeScaled.width) / 2,
      childRect.top + (childRect.size.height - sizeScaled.height) / 2,
    );
    return offsetScaled & sizeScaled;
  }

  // Get the alignment for the ContextMenuSheet's Transform.scale based on the
  // ContextMenuOrientation.
  static AlignmentDirectional getSheetAlignment(_ContextMenuOrientation contextMenuOrientation) {
    switch (contextMenuOrientation) {
      case (_ContextMenuOrientation.center):
        return AlignmentDirectional.topCenter;
      case (_ContextMenuOrientation.left):
        return AlignmentDirectional.topStart;
      case (_ContextMenuOrientation.right):
        return AlignmentDirectional.topEnd;
    }
  }

  // The place to start the sheetRect animation from.
  static Rect _getSheetRectBegin(Orientation orientation, _ContextMenuOrientation contextMenuOrientation, Rect childRect, Rect sheetRect) {
    switch (contextMenuOrientation) {
      case (_ContextMenuOrientation.center):
        final Offset target = orientation == Orientation.portrait
          ? childRect.bottomCenter
          : childRect.topCenter;
        final Offset centered = target - Offset(sheetRect.width / 2, 0.0);
        return centered & sheetRect.size;
      case (_ContextMenuOrientation.left):
        final Offset target = orientation == Orientation.portrait
          ? childRect.bottomLeft
          : childRect.topLeft;
        return target & sheetRect.size;
      case (_ContextMenuOrientation.right):
        final Offset target = orientation == Orientation.portrait
          ? childRect.bottomRight
          : childRect.topRight;
        return (target - Offset(sheetRect.width, 0.0)) & sheetRect.size;
    }
  }

  void _onDismiss(BuildContext context, double scale, double opacity) {
    _scale = scale;
    _opacityTween.end = opacity;
    _sheetOpacity = _opacityTween.animate(CurvedAnimation(
      parent: animation,
      curve: Interval(0.9, 1.0),
    ));
    // TODO(justinmc): The fadeout animation is not perfectly seamless, should
    // continue at the same speed as the drag-to-dismiss animation.
    Navigator.of(context).pop();
  }

  // Take measurements on the child and ContextMenuSheet and update the
  // animation tweens to match.
  void _updateTweenRects() {
    final Rect childRect = _scale == null
      ? _getRect(_childGlobalKey)
      : _getScaledRect(_childGlobalKey, _scale);
    _rectTween.begin = _previousChildRect;
    _rectTween.end = childRect;

    // When opening, the transition happens from the end of the child's bounce
    // animation to the final state. When closing, it goes from the final state
    // to the original position before the bounce.
    final Rect childRectOriginal = Rect.fromCenter(
      center: _previousChildRect.center,
      width: _previousChildRect.width / _kOpenScale,
      height: _previousChildRect.height / _kOpenScale,
    );

    final Rect sheetRect = _getRect(_sheetGlobalKey);
    final Rect sheetRectBegin = _getSheetRectBegin(
      _lastOrientation,
      _contextMenuOrientation,
      childRectOriginal,
      sheetRect,
    );
    _sheetRectTween.begin = sheetRectBegin;
    _sheetRectTween.end = sheetRect;
    _sheetScaleTween.begin = 0.0;
    _sheetScaleTween.end = _scale;

    _rectTweenReverse.begin = childRectOriginal;
    _rectTweenReverse.end = childRect;
  }

  void _setOffstageInternally() {
    super.offstage = _externalOffstage || _internalOffstage;
    // It's necessary to call changedInternalState to get the backdrop to
    // update.
    changedInternalState();
  }

  @override
  bool didPop(T result) {
    _updateTweenRects();
    return super.didPop(result);
  }

  @override
  set offstage(bool value) {
    _externalOffstage = value;
    _setOffstageInternally();
  }

  @override
  TickerFuture didPush() {
    _internalOffstage = true;
    _setOffstageInternally();

    // Render one frame offstage in the final position so that we can take
    // measurements of its layout and then animate to them.
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _updateTweenRects();
      _internalOffstage = false;
      _setOffstageInternally();
    });
    return super.didPush();
  }

  @override
  Animation<double> createAnimation() {
    final CurvedAnimation animation = CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linearToEaseOut,
    );
    _sheetOpacity = _opacityTween.animate(CurvedAnimation(
      parent: animation,
      curve: Curves.linear,
    ));
    _sheetScale = _sheetScaleTween.animate(CurvedAnimation(
      parent: animation,
      curve: Curves.linear,
    ));
    return animation;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    // This is usually used to build the "page", which is then passed to
    // buildTransitions as child, the idea being that buildTransitions will
    // animate the entire page into the scene. In the case of _ContextMenuRoute,
    // two individual pieces of the page are animated into the scene in
    // buildTransitions, and null is returned here.
    return null;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    // TODO(justinmc): Is it bad to put this OrientationBuilder so high in the
    // tree? Better way?
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        _lastOrientation = orientation;
        final bool reverse = animation.status == AnimationStatus.reverse;
        final Rect rect = reverse ? _rectTweenReverse.evaluate(animation) : _rectTween.evaluate(animation);
        final Rect sheetRect = _sheetRectTween.evaluate(animation);

        // TODO(justinmc): Try various types of children in the app. Things
        // contained in a SizedBox, a SizedBox itself, some Text, etc.

        // While the animation is running, render everything in a Stack so that
        // they're movable.
        if (!animation.isCompleted) {
          // TODO(justinmc): Use _DecoyChild here?
          return Stack(
            children: <Widget>[
              Positioned.fromRect(
                rect: sheetRect,
                child: Opacity(
                  opacity: _sheetOpacity.value,
                  child: Transform.scale(
                    alignment: getSheetAlignment(_contextMenuOrientation),
                    scale: _sheetScale.value,
                    child: _ContextMenuSheet(
                      key: _sheetGlobalKey,
                      actions: _actions,
                      contextMenuOrientation: _contextMenuOrientation,
                      orientation: orientation,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: _childGlobalKey,
                rect: rect,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: _builder(context),
                ),
              ),
            ],
          );
        }

        // When the animation is done, just render everything in a static layout in
        // the final position.
        return _ContextMenuRouteStatic(
          actions: _actions,
          child: _builder(context),
          childGlobalKey: _childGlobalKey,
          contextMenuOrientation: _contextMenuOrientation,
          onDismiss: _onDismiss,
          onTap: _onTap,
          orientation: orientation,
          sheetGlobalKey: _sheetGlobalKey,
        );
      },
    );
  }
}

// The final state of the ContextMenuRoute after animating in and before
// animating out.
class _ContextMenuRouteStatic extends StatefulWidget {
  const _ContextMenuRouteStatic({
    Key key,
    this.actions,
    @required this.child,
    this.childGlobalKey,
    @required this.contextMenuOrientation,
    this.onDismiss,
    this.onTap,
    @required this.orientation,
    this.sheetGlobalKey,
  }) : assert(contextMenuOrientation != null),
       assert(orientation != null),
       super(key: key);

  final List<ContextMenuSheetAction> actions;
  final Widget child;
  final GlobalKey childGlobalKey;
  final _ContextMenuOrientation contextMenuOrientation;
  final _DismissCallback onDismiss;
  final VoidCallback onTap;
  final Orientation orientation;
  final GlobalKey sheetGlobalKey;

  @override
  _ContextMenuRouteStaticState createState() => _ContextMenuRouteStaticState();
}

class _ContextMenuRouteStaticState extends State<_ContextMenuRouteStatic> with TickerProviderStateMixin {
  // The child is scaled down as it is dragged down until it hits this minimum
  // value.
  static const double _kMinScale = 0.8;
  // The ContextMenuSheet disappears at this scale.
  static const double _kSheetScaleThreshold = 0.9;
  static const double _kPadding = 20.0;
  static const double _kDamping = 400.0;

  final GlobalKey _childGlobalKey = GlobalKey();

  Offset _dragOffset;
  double _lastScale = 1.0;
  AnimationController _moveController;
  AnimationController _sheetController;
  Animation<Offset> _moveAnimation;
  Animation<double> _sheetScaleAnimation;
  Animation<double> _sheetOpacityAnimation;

  // The scale of the child changes as a function of the distance it is dragged.
  static double _getScale(Orientation orientation, double maxDragDistance, double dy) {
    final dyDirectional = dy <= 0.0 ? dy : -dy;
    return math.max(
      _kMinScale,
      (maxDragDistance + dyDirectional) / maxDragDistance,
    );
  }

  // The ContextMenuSheet fades out with distance dragged.
  static double _getOpacity(double maxDragDistance, double dy) {
    if (dy <= 0.0) {
      return 1.0;
    }
    return math.max(0.0, (maxDragDistance - dy * 4.0) / maxDragDistance);
  }

  void _onPanStart(DragStartDetails details) {
    _moveController.value = 1.0;
    _setDragOffset(Offset.zero);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _setDragOffset(_dragOffset + details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    // If flung, animate a bit before handling the potential dismiss.
    if (details.velocity.pixelsPerSecond.dy.abs() >= kMinFlingVelocity) {
      final bool flingIsAway = details.velocity.pixelsPerSecond.dy > 0;
      final double finalPosition = flingIsAway
        ? _moveAnimation.value.dy + 100.0
        : 0.0;

      if (flingIsAway && _sheetController.status != AnimationStatus.forward) {
        _sheetController.forward();
      } else if (!flingIsAway && _sheetController.status != AnimationStatus.reverse) {
        _sheetController.reverse();
      }

      _moveAnimation = Tween<Offset>(
        begin: Offset(0.0, _moveAnimation.value.dy),
        end: Offset(0.0, finalPosition),
      ).animate(_moveController);
      _moveController.reset();
      _moveController.duration = const Duration(
        milliseconds: 64,
      );
      _moveController.forward();
      _moveController.addStatusListener(_flingStatusListener);
      return;
    }

    // Dismiss if the drag is enough to scale down all the way.
    if (_lastScale == _kMinScale) {
      widget.onDismiss(context, _lastScale, _sheetOpacityAnimation.value);
      return;
    }

    // Otherwise animate back home.
    _moveController.addListener(_moveListener);
    _moveController.reverse();
  }

  void _moveListener() {
    // When the scale passes the threshold, animate the sheet back in.
    if (_lastScale > _kSheetScaleThreshold) {
      _moveController.removeListener(_moveListener);
      if (_sheetController.status != AnimationStatus.dismissed) {
        _sheetController.reverse();
      }
    }
  }

  void _flingStatusListener(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    _moveController.removeStatusListener(_flingStatusListener);
    // If it was a fling back to the start, it has reset itself, and it should
    // not be dismissed.
    if (_moveAnimation.value.dy == 0.0) {
      return;
    }
    widget.onDismiss(context, _lastScale, _sheetOpacityAnimation.value);
  }

  Alignment _getChildAlignment(Orientation orientation, _ContextMenuOrientation contextMenuOrientation) {
    switch (contextMenuOrientation) {
      case (_ContextMenuOrientation.center):
        return orientation == Orientation.portrait
          ? Alignment.bottomCenter
          : Alignment.topRight;
      case (_ContextMenuOrientation.left):
        return orientation == Orientation.portrait
          ? Alignment.bottomCenter
          : Alignment.topRight;
      case (_ContextMenuOrientation.right):
        return orientation == Orientation.portrait
          ? Alignment.bottomCenter
          : Alignment.topLeft;
    }
  }

  void _setDragOffset(Offset dragOffset) {
    // Allow horizontal and negative vertical movement, but damp it.
    final double endX = _kPadding * dragOffset.dx / _kDamping;
    final double endY = dragOffset.dy >= 0.0
      ? dragOffset.dy
      : _kPadding * dragOffset.dy / _kDamping;
    setState(() {
      _dragOffset = dragOffset;
      _moveAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(
          endX.clamp(-_kPadding, _kPadding),
          endY,
        ),
      ).animate(
        CurvedAnimation(
          parent: _moveController,
          curve: Curves.elasticIn,
        ),
      );

      // Fade the ContextMenuSheet out or in, if needed.
      if (_lastScale <= _kSheetScaleThreshold
          && _sheetController.status != AnimationStatus.forward
          && _sheetScaleAnimation.value != 0.0) {
        _sheetController.forward();
      } else if (_lastScale > _kSheetScaleThreshold
          && _sheetController.status != AnimationStatus.reverse
          && _sheetScaleAnimation.value != 1.0) {
        _sheetController.reverse();
      }
    });
  }

  // The order and alignment of the ContextMenuSheet and the child depend on
  // both the orientation of the screen as well as the position on the screen of
  // the original child.
  List<Widget> _getChildren(Orientation orientation, _ContextMenuOrientation contextMenuOrientation) {
    final Expanded child = Expanded(
      child: Align(
        alignment: _getChildAlignment(
          widget.orientation,
          widget.contextMenuOrientation,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _moveController,
            builder: _buildChildAnimation,
            child: FittedBox(
              fit: BoxFit.cover,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
    final Container spacer = Container(
      width: _kPadding,
      height: _kPadding,
    );
    final Expanded sheet = Expanded(
      child: AnimatedBuilder(
        animation: _sheetController,
        builder: _buildSheetAnimation,
        child: _ContextMenuSheet(
          key: widget.sheetGlobalKey,
          actions: widget.actions,
          contextMenuOrientation: widget.contextMenuOrientation,
          orientation: widget.orientation,
        ),
      ),
    );

    switch (contextMenuOrientation) {
      case (_ContextMenuOrientation.center):
        return <Widget>[child, spacer, sheet];
      case (_ContextMenuOrientation.left):
        return <Widget>[child, spacer, sheet];
      case (_ContextMenuOrientation.right):
        return orientation == Orientation.portrait
          ? <Widget>[child, spacer, sheet]
          : <Widget>[sheet, spacer, child];
    }
  }

  // Build the animation for the ContextMenuSheet.
  Widget _buildSheetAnimation(BuildContext context, Widget child) {
    return Transform.scale(
      alignment: _ContextMenuRoute.getSheetAlignment(widget.contextMenuOrientation),
      scale: _sheetScaleAnimation.value,
      child: Opacity(
        opacity: _sheetOpacityAnimation.value,
        child: child,
      ),
    );
  }

  // Build the animation for the child.
  Widget _buildChildAnimation(BuildContext context, Widget child) {
    _lastScale = _getScale(
      widget.orientation,
      MediaQuery.of(context).size.height,
      _moveAnimation.value.dy,
    );
    return Transform.scale(
      key: widget.childGlobalKey,
      scale: _lastScale,
      child: child,
    );
  }

  // Build the animation for the overall draggable dismissable content.
  Widget _buildAnimation(BuildContext context, Widget child) {
    return Transform.translate(
      offset: _moveAnimation.value,
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      value: 1.0,
      vsync: this,
    );
    _sheetController = AnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sheetScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _sheetController,
        curve: Curves.linear,
        reverseCurve: Curves.easeInBack,
      ),
    );
    _sheetOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_sheetController);
    _setDragOffset(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _getChildren(
      widget.orientation,
      widget.contextMenuOrientation,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(_kPadding),
        child: Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onPanEnd: _onPanEnd,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            child: AnimatedBuilder(
              animation: _moveController,
              builder: _buildAnimation,
              child: widget.orientation == Orientation.portrait ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                )
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _sheetController.dispose();
    super.dispose();
  }
}

// A menu of _ContextMenuSheetActions.
class _ContextMenuSheet extends StatelessWidget {
  _ContextMenuSheet({
    Key key,
    @required this.actions,
    @required _ContextMenuOrientation contextMenuOrientation,
    @required Orientation orientation,
  }) : assert(actions != null && actions.isNotEmpty),
       assert(contextMenuOrientation != null),
       assert(orientation != null),
       _contextMenuOrientation = contextMenuOrientation,
       _orientation = orientation,
       super(key: key);

  final List<ContextMenuSheetAction> actions;
  final _ContextMenuOrientation _contextMenuOrientation;
  final Orientation _orientation;

  // Get the children, whose order depends on orientation and
  // contextMenuOrientation.
  List<Widget> get children {
    final Flexible menu = Flexible(
      fit: FlexFit.tight,
      flex: 2,
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actions,
          ),
        ),
      ),
    );

    switch (_contextMenuOrientation) {
      case (_ContextMenuOrientation.left):
        return <Widget>[
          menu,
          const Spacer(
            flex: 1,
          ),
        ];
      case (_ContextMenuOrientation.right):
        return <Widget>[
          const Spacer(
            flex: 1,
          ),
          menu,
        ];
      case (_ContextMenuOrientation.center):
        return _orientation == Orientation.portrait
          ? <Widget>[
            const Spacer(
              flex: 1,
            ),
            menu,
            const Spacer(
              flex: 1,
            ),
          ]
        : <Widget>[
            menu,
            const Spacer(
              flex: 1,
            ),
          ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// A button in a _ContextMenuSheet.
///
/// A typical use case is to pass a [Text] as the [child] here, but be sure to
/// use [TextOverflow.ellipsis] for the [Text.overflow] field if the text may be
/// long, as without it the text will wrap to the next line.
class ContextMenuSheetAction extends StatefulWidget {
  /// Construct a ContextMenuSheetAction.
  const ContextMenuSheetAction({
    Key key,
    @required this.child,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.onPressed,
    this.trailingIcon,
  }) : assert(child != null),
       assert(isDefaultAction != null),
       assert(isDestructiveAction != null),
       super(key: key);

  /// The widget that will be placed inside the action.
  final Widget child;

  /// Indicates whether this action should receive the style of an emphasized,
  /// default action.
  final bool isDefaultAction;

  /// Indicates whether this action should receive the style of a destructive
  /// action.
  final bool isDestructiveAction;

  /// Called when the action is pressed.
  final VoidCallback onPressed;

  // TODO(justinmc): Is this in the spirit how we usually do things like this in
  // Flutter? All Apple examples I've seen of ContextMenus feature icons, so
  // this seemed like a nice way to encourage that. However, it's also totally
  // possible for the user to do this without this field.
  /// An optional icon to display to the right of the child.
  ///
  /// Will be colored in the same way as the [TextStyle] used for [child] (for
  /// example, if using [isDestructiveAction]).
  final IconData trailingIcon;

  @override
  _ContextMenuSheetActionState createState() => _ContextMenuSheetActionState();
}

class _ContextMenuSheetActionState extends State<ContextMenuSheetAction> {
  static const Color _kBackgroundColor = Color(0xFFEEEEEE);
  static const Color _kBackgroundColorPressed = Color(0xFFDDDDDD);
  static const double _kButtonHeight = 56.0;
  static const TextStyle _kActionSheetActionStyle = TextStyle(
    fontFamily: '.SF UI Text',
    inherit: false,
    fontSize: 20.0,
    fontWeight: FontWeight.w400,
    color: CupertinoColors.black,
    textBaseline: TextBaseline.alphabetic,
  );

  final GlobalKey _globalKey = GlobalKey();
  bool _isPressed = false;

  void onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  TextStyle get _textStyle {
    if (widget.isDefaultAction) {
      return _kActionSheetActionStyle.copyWith(
        fontWeight: FontWeight.w600,
      );
    }
    if (widget.isDestructiveAction) {
      return _kActionSheetActionStyle.copyWith(
        color: CupertinoColors.destructiveRed,
      );
    }
    return _kActionSheetActionStyle;
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _globalKey,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _kButtonHeight,
        ),
        child: Semantics(
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: _isPressed ? _kBackgroundColorPressed : _kBackgroundColor,
              border: const Border(
                bottom: BorderSide(width: 1.0, color: _kBackgroundColorPressed),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 10.0,
            ),
            child: DefaultTextStyle(
              style: _textStyle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: widget.child,
                  ),
                  if (widget.trailingIcon != null)
                    Icon(
                      widget.trailingIcon,
                      color: CupertinoColors.destructiveRed,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// An animation that switches immediately between two colors.
//
// The transition is immediate, so there are no intermediate values or
// interpolation. The color switches from offColor to onColor and back to
// offColor at the times given by intervalOn and intervalOff.
class _OnOffAnimation<T> extends CompoundAnimation<T> {
  _OnOffAnimation({
    AnimationController controller,
    @required T onValue,
    @required T offValue,
    @required double intervalOn,
    @required double intervalOff,
  }) : _offValue = offValue,
       assert(intervalOn >= 0.0 && intervalOn <= 1.0),
       assert(intervalOff >= 0.0 && intervalOff <= 1.0),
       assert(intervalOn <= intervalOff),
       super(
        first: Tween<T>(begin: offValue, end: onValue).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(intervalOn, intervalOn),
          ),
        ),
        next: Tween<T>(begin: onValue, end: offValue).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(intervalOff, intervalOff),
          ),
        ),
       );

  final T _offValue;

  @override
  T get value => next.value == _offValue ? next.value : first.value;
}
