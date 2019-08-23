// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'colors.dart';

// The scale of the child at the time that the ContextMenu opens.
const double _kOpenScale = 1.2;

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

  OverlayEntry _lastOverlayEntry;
  double _childOpacity = 1.0;
  ContextMenuRoute<void> _route;

  @override
  void initState() {
    super.initState();
    _dummyController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _dummyController.addStatusListener(_onDummyAnimationStatusChange);
  }

  void _openContextMenu(Rect childRectEnd) {
    setState(() {
      _childOpacity = 0.0;
    });

    _route = ContextMenuRoute<void>(
      barrierLabel: 'Dismiss',
      filter: ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ),
      previousChildGlobalKey: _childGlobalKey,
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
    final Rect endRect = childRect.inflate(_kOpenScale);

    return OverlayEntry(
      opaque: false,
      builder: (BuildContext context) {
        return _DummyChild(
          beginRect: childRect,
          child: widget.child,
          controller: _dummyController,
          endRect: endRect,
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
        final Rect endRect = childRect.inflate(_kOpenScale);
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

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _childOpacity = 0.0;
    });
    _lastOverlayEntry = _overlayEntry;
    Overlay.of(context).insert(_lastOverlayEntry);
    _dummyController.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_dummyController.isAnimating) {
      _dummyController.reverse();
    }
  }

  // A regular tap should be totally separate from a long-press to open the
  // ContextMenu. If this gesture is just a tap, then don't do any animation
  // and allow the tap to be handled by another GestureDetector as if the
  // ContextMenu didn't exist.
  void _onTap() {
    if (_dummyController.isAnimating) {
      _dummyController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressEnd: _onLongPressEnd,
      onLongPressStart: _onLongPressStart,
      child: Container(
        child: Opacity(
          opacity: _childOpacity,
          key: _childGlobalKey,
          // TODO(justinmc): Round corners of child?
          child: widget.child,
        ),
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
  static const Color _lightModeMaskColor = Color(0xAAAAAAAA);
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
      intervalOn: 0.2,
      intervalOff: 0.8,
    );
    _rect = RectTween(
      begin: widget.beginRect,
      end: widget.endRect,
    ).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Curves.easeInBack,
      ),
    );
  }

  Widget _buildAnimation(BuildContext context, Widget child) {
    return Positioned.fromRect(
      rect: _rect.value,
      child: ShaderMask(
        key: _childGlobalKey,
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_mask.value, _mask.value],
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

// The open context menu.
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
    GlobalKey previousChildGlobalKey,
    VoidCallback onTap,
  }) : assert(actions != null && actions.isNotEmpty),
       _actions = actions,
       _builder = builder,
       _onTap = onTap,
       _previousChildGlobalKey = previousChildGlobalKey,
       super(
         filter: filter,
         settings: settings,
       );

  // A rect that indicates the space available to position the child.
  // TODO(justinmc): I don't like the idea of needing to pass this in. Is it
  // possible to get the full screen size in createAnimation? Problem is that
  // this widget hasn't built yet by the time createAnimation is called.

  // The GlobalKey for the child in the previous route.
  final GlobalKey _previousChildGlobalKey;

  // Barrier color for a Cupertino modal barrier.
  static const Color _kModalBarrierColor = Color(0x6604040F);
  // The duration of the transition used when a modal popup is shown.
  static const Duration _kModalPopupTransitionDuration = Duration(milliseconds: 335);

  final List<ContextMenuSheetAction> _actions;
  final WidgetBuilder _builder;
  final VoidCallback _onTap;

  final RectTween _rectTween = RectTween();
  final RectTween _rectTweenReverse = RectTween();
  final RectTween _sheetRectTween = RectTween();
  final Tween<double> _opacityTween = Tween<double>(begin: 0.0, end: 1.0);

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

  void _updateTweenRects() {
    // The final Rect of the child where it has finished animating to its static
    // position.
    final Rect childRect = _getRect(_childGlobalKey);

    final Rect previousChildRect = _getRect(_previousChildGlobalKey);
    _rectTween.begin = previousChildRect;
    _rectTween.end = childRect;

    final Rect sheetRect = _getRect(_sheetGlobalKey);
    _sheetRectTween.begin = previousChildRect.topLeft & sheetRect.size;
    _sheetRectTween.end = sheetRect;

    // When opening, the transition happens from the end of the child's bounce
    // animation to the final state. When closing, it goes from the final state
    // to the original position before the bounce.
    final Rect childRectOriginal = previousChildRect.inflate(1 / _kOpenScale);
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
    if (!animation.isCompleted) {
      // TODO(justinmc): Use _DummyRect here?
      return Stack(
        children: <Widget>[
          Positioned.fromRect(
            rect: _sheetRectTween.evaluate(animation),
            child: Opacity(
              opacity: _opacityTween.evaluate(animation),
              child: _ContextMenuSheet(
                actions: _actions,
              ),
            ),
          ),
          Positioned.fromRect(
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
              final List<Widget> children =  <Widget>[
                Expanded(
                  child: Align(
                    // TODO(justinmc): Is alignment right when landscape?
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onTap,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        key: _childGlobalKey,
                        child: _builder(context),
                      ),
                    ),
                  ),
                ),
                // Create space between items in both Row and Column.
                Container(
                  width: 20,
                  height: 20,
                ),
                Expanded(
                  child: _ContextMenuSheet(
                    key: _sheetGlobalKey,
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
