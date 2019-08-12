// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
//import 'package:flutter/painting.dart' show MatrixUtils;
import 'package:vector_math/vector_math_64.dart';

// The scale of the child at the time that the ContextMenu opens.
const double _kOpenScale = 1.2;

/// A full-screen menu that can be activated for the given child.
///
/// Long pressing or 3d touching on the child will open in up in a full-screen
/// overlay menu.
// TODO(justinmc): Set up type param here for return value.
class ContextMenu extends StatefulWidget {
  /// Create a context menu.
  const ContextMenu({
    Key key,
    @required this.child,
  }) : assert(child != null),
       super(key: key);

  /// The widget that can be opened in a ContextMenu.
  ///
  /// This widget will be displayed at its normal position in the widget tree,
  /// but long pressing or 3d touching on it will cause the ContextMenu to open.
  final Widget child;

  @override
  _ContextMenuState createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> with TickerProviderStateMixin {
  // TODO(justinmc): Replace with real system colors when dark mode is
  // supported for iOS.
  //static const Color _darkModeMaskColor = Color(0xAAFFFFFF);
  static const Color _lightModeMaskColor = Color(0xAAAAAAAA);

  final GlobalKey _childGlobalKey = GlobalKey();

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

    // Get the current position of the child
    assert(_childGlobalKey.currentContext != null);
    final RenderBox renderBox = _childGlobalKey.currentContext.findRenderObject();
    final Opacity container = _childGlobalKey.currentContext.widget;
    final Offset offset = renderBox.localToGlobal(renderBox.paintBounds.topLeft);
    final Rect originalChildRect = offset & renderBox.paintBounds.size;
    //final Rect rect = MatrixUtils.transformRect(_transform.value, originalChildRect);
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
    _route = _ContextMenuRoute<void>(
      barrierLabel: 'Dismiss',
      filter: ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ),
      childRect: childRect,
      parentRect: parentRect,
      builder: (BuildContext context) {
        return container.child;
      },
    );
    Navigator.of(context, rootNavigator: true).push<void>(_route);

    // Run the reverse animation in the main view after the modal finishes
    // animating out.
    _route.animation.addStatusListener(routeAnimationStatusListener);
  }

  void routeAnimationStatusListener(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) {
      return;
    }
    _controller.reverse();
    setState(() {
      _isOpen = false;
    });
    _route.animation.removeStatusListener(routeAnimationStatusListener);
    _route = null;
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  Widget _buildAnimation(BuildContext context, Widget whatever) {
    final bool isAnimating = _controller.status == AnimationStatus.forward;
    final Color maskColor = isAnimating && _mask.value == 1
      ? _lightModeMaskColor
      : const Color(0xFFFFFFFF);
    return Transform(
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
          child: widget.child,
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
class _ContextMenuRoute<T> extends PopupRoute<T> {
  _ContextMenuRoute({
    this.barrierLabel,
    this.builder,
    ui.ImageFilter filter,
    RouteSettings settings,
    Rect childRect,
    Rect parentRect,
  }) : _childRect = childRect,
       _parentRect = parentRect,
       super(
         filter: filter,
         settings: settings,
       );

  // The rect containing the widget that should show in the ContextMenu.
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

  final WidgetBuilder builder;

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

  @override
  Animation<double> createAnimation() {
    assert(_animation == null);
    _animation = CurvedAnimation(
      parent: super.createAnimation(),
      // These curves were initially measured from native iOS horizontal page
      // route animations and seemed to be a good match here as well.
      curve: Curves.linearToEaseOut,
      reverseCurve: Curves.linear,//Curves.easeInToLinear,
    );

    // endScale is the scale that fits the original child into the parent.
    //final Rect parentRect = Offset.zero & MediaQuery.of(subtreeContext).size;
    final double endScale = math.max(
      _parentRect.width / _childRect.width * _kOpenScale,
      _parentRect.height / _parentRect.height * _kOpenScale,
    );
    _scaleTween = Tween<double>(
      begin: _kOpenScale,
      end: endScale,
    );

    final double centerY = _parentRect.height / 2;
    final double endChildHeight = _childRect.height * endScale;
    // TODO(justinmc): topLeftEnd is off for now. Should align child's bottom to
    // midpoint of screen.
    final Offset topLeftEnd = Offset(0.0, _parentRect.height / 2 - endChildHeight);
    _offsetTween = Tween<Offset>(
      begin: _childRect.topLeft,
      end: topLeftEnd,
    );

    return _animation;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final Offset offset = _offsetTween.evaluate(_animation);
    return SafeArea(
      child: Container(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: 0.0,
                      left: 0.0,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(offset.dx, offset.dy)
                          ..scale(_scaleTween.evaluate(_animation)),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                child: Text('TODO make me a menu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
