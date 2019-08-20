// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';
import 'colors.dart';
import 'route.dart';

// The scale of the child at the time that the ContextMenu opens.
const double _kOpenScale = 1.2;

/// A full-screen menu that can be activated for the given child.
///
/// Long pressing or 3d touching on the child will open in up in a full-screen
/// overlay menu.
class ContextMenu extends StatefulWidget {
  /// Create a context menu.
  ContextMenu({
    Key key,
    @required this.child,
    @required this.actions,
    // TODO(justinnmc): Should I include a previewChild param to allow the
    // preview to look differently than the original?
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
  final GlobalKey _containerGlobalKey = GlobalKey();

  Animation<Color> _mask;
  Animation<Matrix4> _transform;
  AnimationController _controller;
  bool _isOpen = false;
  ContextMenuRoute<void> _route;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.addStatusListener(_onAnimationChangeStatus);
    _mask = _OnOffColorAnimation(
      controller: _controller,
      onColor: _lightModeMaskColor,
      offColor: _masklessColor,
      intervalOn: 0.2,
      intervalOff: 0.8,
    );
    _transform = Tween<Matrix4>(
      begin: Matrix4.identity(),
      end: Matrix4.identity()..scale(_kOpenScale),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.2,
          1.0,
          curve: Curves.easeInBack,
        ),
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
    final Hero container = _childGlobalKey.currentContext.widget;
    _route = ContextMenuRoute<void>(
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
    // TODO(justinmc): Get rid of swipe animation, use own blur.
    Navigator.of(context).push(CupertinoPageRoute<void>(
      builder: (BuildContext context) {
        return _ContextMenuOpen(
          actions: widget.actions,
          onTap: widget.onTap,
          child: Hero(
            tag: container.child,
            child: container.child,
          ),
        );
      }
    ));
    _controller.reset();
    setState(() {
      _isOpen = false;
    });
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTap() {
    // A regular tap should be totally separate from a long-press to open the
    // ContextMenu. If this gesture is just a tap, then don't do any animation
    // and allow the tap to be handled by another GestureDetector as if the
    // ContextMenu didn't exist.
    _controller.reset();
  }

  Widget _buildAnimation(BuildContext context, Widget child) {
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
              colors: <Color>[_mask.value, _mask.value],
            ).createShader(bounds);
          },
          child: Opacity(
            opacity: _isOpen ? 0.0 : 1.0,
            // TODO(justinmc): Round corners of child?
            child: Hero(
              key: _childGlobalKey,
              tag: widget.child,
              child: widget.child,
            ),
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
      onTap: _onTap,
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
@visibleForTesting
class ContextMenuRoute<T> extends PopupRoute<T> {
  /// Build a ContextMenuRoute.
  ContextMenuRoute({
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
  @visibleForTesting
  static Rect getEndRect(Rect child, Rect parent) {
    // The given child is the child at the time the ContextMenu opens, after the
    // bounce animation. originalChild is the child before any animation.
    final Rect originalChild = Rect.fromLTWH(
      // left and top are the same because the transform alignment is center.
      child.left,
      child.top,
      child.width / _kOpenScale,
      child.height / _kOpenScale,
    );

    // TODO(justinmc): Use real padding and/or safe area. Child needs to line up
    // with menu when full width, but unfortunately it's always coming out too
    // thin.
    const double topInset = 40.0;
    const double horizontalPadding = 20.0;
    final Rect container = Rect.fromLTWH(
      parent.left + horizontalPadding,
      parent.top + topInset,
      parent.width - horizontalPadding * 2,
      parent.height / 2 - topInset,
    );

    final double endScale = math.min(
      container.width / originalChild.width,
      container.height / originalChild.height,
    );
    final Size endChildSize = Size(
      originalChild.width * endScale,
      originalChild.height * endScale,
    );
    final Offset topLeftEnd = Offset(
      // Center horizontally, which won't be affected by the center alignment.
      container.left + (container.width - originalChild.width) / 2,
      // Align the bottom of the child with the bottom of the parent, adjusting
      // to consider center alignment of the transform.
      container.bottom - endChildSize.height + (container.height - originalChild.height) / 2,
    );
    return topLeftEnd & endChildSize;
  }

  @override
  Animation<double> createAnimation() {
    assert(_animation == null);
    _animation = CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linearToEaseOut,
    );

    final Rect endChildRect = getEndRect(_childRect, _parentRect);
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
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        final List<Widget> children =  <Widget>[
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
    );
  }
}

class _ContextMenuOpen extends StatelessWidget {
  _ContextMenuOpen({
    @required List<ContextMenuSheetAction> actions,
    Widget child,
    ui.ImageFilter filter,
    RouteSettings settings,
    Rect childRect,
    VoidCallback onTap,
    Rect parentRect,
  }) : assert(actions != null && actions.isNotEmpty),
       _actions = actions,
       _child = child,
       _childRect = childRect,
       _onTap = onTap,
       _parentRect = parentRect,
       super();

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
  final VoidCallback _onTap;
  final Widget _child;

  @override
  Widget build(BuildContext context) {
    // TODO(justinmc): Are taps not dismissing the modal when above or below?
    // Might need to make something transparent to gestures if possible. Some
    // parent of the transformed child is overhanging it.
    return BackdropFilter(
      filter: ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ),
      child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          final List<Widget> children =  <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onTap,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: _child,
                      ),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
          child: Row(
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
        ),
      ),
    );
  }
}

/// A button in a _ContextMenuSheet.
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
                  widget.child,
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
class _OnOffColorAnimation extends CompoundAnimation<Color> {
  _OnOffColorAnimation({
    AnimationController controller,
    @required Color onColor,
    @required Color offColor,
    @required double intervalOn,
    @required double intervalOff,
  }) : _offColor = offColor,
       assert(intervalOn >= 0.0 && intervalOn <= 1.0),
       assert(intervalOff >= 0.0 && intervalOff <= 1.0),
       assert(intervalOn <= intervalOff),
       super(
        first: ColorTween(begin: offColor, end: onColor).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(intervalOn, intervalOn),
          ),
        ),
        next: ColorTween(begin: onColor, end: offColor).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(intervalOff, intervalOff),
          ),
        ),
       );

  final Color _offColor;

  @override
  Color get value => next.value == _offColor ? next.value : first.value;
}
