// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart' show kMinFlingVelocity;
import 'package:flutter/physics.dart' show FrictionSimulation;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'colors.dart';

// The scale of the child at the time that the ContextMenu opens.
const double _kOpenScale = 1.2;

typedef void _DismissCallback(BuildContext context, double scale, double opacity);

// Given a GlobalKey, return the Rect of the corresponding RenderBox's
// paintBounds.
Rect _getRect(GlobalKey globalKey) {
  assert(globalKey.currentContext != null);
  final RenderBox renderBoxContainer = globalKey.currentContext.findRenderObject();
  final Offset containerOffset = renderBoxContainer.localToGlobal(renderBoxContainer.paintBounds.topLeft);
  return containerOffset & renderBoxContainer.paintBounds.size;
}

/// A full-screen menu that can be activated for the given child.
///
/// Long pressing or 3d touching on the child will open in up in a full-screen
/// overlay menu.
class ContextMenu extends StatefulWidget {
  /// Create a context menu.
  ContextMenu({
    Key key,
    // TODO(justinmc): Use a builder instead of child so that it's easier to
    // make duplicates?
    @required this.child,
    @required this.actions,
    this.onTap,
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
  AnimationController _dummyController;
  Rect _dummyChildEndRect;

  OverlayEntry _lastOverlayEntry;
  double _childOpacity = 1.0;
  ContextMenuRoute<void> _route;

  @override
  void initState() {
    super.initState();
    _dummyController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dummyController.addStatusListener(_onDummyAnimationStatusChange);
  }

  void _openContextMenu(Rect childRectEnd) {
    HapticFeedback.lightImpact();

    setState(() {
      _childOpacity = 0.0;
    });

    _route = ContextMenuRoute<void>(
      barrierLabel: 'Dismiss',
      filter: ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ),
      previousChildRect: _dummyChildEndRect,
      actions: widget.actions,
      onTap: widget.onTap,
      builder: (BuildContext context) {
        return widget.child;
      },
    );
    Navigator.of(context, rootNavigator: true).push<void>(_route);
    _route.animation.addStatusListener(_routeAnimationStatusListener);
  }

  // The OverlayEntry that positions widget.child directly on top of its
  // original position in this widget.
  OverlayEntry get _overlayEntry {
    final Rect childRect = _getRect(_childGlobalKey);
    _dummyChildEndRect = Rect.fromCenter(
      center: childRect.center,
      width: childRect.width * _kOpenScale,
      height: childRect.height * _kOpenScale,
    );

    return OverlayEntry(
      opaque: false,
      builder: (BuildContext context) {
        return _DummyChild(
          beginRect: childRect,
          child: widget.child,
          controller: _dummyController,
          endRect: _dummyChildEndRect,
        );
      },
    );
  }

  void _onDummyAnimationStatusChange(AnimationStatus animationStatus) {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
        setState(() {
          _childOpacity = 1.0;
        });
        _lastOverlayEntry?.remove();
        _lastOverlayEntry = null;
        _dummyController.reset();
        break;

      case AnimationStatus.completed:
        setState(() {
          _childOpacity = 0.0;
        });
        // TODO(justinmc): Maybe cache these instead of recalculating.
        final Rect childRect = _getRect(_childGlobalKey);
        final Rect endRect = Rect.fromCenter(
          center: childRect.center,
          width: childRect.width * _kOpenScale,
          height: childRect.height * _kOpenScale,
        );
        _openContextMenu(endRect);
        // TODO(justinmc): Without this, flashes white. I think due to rendering 1
        // frame offscreen?
        Future<void>.delayed(const Duration(milliseconds: 1)).then((_) {
          _lastOverlayEntry?.remove();
          _lastOverlayEntry = null;
          _dummyController.reset();
        });
        break;

      default:
        return;
    }
  }

