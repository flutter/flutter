// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';
import 'colors.dart';

// The scale of the child at the time that the ContextMenu opens.
const double _kOpenScale = 1.2;

/// A full-screen menu that can be activated for the given child.
///
/// Long pressing or 3d touching on the child will open in up in a full-screen
/// overlay menu.
// TODO(justinmc): Set up type param here for return value.
class ContextMenu extends StatefulWidget {
  /// Create a context menu.
  ContextMenu({
    Key key,
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

  final GlobalKey _childGlobalKey = GlobalKey();
  final GlobalKey _containerGlobalKey = GlobalKey();

  Animation<int> _mask;
  Animation<Matrix4> _transform;
  AnimationController _controller;
  bool _isOpen = false;
  _ContextMenuRoute<void> _route;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.addStatusListener(_onAnimationChangeStatus);
    _mask = IntTween(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.9,
        ),
      ),
    );
    _transform = Tween<Matrix4>(
      begin: Matrix4.identity(),
      end: Matrix4.identity()..scale(_kOpenScale),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInBack,
      ),
    );
  }

  void _onAnimationChangeStatus(AnimationStatus animationStatus) {
    if (animationStatus == AnimationStatus.completed) {
      _openContextMenu();
    }
  }

  void _openContextMenu() {
    setState(() {
      _isOpen = true;
    });

    // Get the original Rect of the child before any transformation.
    assert(_childGlobalKey.currentContext != null);
    final RenderBox renderBoxContainer = _containerGlobalKey.currentContext.findRenderObject();
    final Offset containerOffset = renderBoxContainer.localToGlobal(renderBoxContainer.paintBounds.topLeft);
    final Rect originalChildRect = containerOffset & renderBoxContainer.paintBounds.size;

    // Get the Rect of the child right at the end of the transformation.
    // Consider that the Transform has `alignment` set to `Alignment.center`.
    final Vector4 sizeVector = _transform.value.transform(Vector4(
      originalChildRect.width,
      originalChildRect.height,
      0.0,
      0.0,
    ));
    final Rect childRect = Rect.fromLTWH(
      originalChildRect.left,
      originalChildRect.top,
      sizeVector.x,
      sizeVector.y,
    );

    final Rect parentRect = Offset.zero & MediaQuery.of(context).size;
    final Opacity container = _childGlobalKey.currentContext.widget;
    _route = _ContextMenuRoute<void>(
      barrierLabel: 'Dismiss',
      filter: ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ),
      childRect: childRect,
      parentRect: parentRect,
      actions: widget.actions,
      onTap: widget.onTap,
      builder: (BuildContext context) {
        return container.child;
      },
    );
    Navigator.of(context, rootNavigator: true).push<void>(_route);
    _route.animation.addStatusListener(_routeAnimationStatusListener);
  }

  void _routeAnimationStatusListener(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) {
      return;
    }
    _controller.reset();
    setState(() {
      _isOpen = false;
    });
    _route.animation.removeStatusListener(_routeAnimationStatusListener);
    _route = null;
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  Widget _buildAnimation(BuildContext context, Widget child) {
    final bool isAnimating = _controller.status == AnimationStatus.forward;
    final Color maskColor = isAnimating && _mask.value == 1
      ? _lightModeMaskColor
      : const Color(0xFFFFFFFF);

    return Container(
      key: _containerGlobalKey,
      child: Transform(
        alignment: Alignment.center,
        transform: _transform?.value ?? Matrix4.identity(),
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[maskColor, maskColor],
            ).createShader(bounds);
          },
          child: Opacity(
            opacity: _isOpen ? 0.0 : 1.0,
            key: _childGlobalKey,
            // TODO(justinmc): Round corners of child?
            child: widget.child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      child: AnimatedBuilder(
        builder: _buildAnimation,
        animation: _controller,
      ),
    );
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.reset();
    _transform = null;
    super.dispose();
  }
}

// The open context menu.
// TODO(justinmc): In native, dragging on the menu or the child animates and
// eventually dismisses.
class _ContextMenuRoute<T> extends PopupRoute<T> {
  _ContextMenuRoute({
    this.barrierLabel,
    @required List<ContextMenuSheetAction> actions,
    WidgetBuilder builder,
    ui.ImageFilter filter,
    RouteSettings settings,
    Rect childRect,
    VoidCallback onTap,
    Rect parentRect,
  }) : assert(actions != null && actions.isNotEmpty),
       _actions = actions,
       _builder = builder,
       _childRect = childRect,
       _onTap = onTap,
       _parentRect = parentRect,
       super(
         filter: filter,
         settings: settings,
       );

  // The rect containing the widget that should show in the ContextMenu, in its
  // original position before animating.
  final Rect _childRect;

