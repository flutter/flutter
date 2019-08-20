// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';
import 'colors.dart';

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
    _mask = _OnOffAnimation<Color>(
      controller: _controller,
      onValue: _lightModeMaskColor,
      offValue: _masklessColor,
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
    final Opacity container = _childGlobalKey.currentContext.widget;
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

  RectTween _rectTween = RectTween();
  RectTween _rectTweenReverse = RectTween();

  // The final position of the child produced by builder after all animation has
  // stopped.
  Rect _childRectFinal;

  final GlobalKey _containerGlobalKey = GlobalKey();

  bool _externalOffstage = false;
  bool _internalOffstage = false;

  @override
  set offstage(bool value) {
    _externalOffstage = value;
    _setOffstageInternally();
  }

  void _setOffstageInternally() {
    super.offstage = _externalOffstage || _internalOffstage;
    // It's necessary to call changedInternalState to get the backdrop to
    // update.
    changedInternalState();
  }

  @override
  TickerFuture didPush() {
    _internalOffstage = true;
    _setOffstageInternally();

    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      assert(_containerGlobalKey.currentContext != null);
      final RenderBox renderBoxContainer = _containerGlobalKey.currentContext.findRenderObject();
      final Offset containerOffset = renderBoxContainer.localToGlobal(renderBoxContainer.paintBounds.topLeft);
      _childRectFinal = containerOffset & renderBoxContainer.paintBounds.size;
      _rectTween.begin = _childRect;
      _rectTween.end = _childRectFinal;

      // When opening, the transition happens from the end of the child's bounce
      // animation to the final state. When closing, it goes from the final state
      // to the original position before the bounce.
      final Rect childRectOriginal = Rect.fromLTWH(
        _childRect.left,
        _childRect.top,
        _childRect.width / _kOpenScale,
        _childRect.height / _kOpenScale,
      );
      _rectTweenReverse.begin = childRectOriginal;
      _rectTweenReverse.end = _childRectFinal;


      _internalOffstage = false;
      _setOffstageInternally();
    });
    return super.didPush();
  }

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linearToEaseOut,
    );
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
    // TODO(justinmc): At the start, doesn't quite line up with pre-modal child.
    // Maybe do entire animation inside this modal though?
    if (!animation.isCompleted) {
      return Stack(
        children: <Widget>[
          Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Align(
          alignment: Alignment.topLeft,
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
                            key: _containerGlobalKey,
                            child: _builder(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Create space between items in both Row and Column.
                Container(
                  width: 20,
                  height: 20,
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
        ),
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