  // Watch for when ContextMenuRoute is closed.
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
    if (_dummyController.isAnimating) {
      _dummyController.reverse();
    }
  }

  void _onTapCancel() {
    if (_dummyController.isAnimating) {
      _dummyController.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_dummyController.isAnimating) {
      _dummyController.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _childOpacity = 0.0;
    });
    _lastOverlayEntry = _overlayEntry;
    Overlay.of(context).insert(_lastOverlayEntry);
    _dummyController.forward();
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
        // TODO(justinmc): Round corners of child?
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _dummyController.dispose();
    super.dispose();
  }
}

// A floating copy of the child.
class _DummyChild extends StatefulWidget {
  const _DummyChild({
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
  _DummyChildState createState() => _DummyChildState();
}

class _DummyChildState extends State<_DummyChild> with TickerProviderStateMixin {
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

// TODO(justinmc): In native, dragging on the menu or the child animates and
// eventually dismisses.
/// The open ContextMenu modal.
@visibleForTesting
class ContextMenuRoute<T> extends PopupRoute<T> {
  /// Build a ContextMenuRoute.
  ContextMenuRoute({
    this.barrierLabel,
    @required List<ContextMenuSheetAction> actions,
    WidgetBuilder builder,
    ui.ImageFilter filter,
    RouteSettings settings,
    Rect previousChildRect,
    VoidCallback onTap,
  }) : assert(actions != null && actions.isNotEmpty),
       _actions = actions,
       _builder = builder,
       _onTap = onTap,
       _previousChildRect = previousChildRect,
       super(
         filter: filter,
         settings: settings,
       );

  // The Rect of the child at the moment that the ContextMenu opens.
  final Rect _previousChildRect;

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

  void _updateTweenRects() {
    final Rect childRect = _scale == null
      ? _getRect(_childGlobalKey)
      : _getScaledRect(_childGlobalKey, _scale);

    _rectTween.begin = _previousChildRect;
    _rectTween.end = childRect;

    final Rect sheetRect = _getRect(_sheetGlobalKey);
    _sheetRectTween.begin = _previousChildRect.topLeft & sheetRect.size;
    _sheetRectTween.end = sheetRect;
    _sheetScaleTween.begin = 0.0;
    _sheetScaleTween.end = _scale;

    // When opening, the transition happens from the end of the child's bounce
    // animation to the final state. When closing, it goes from the final state
    // to the original position before the bounce.
    final Rect childRectOriginal = Rect.fromCenter(
      center: _previousChildRect.center,
      width: _previousChildRect.width / _kOpenScale,
      height: _previousChildRect.height / _kOpenScale,
    );
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
    // animate the entire page into the scene. In the case of ContextMenuRoute,
    // two individual pieces of the page are animated into the scene in
    // buildTransitions, and null is returned here.
    return null;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final bool reverse = animation.status == AnimationStatus.reverse;
    final Rect rect = reverse ? _rectTweenReverse.evaluate(animation) : _rectTween.evaluate(animation);

    // TODO(justinmc): Try various types of children in the app. Things
    // contained in a SizedBox, a SizedBox itself, some Text, etc.

    // While the animation is running, render everything in a Stack so that
    // they're movable.
    if (!animation.isCompleted) {
      // TODO(justinmc): Use _DummyChild here?
      return Stack(
        children: <Widget>[
          Positioned.fromRect(
            rect: _sheetRectTween.evaluate(animation),
            child: Opacity(
              opacity: _sheetOpacity.value,
              child: Transform.scale(
                // TODO(justinmc): alignment should adapt based on side of screen.
                alignment: AlignmentDirectional.topStart,
                scale: _sheetScale.value,
                child: _ContextMenuSheet(
                  key: _sheetGlobalKey,
                  actions: _actions,
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
      onDismiss: _onDismiss,
      onTap: _onTap,
      sheetGlobalKey: _sheetGlobalKey,
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
    this.onDismiss,
    this.onTap,
    this.sheetGlobalKey,
  }) : super(key: key);

  final List<ContextMenuSheetAction> actions;
  final Widget child;
  final GlobalKey childGlobalKey;
  final _DismissCallback onDismiss;
  final VoidCallback onTap;
  final GlobalKey sheetGlobalKey;

  @override
  _ContextMenuRouteStaticState createState() => _ContextMenuRouteStaticState();
}

class _ContextMenuRouteStaticState extends State<_ContextMenuRouteStatic> with TickerProviderStateMixin {
  // The child is scaled down as it is dragged down until it hits this minimum
  // value.
  static const double _kMinScale = 0.8;
  static const double _kPadding = 20.0;

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
    if (orientation != Orientation.portrait) {
      return 1.0;
    }
    if (dy <= 0.0) {
      // Scale much more slowly when dragging in opposite direction of dismiss.
      final double maxDragDistanceReverse = maxDragDistance * 8;
      return math.max(
        _kMinScale,
        (maxDragDistanceReverse + dy) / maxDragDistanceReverse,
      );
    }
    return math.max(
      _kMinScale,
      (maxDragDistance - dy) / maxDragDistance,
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
      // If already at the finalPosition, no need to animate anywhere.
      if (_moveAnimation.value.dy == finalPosition) {
        return;
      }

      if (flingIsAway && _sheetController.status != AnimationStatus.forward) {
        _sheetController.forward();
      } else if (!flingIsAway && _sheetController.status != AnimationStatus.reverse) {
        _sheetController.reverse();
      }

      final FrictionSimulation frictionSimulation = FrictionSimulation.through(
        _moveAnimation.value.dy,
        finalPosition,
        details.velocity.pixelsPerSecond.dy,
        0.0,
      );
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
    _moveController.reverse();
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

  void _setDragOffset(Offset dragOffset) {
    final double endX = _kPadding * dragOffset.dx / 400.0;
    setState(() {
      _dragOffset = dragOffset;
      _moveAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(
          endX.clamp(-_kPadding, _kPadding),
          math.max(0.0, dragOffset.dy),
        ),
      ).animate(
        CurvedAnimation(
          parent: _moveController,
          curve: Curves.elasticIn,
        ),
      );

      // Fade the ContextMenuSheet out or in, if needed.
      if (_lastScale == _kMinScale
          && _sheetController.status != AnimationStatus.forward
          && _sheetScaleAnimation.value != 0.0) {
        _sheetController.forward();
      } else if (_lastScale > _kMinScale
          && _sheetController.status != AnimationStatus.reverse
          && _sheetScaleAnimation.value != 1.0) {
        _sheetController.reverse();
      }
    });
  }

  // Build the animation for the overall draggable dismissable content.
  Widget _buildAnimation(BuildContext context, Widget child) {
    return Transform.translate(
      offset: _moveAnimation.value,
      child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          final double maxDragDistance = MediaQuery.of(context).size.height;
          _lastScale = _getScale(
            orientation,
            maxDragDistance,
            _moveAnimation.value.dy,
          );
          final List<Widget> children =  <Widget>[
            Expanded(
              child: Align(
                alignment: orientation == Orientation.portrait
                  ? Alignment.bottomCenter
                  : Alignment.topRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTap,
                  child: Transform.scale(
                    key: widget.childGlobalKey,
                    scale: _lastScale,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
            // Create space between items in both Row and Column.
            Container(
              width: _kPadding,
              height: _kPadding,
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _sheetController,
                builder: _buildSheetAnimation,
              ),
            ),
          ];

          return orientation == Orientation.portrait ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            )
            : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
        },
      ),
    );
  }

  // Build the animation for the ContextMenuSheet.
  Widget _buildSheetAnimation(BuildContext context, Widget child) {
    return Transform.scale(
      // TODO(justinmc): Should adapt based on side of screen.
      alignment: AlignmentDirectional.topStart,
      scale: _sheetScaleAnimation.value,
      child: Opacity(
        opacity: _sheetOpacityAnimation.value,
        child: _ContextMenuSheet(
          key: widget.sheetGlobalKey,
          actions: widget.actions,
        ),
      ),
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
  }) : assert(actions != null && actions.isNotEmpty),
       super(key: key);

  final List<ContextMenuSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // TODO(justinmc): Rearrange the Flexible and the spacer based on what
        // side of the screen the original child was in
        Flexible(
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
        ),
        const Spacer(
          flex: 1,
        ),
      ],
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