  // A rect that indicates the space available to position the child.
  // TODO(justinmc): I don't like the idea of needing to pass this in. Is it
  // possible to get the full screen size in createAnimation? Problem is that
  // this widget hasn't built yet by the time createAnimation is called.
  final Rect _parentRect;

  // Barrier color for a Cupertino modal barrier.
  static const Color _kModalBarrierColor = Color(0x6604040F);
  // The duration of the transition used when a modal popup is shown.
  static const Duration _kModalPopupTransitionDuration = Duration(milliseconds: 335);

  final List<ContextMenuSheetAction> _actions;
  final WidgetBuilder _builder;
  final VoidCallback _onTap;

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

  Animation<double> _animation;

  Tween<Offset> _offsetTween;
  Tween<double> _scaleTween;
  Tween<double> _scaleTweenReverse;

  // Given an initial untransformed child Rect and a parent to put it in, return
  // the Rect for its final position in the open ContextMenu.
  //
  // The final position is aligned so that its bottom is at the center of the
  // screen, and it's sized to be as big as possible. It's considered to be
  // inside of a Transform with `alignment` set to `Alignment.center`.
  // TODO(justinmc): Try this with a child that has a portrait aspect ratio. May
  // need to manually calculate safe area.
  static Rect _getEndRect(Rect child, Rect parent) {
    // The rect of the child at the time that the ContextMenu opens.
    final Rect openChildRect = Rect.fromLTWH(
      child.left,
      child.top,
      child.width * _kOpenScale,
      child.height * _kOpenScale,
    );

    final double endScale = math.max(
      parent.width / child.width * _kOpenScale,
      parent.height / parent.height * _kOpenScale,
    );
    final Size endChildSize = Size(
      child.width * endScale,
      child.height * endScale,
    );
    final Offset topLeftEnd = Offset(0.0, parent.height / 2 - endChildSize.height);
    final Offset adjustmentFromScale = Offset(
      (endChildSize.width - openChildRect.width) / 2,
      (endChildSize.height - openChildRect.height) / 2,
    );
    return (topLeftEnd + adjustmentFromScale) & endChildSize;
  }

  @override
  Animation<double> createAnimation() {
    assert(_animation == null);
    _animation = CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linearToEaseOut,
    );

    final Rect endChildRect = _getEndRect(_childRect, _parentRect);
    _offsetTween = Tween<Offset>(
      begin: _childRect.topLeft,
      end: endChildRect.topLeft,
    );

    // When opening, the scale happens from the end of the child's bounce
    // animation to the final state. When closing, it goes from the final state
    // to the original position before the bounce.
    final double endScale = endChildRect.width / _childRect.width;
    _scaleTween = Tween<double>(
      begin: _kOpenScale,
      end: endScale,
    );
    _scaleTweenReverse = Tween<double>(
      begin: 1.0,
      end: endScale,
    );

    return _animation;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final bool reverse = _animation.status == AnimationStatus.reverse;
    final Offset offset = _offsetTween.evaluate(_animation);
    final double scale = reverse
      ? _scaleTweenReverse.evaluate(_animation)
      : _scaleTween.evaluate(_animation);

    // TODO(justinmc): Are taps not dismissing the modal when above or below?
    // Might need to make something transparent to gestures if possible. Some
    // parent of the transformed child is overhanging it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Transform(
                transformHitTests: true,
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(offset.dx, offset.dy)
                  ..scale(scale),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onTap,
                  child: _builder(context),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _ContextMenuSheet(
            actions: _actions,
          ),
        ),
      ],
    );
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
class ContextMenuSheetAction extends StatefulWidget {
  /// Construct a ContextMenuSheetAction.
  const ContextMenuSheetAction({
    Key key,
    @required this.child,
    this.onPressed,
  }) : assert(child != null),
       super(key: key);

  final Widget child;
  final VoidCallback onPressed;

  @override
  _ContextMenuSheetActionState createState() => _ContextMenuSheetActionState();
}

class _ContextMenuSheetActionState extends State<ContextMenuSheetAction> {
  static const Color _kBackgroundColor = Color(0xAAFFFFFF);
  static const Color _kBackgroundColorPressed = Color(0xAADDDDDD);
  static const double _kButtonHeight = 56.0;
  static const TextStyle _kActionSheetActionStyle = TextStyle(
    fontFamily: '.SF UI Text',
    inherit: false,
    fontSize: 20.0,
    fontWeight: FontWeight.w400,
    color: CupertinoColors.activeBlue,
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
            color: _isPressed ? _kBackgroundColorPressed : _kBackgroundColor,
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 10.0,
            ),
            child: DefaultTextStyle(
              style: _kActionSheetActionStyle,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
