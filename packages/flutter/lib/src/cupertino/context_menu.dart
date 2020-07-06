// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart' show kMinFlingVelocity, kLongPressTimeout;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// The scale of the child at the time that the CupertinoContextMenu opens.
// This value was eyeballed from a physical device running iOS 13.1.2.
const double _kOpenScale = 1.1;

typedef _DismissCallback = void Function(
  BuildContext context,
  double scale,
  double opacity,
);

/// A function that produces the preview when the CupertinoContextMenu is open.
///
/// Called every time the animation value changes.
typedef ContextMenuPreviewBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Widget child,
);

// A function that proxies to ContextMenuPreviewBuilder without the child.
typedef _ContextMenuPreviewBuilderChildless = Widget Function(
  BuildContext context,
  Animation<double> animation,
);

// Given a GlobalKey, return the Rect of the corresponding RenderBox's
// paintBounds in global coordinates.
Rect _getRect(GlobalKey globalKey) {
  assert(globalKey.currentContext != null);
  final RenderBox renderBoxContainer = globalKey.currentContext.findRenderObject() as RenderBox;
  final Offset containerOffset = renderBoxContainer.localToGlobal(
    renderBoxContainer.paintBounds.topLeft,
  );
  return containerOffset & renderBoxContainer.paintBounds.size;
}

// The context menu arranges itself slightly differently based on the location
// on the screen of [CupertinoContextMenu.child] before the
// [CupertinoContextMenu] opens.
enum _ContextMenuLocation {
  center,
  left,
  right,
}

/// A full-screen modal route that opens when the [child] is long-pressed.
///
/// When open, the [CupertinoContextMenu] shows the child, or the widget returned
/// by [previewBuilder] if given, in a large full-screen [Overlay] with a list
/// of buttons specified by [actions]. The child/preview is placed in an
/// [Expanded] widget so that it will grow to fill the Overlay if its size is
/// unconstrained.
///
/// When closed, the CupertinoContextMenu simply displays the child as if the
/// CupertinoContextMenu were not there. Sizing and positioning is unaffected.
/// The menu can be closed like other [PopupRoute]s, such as by tapping the
/// background or by calling `Navigator.pop(context)`. Unlike PopupRoute, it can
/// also be closed by swiping downwards.
///
/// The [previewBuilder] parameter is most commonly used to display a slight
/// variation of [child]. See [previewBuilder] for an example of rounding the
/// child's corners and allowing its aspect ratio to expand, similar to the
/// Photos app on iOS.
///
/// {@tool dartpad --template=stateless_widget_material}
///
/// This sample shows a very simple CupertinoContextMenu for an empty red
/// 100x100 Container. Simply long press on it to open.
///
/// ```dart imports
/// import 'package:flutter/cupertino.dart';
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Center(
///       child: Container(
///         width: 100,
///         height: 100,
///         child: CupertinoContextMenu(
///           child: Container(
///             color: Colors.red,
///           ),
///           actions: <Widget>[
///             CupertinoContextMenuAction(
///               child: const Text('Action one'),
///               onPressed: () {
///                 Navigator.pop(context);
///               },
///             ),
///             CupertinoContextMenuAction(
///               child: const Text('Action two'),
///               onPressed: () {
///                 Navigator.pop(context);
///               },
///             ),
///           ],
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Apple's HIG for Context Menus](https://developer.apple.com/design/human-interface-guidelines/ios/controls/context-menus/)
class CupertinoContextMenu extends StatefulWidget {
  /// Create a context menu.
  ///
  /// [actions] is required and cannot be null or empty.
  ///
  /// [child] is required and cannot be null.
  CupertinoContextMenu({
    Key key,
    @required this.actions,
    @required this.child,
    this.previewBuilder,
  }) : assert(actions != null && actions.isNotEmpty),
       assert(child != null),
       super(key: key);

  /// The widget that can be "opened" with the [CupertinoContextMenu].
  ///
  /// When the [CupertinoContextMenu] is long-pressed, the menu will open and
  /// this widget (or the widget returned by [previewBuilder], if provided) will
  /// be moved to the new route and placed inside of an [Expanded] widget. This
  /// allows the child to resize to fit in its place in the new route, if it
  /// doesn't size itself.
  ///
  /// When the [CupertinoContextMenu] is "closed", this widget acts like a
  /// [Container], i.e. it does not constrain its child's size or affect its
  /// position.
  ///
  /// This parameter cannot be null.
  final Widget child;

  /// The actions that are shown in the menu.
  ///
  /// These actions are typically [CupertinoContextMenuAction]s.
  ///
  /// This parameter cannot be null or empty.
  final List<Widget> actions;

  /// A function that returns an alternative widget to show when the
  /// [CupertinoContextMenu] is open.
  ///
  /// If not specified, [child] will be shown.
  ///
  /// The preview is often used to show a slight variation of the [child]. For
  /// example, the child could be given rounded corners in the preview but have
  /// sharp corners when in the page.
  ///
  /// In addition to the current [BuildContext], the function is also called
  /// with an [Animation] and the [child]. The animation goes from 0 to 1 when
  /// the CupertinoContextMenu opens, and from 1 to 0 when it closes, and it can
  /// be used to animate the preview in sync with this opening and closing. The
  /// child parameter provides access to the child displayed when the
  /// CupertinoContextMenu is closed.
  ///
  /// {@tool snippet}
  ///
  /// Below is an example of using `previewBuilder` to show an image tile that's
  /// similar to each tile in the iOS iPhoto app's context menu. Several of
  /// these could be used in a GridView for a similar effect.
  ///
  /// When opened, the child animates to show its full aspect ratio and has
  /// rounded corners. The larger size of the open CupertinoContextMenu allows
  /// the FittedBox to fit the entire image, even when it has a very tall or
  /// wide aspect ratio compared to the square of a GridView, so this animates
  /// into view as the CupertinoContextMenu is opened. The preview is swapped in
  /// right when the open animation begins, which includes the rounded corners.
  ///
  /// ```dart
  /// CupertinoContextMenu(
  ///   child: FittedBox(
  ///     fit: BoxFit.cover,
  ///     child: Image.asset('assets/photo.jpg'),
  ///   ),
  ///   // The FittedBox in the preview here allows the image to animate its
  ///   // aspect ratio when the CupertinoContextMenu is animating its preview
  ///   // widget open and closed.
  ///   previewBuilder: (BuildContext context, Animation<double> animation, Widget child) {
  ///     return FittedBox(
  ///       fit: BoxFit.cover,
  ///       // This ClipRRect rounds the corners of the image when the
  ///       // CupertinoContextMenu is open, even though it's not rounded when
  ///       // it's closed. It uses the given animation to animate the corners
  ///       // in sync with the opening animation.
  ///       child: ClipRRect(
  ///         borderRadius: BorderRadius.circular(64.0 * animation.value),
  ///         child: Image.asset('assets/photo.jpg'),
  ///       ),
  ///     );
  ///   },
  ///   actions: <Widget>[
  ///     CupertinoContextMenuAction(
  ///       child: const Text('Action one'),
  ///       onPressed: () {},
  ///     ),
  ///   ],
  /// ),
  /// ```
  ///
  /// {@end-tool}
  final ContextMenuPreviewBuilder previewBuilder;

  @override
  _CupertinoContextMenuState createState() => _CupertinoContextMenuState();
}

class _CupertinoContextMenuState extends State<CupertinoContextMenu> with TickerProviderStateMixin {
  final GlobalKey _childGlobalKey = GlobalKey();
  bool _childHidden = false;
  // Animates the child while it's opening.
  AnimationController _openController;
  Rect _decoyChildEndRect;
  OverlayEntry _lastOverlayEntry;
  _ContextMenuRoute<void> _route;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      duration: kLongPressTimeout,
      vsync: this,
    );
    _openController.addStatusListener(_onDecoyAnimationStatusChange);
  }

  // Determine the _ContextMenuLocation based on the location of the original
  // child in the screen.
  //
  // The location of the original child is used to determine how to horizontally
  // align the content of the open CupertinoContextMenu. For example, if the
  // child is near the center of the screen, it will also appear in the center
  // of the screen when the menu is open, and the actions will be centered below
  // it.
  _ContextMenuLocation get _contextMenuLocation {
    final Rect childRect = _getRect(_childGlobalKey);
    final double screenWidth = MediaQuery.of(context).size.width;

    final double center = screenWidth / 2;
    final bool centerDividesChild = childRect.left < center
      && childRect.right > center;
    final double distanceFromCenter = (center - childRect.center.dx).abs();
    if (centerDividesChild && distanceFromCenter <= childRect.width / 4) {
      return _ContextMenuLocation.center;
    }

    if (childRect.center.dx > center) {
      return _ContextMenuLocation.right;
    }

    return _ContextMenuLocation.left;
  }

  // Push the new route and open the CupertinoContextMenu overlay.
  void _openContextMenu() {
    setState(() {
      _childHidden = true;
    });

    _route = _ContextMenuRoute<void>(
      actions: widget.actions,
      barrierLabel: 'Dismiss',
      filter: ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ),
      contextMenuLocation: _contextMenuLocation,
      previousChildRect: _decoyChildEndRect,
      builder: (BuildContext context, Animation<double> animation) {
        if (widget.previewBuilder == null) {
          return widget.child;
        }
        return widget.previewBuilder(context, animation, widget.child);
      },
    );
    Navigator.of(context, rootNavigator: true).push<void>(_route);
    _route.animation.addStatusListener(_routeAnimationStatusListener);
  }

  void _onDecoyAnimationStatusChange(AnimationStatus animationStatus) {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
        if (_route == null) {
          setState(() {
            _childHidden = false;
          });
        }
        _lastOverlayEntry?.remove();
        _lastOverlayEntry = null;
        break;

      case AnimationStatus.completed:
        setState(() {
          _childHidden = true;
        });
        _openContextMenu();
        // Keep the decoy on the screen for one extra frame. We have to do this
        // because _ContextMenuRoute renders its first frame offscreen.
        // Otherwise there would be a visible flash when nothing is rendered for
        // one frame.
        SchedulerBinding.instance.addPostFrameCallback((Duration _) {
          _lastOverlayEntry?.remove();
          _lastOverlayEntry = null;
          _openController.reset();
        });
        break;

      default:
        return;
    }
  }

  // Watch for when _ContextMenuRoute is closed and return to the state where
  // the CupertinoContextMenu just behaves as a Container.
  void _routeAnimationStatusListener(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) {
      return;
    }
    setState(() {
      _childHidden = false;
    });
    _route.animation.removeStatusListener(_routeAnimationStatusListener);
    _route = null;
  }

  void _onTap() {
    if (_openController.isAnimating && _openController.value < 0.5) {
      _openController.reverse();
    }
  }

  void _onTapCancel() {
    if (_openController.isAnimating && _openController.value < 0.5) {
      _openController.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_openController.isAnimating && _openController.value < 0.5) {
      _openController.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _childHidden = true;
    });

    final Rect childRect = _getRect(_childGlobalKey);
    _decoyChildEndRect = Rect.fromCenter(
      center: childRect.center,
      width: childRect.width * _kOpenScale,
      height: childRect.height * _kOpenScale,
    );

    // Create a decoy child in an overlay directly on top of the original child.
    // TODO(justinmc): There is a known inconsistency with native here, due to
    // doing the bounce animation using a decoy in the top level Overlay. The
    // decoy will pop on top of the AppBar if the child is partially behind it,
    // such as a top item in a partially scrolled view. However, if we don't use
    // an overlay, then the decoy will appear behind its neighboring widget when
    // it expands. This may be solvable by adding a widget to Scaffold that's
    // underneath the AppBar.
    _lastOverlayEntry = OverlayEntry(
      opaque: false,
      builder: (BuildContext context) {
        return _DecoyChild(
          beginRect: childRect,
          child: widget.child,
          controller: _openController,
          endRect: _decoyChildEndRect,
        );
      },
    );
    Overlay.of(context).insert(_lastOverlayEntry);
    _openController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapCancel: _onTapCancel,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTap: _onTap,
      child: TickerMode(
        enabled: !_childHidden,
        child: Opacity(
          key: _childGlobalKey,
          opacity: _childHidden ? 0.0 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    super.dispose();
  }
}

// A floating copy of the CupertinoContextMenu's child.
//
// When the child is pressed, but before the CupertinoContextMenu opens, it does
// a "bounce" animation where it shrinks and then grows. This is implemented
// by hiding the original child and placing _DecoyChild on top of it in an
// Overlay. The use of an Overlay allows the _DecoyChild to appear on top of
// siblings of the original child.
class _DecoyChild extends StatefulWidget {
  const _DecoyChild({
    Key key,
    this.beginRect,
    this.controller,
    this.endRect,
    this.child,
  }) : super(key: key);

  final Rect beginRect;
  final AnimationController controller;
  final Rect endRect;
  final Widget child;

  @override
  _DecoyChildState createState() => _DecoyChildState();
}

class _DecoyChildState extends State<_DecoyChild> with TickerProviderStateMixin {
  // TODO(justinmc): Dark mode support.
  // See https://github.com/flutter/flutter/issues/43211.
  static const Color _lightModeMaskColor = Color(0xFF888888);
  static const Color _masklessColor = Color(0xFFFFFFFF);

  final GlobalKey _childGlobalKey = GlobalKey();
  Animation<Color> _mask;
  Animation<Rect> _rect;

  @override
  void initState() {
    super.initState();
    // Change the color of the child during the initial part of the decoy bounce
    // animation. The interval was eyeballed from a physical iOS 13.1.2 device.
    _mask = _OnOffAnimation<Color>(
      controller: widget.controller,
      onValue: _lightModeMaskColor,
      offValue: _masklessColor,
      intervalOn: 0.0,
      intervalOff: 0.5,
    );

    final Rect midRect =  widget.beginRect.deflate(
      widget.beginRect.width * (_kOpenScale - 1.0) / 2,
    );
    _rect = TweenSequence<Rect>(<TweenSequenceItem<Rect>>[
      TweenSequenceItem<Rect>(
        tween: RectTween(
          begin: widget.beginRect,
          end: midRect,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 1.0,
      ),
      TweenSequenceItem<Rect>(
        tween: RectTween(
          begin: midRect,
          end: widget.endRect,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 1.0,
      ),
    ]).animate(widget.controller);
    _rect.addListener(_rectListener);
  }

  // Listen to the _rect animation and vibrate when it reaches the halfway point
  // and switches from animating down to up.
  void _rectListener() {
    if (widget.controller.value < 0.5) {
      return;
    }
    HapticFeedback.selectionClick();
    _rect.removeListener(_rectListener);
  }

  @override
  void dispose() {
    _rect.removeListener(_rectListener);
    super.dispose();
  }

  Widget _buildAnimation(BuildContext context, Widget child) {
    final Color color = widget.controller.status == AnimationStatus.reverse
      ? _masklessColor
      : _mask.value;
    return Positioned.fromRect(
      rect: _rect.value,
      // TODO(justinmc): When ShaderMask is supported on web, remove this
      // conditional and use ShaderMask everywhere.
      // https://github.com/flutter/flutter/issues/52967.
      child: kIsWeb
          ? Container(key: _childGlobalKey, child: widget.child)
          : ShaderMask(
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

// The open CupertinoContextMenu modal.
class _ContextMenuRoute<T> extends PopupRoute<T> {
  // Build a _ContextMenuRoute.
  _ContextMenuRoute({
    @required List<Widget> actions,
    @required _ContextMenuLocation contextMenuLocation,
    this.barrierLabel,
    _ContextMenuPreviewBuilderChildless builder,
    ui.ImageFilter filter,
    Rect previousChildRect,
    RouteSettings settings,
  }) : assert(actions != null && actions.isNotEmpty),
       assert(contextMenuLocation != null),
       _actions = actions,
       _builder = builder,
       _contextMenuLocation = contextMenuLocation,
       _previousChildRect = previousChildRect,
       super(
         filter: filter,
         settings: settings,
       );

  // Barrier color for a Cupertino modal barrier.
  static const Color _kModalBarrierColor = Color(0x6604040F);
  // The duration of the transition used when a modal popup is shown. Eyeballed
  // from a physical device running iOS 13.1.2.
  static const Duration _kModalPopupTransitionDuration =
    Duration(milliseconds: 335);

  final List<Widget> _actions;
  final _ContextMenuPreviewBuilderChildless _builder;
  final GlobalKey _childGlobalKey = GlobalKey();
  final _ContextMenuLocation _contextMenuLocation;
  bool _externalOffstage = false;
  bool _internalOffstage = false;
  Orientation _lastOrientation;
  // The Rect of the child at the moment that the CupertinoContextMenu opens.
  final Rect _previousChildRect;
  double _scale = 1.0;
  final GlobalKey _sheetGlobalKey = GlobalKey();

  static final CurveTween _curve = CurveTween(
    curve: Curves.easeOutBack,
  );
  static final CurveTween _curveReverse = CurveTween(
    curve: Curves.easeInBack,
  );
  static final RectTween _rectTween = RectTween();
  static final Animatable<Rect> _rectAnimatable = _rectTween.chain(_curve);
  static final RectTween _rectTweenReverse = RectTween();
  static final Animatable<Rect> _rectAnimatableReverse = _rectTweenReverse
    .chain(
      _curveReverse,
    );
  static final RectTween _sheetRectTween = RectTween();
  final Animatable<Rect> _sheetRectAnimatable = _sheetRectTween.chain(
    _curve,
  );
  final Animatable<Rect> _sheetRectAnimatableReverse = _sheetRectTween.chain(
    _curveReverse,
  );
  static final Tween<double> _sheetScaleTween = Tween<double>();
  static final Animatable<double> _sheetScaleAnimatable = _sheetScaleTween
    .chain(
      _curve,
    );
  static final Animatable<double> _sheetScaleAnimatableReverse =
    _sheetScaleTween.chain(
      _curveReverse,
    );
  final Tween<double> _opacityTween = Tween<double>(begin: 0.0, end: 1.0);
  Animation<double> _sheetOpacity;

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

  // Get the alignment for the _ContextMenuSheet's Transform.scale based on the
  // contextMenuLocation.
  static AlignmentDirectional getSheetAlignment(_ContextMenuLocation contextMenuLocation) {
    switch (contextMenuLocation) {
      case _ContextMenuLocation.center:
        return AlignmentDirectional.topCenter;
      case _ContextMenuLocation.right:
        return AlignmentDirectional.topEnd;
      default:
        return AlignmentDirectional.topStart;
    }
  }

  // The place to start the sheetRect animation from.
  static Rect _getSheetRectBegin(Orientation orientation, _ContextMenuLocation contextMenuLocation, Rect childRect, Rect sheetRect) {
    switch (contextMenuLocation) {
      case _ContextMenuLocation.center:
        final Offset target = orientation == Orientation.portrait
          ? childRect.bottomCenter
          : childRect.topCenter;
        final Offset centered = target - Offset(sheetRect.width / 2, 0.0);
        return centered & sheetRect.size;
      case _ContextMenuLocation.right:
        final Offset target = orientation == Orientation.portrait
          ? childRect.bottomRight
          : childRect.topRight;
        return (target - Offset(sheetRect.width, 0.0)) & sheetRect.size;
      default:
        final Offset target = orientation == Orientation.portrait
          ? childRect.bottomLeft
          : childRect.topLeft;
        return target & sheetRect.size;
    }
  }

  void _onDismiss(BuildContext context, double scale, double opacity) {
    _scale = scale;
    _opacityTween.end = opacity;
    _sheetOpacity = _opacityTween.animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.9, 1.0),
    ));
    Navigator.of(context).pop();
  }

  // Take measurements on the child and _ContextMenuSheet and update the
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
      _contextMenuLocation,
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
    final Animation<double> animation = super.createAnimation();
    _sheetOpacity = _opacityTween.animate(CurvedAnimation(
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
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        _lastOrientation = orientation;

        // While the animation is running, render everything in a Stack so that
        // they're movable.
        if (!animation.isCompleted) {
          final bool reverse = animation.status == AnimationStatus.reverse;
          final Rect rect = reverse
            ? _rectAnimatableReverse.evaluate(animation)
            : _rectAnimatable.evaluate(animation);
          final Rect sheetRect = reverse
            ? _sheetRectAnimatableReverse.evaluate(animation)
            : _sheetRectAnimatable.evaluate(animation);
          final double sheetScale = reverse
            ? _sheetScaleAnimatableReverse.evaluate(animation)
            : _sheetScaleAnimatable.evaluate(animation);
          return Stack(
            children: <Widget>[
              Positioned.fromRect(
                rect: sheetRect,
                child: Opacity(
                  opacity: _sheetOpacity.value,
                  child: Transform.scale(
                    alignment: getSheetAlignment(_contextMenuLocation),
                    scale: sheetScale,
                    child: _ContextMenuSheet(
                      key: _sheetGlobalKey,
                      actions: _actions,
                      contextMenuLocation: _contextMenuLocation,
                      orientation: orientation,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: _childGlobalKey,
                rect: rect,
                child: _builder(context, animation),
              ),
            ],
          );
        }

        // When the animation is done, just render everything in a static layout
        // in the final position.
        return _ContextMenuRouteStatic(
          actions: _actions,
          child: _builder(context, animation),
          childGlobalKey: _childGlobalKey,
          contextMenuLocation: _contextMenuLocation,
          onDismiss: _onDismiss,
          orientation: orientation,
          sheetGlobalKey: _sheetGlobalKey,
        );
      },
    );
  }
}

// The final state of the _ContextMenuRoute after animating in and before
// animating out.
class _ContextMenuRouteStatic extends StatefulWidget {
  const _ContextMenuRouteStatic({
    Key key,
    this.actions,
    @required this.child,
    this.childGlobalKey,
    @required this.contextMenuLocation,
    this.onDismiss,
    @required this.orientation,
    this.sheetGlobalKey,
  }) : assert(contextMenuLocation != null),
       assert(orientation != null),
       super(key: key);

  final List<Widget> actions;
  final Widget child;
  final GlobalKey childGlobalKey;
  final _ContextMenuLocation contextMenuLocation;
  final _DismissCallback onDismiss;
  final Orientation orientation;
  final GlobalKey sheetGlobalKey;

  @override
  _ContextMenuRouteStaticState createState() => _ContextMenuRouteStaticState();
}

class _ContextMenuRouteStaticState extends State<_ContextMenuRouteStatic> with TickerProviderStateMixin {
  // The child is scaled down as it is dragged down until it hits this minimum
  // value.
  static const double _kMinScale = 0.8;
  // The CupertinoContextMenuSheet disappears at this scale.
  static const double _kSheetScaleThreshold = 0.9;
  static const double _kPadding = 20.0;
  static const double _kDamping = 400.0;
  static const Duration _kMoveControllerDuration = Duration(milliseconds: 600);

  Offset _dragOffset;
  double _lastScale = 1.0;
  AnimationController _moveController;
  AnimationController _sheetController;
  Animation<Offset> _moveAnimation;
  Animation<double> _sheetScaleAnimation;
  Animation<double> _sheetOpacityAnimation;

  // The scale of the child changes as a function of the distance it is dragged.
  static double _getScale(Orientation orientation, double maxDragDistance, double dy) {
    final double dyDirectional = dy <= 0.0 ? dy : -dy;
    return math.max(
      _kMinScale,
      (maxDragDistance + dyDirectional) / maxDragDistance,
    );
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

    // Reset the duration back to its original value.
    _moveController.duration = _kMoveControllerDuration;

    _moveController.removeStatusListener(_flingStatusListener);
    // If it was a fling back to the start, it has reset itself, and it should
    // not be dismissed.
    if (_moveAnimation.value.dy == 0.0) {
      return;
    }
    widget.onDismiss(context, _lastScale, _sheetOpacityAnimation.value);
  }

  Alignment _getChildAlignment(Orientation orientation, _ContextMenuLocation contextMenuLocation) {
    switch (contextMenuLocation) {
      case _ContextMenuLocation.center:
        return orientation == Orientation.portrait
          ? Alignment.bottomCenter
          : Alignment.topRight;
      case _ContextMenuLocation.right:
        return orientation == Orientation.portrait
          ? Alignment.bottomCenter
          : Alignment.topLeft;
      default:
        return orientation == Orientation.portrait
          ? Alignment.bottomCenter
          : Alignment.topRight;
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
          endX.clamp(-_kPadding, _kPadding) as double,
          endY,
        ),
      ).animate(
        CurvedAnimation(
          parent: _moveController,
          curve: Curves.elasticIn,
        ),
      );

      // Fade the _ContextMenuSheet out or in, if needed.
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

  // The order and alignment of the _ContextMenuSheet and the child depend on
  // both the orientation of the screen as well as the position on the screen of
  // the original child.
  List<Widget> _getChildren(Orientation orientation, _ContextMenuLocation contextMenuLocation) {
    final Expanded child = Expanded(
      child: Align(
        alignment: _getChildAlignment(
          widget.orientation,
          widget.contextMenuLocation,
        ),
        child: AnimatedBuilder(
          animation: _moveController,
          builder: _buildChildAnimation,
          child: widget.child,
        ),
      ),
    );
    const SizedBox spacer = SizedBox(
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
          contextMenuLocation: widget.contextMenuLocation,
          orientation: widget.orientation,
        ),
      ),
    );

    switch (contextMenuLocation) {
      case _ContextMenuLocation.center:
        return <Widget>[child, spacer, sheet];
      case _ContextMenuLocation.right:
        return orientation == Orientation.portrait
          ? <Widget>[child, spacer, sheet]
          : <Widget>[sheet, spacer, child];
      default:
        return <Widget>[child, spacer, sheet];
    }
  }

  // Build the animation for the _ContextMenuSheet.
  Widget _buildSheetAnimation(BuildContext context, Widget child) {
    return Transform.scale(
      alignment: _ContextMenuRoute.getSheetAlignment(widget.contextMenuLocation),
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

  // Build the animation for the overall draggable dismissible content.
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
      duration: _kMoveControllerDuration,
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
  void dispose() {
    _moveController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _getChildren(
      widget.orientation,
      widget.contextMenuLocation,
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
              child: widget.orientation == Orientation.portrait
                ? Column(
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
}

// The menu that displays when CupertinoContextMenu is open. It consists of a
// list of actions that are typically CupertinoContextMenuActions.
class _ContextMenuSheet extends StatelessWidget {
  _ContextMenuSheet({
    Key key,
    @required this.actions,
    @required _ContextMenuLocation contextMenuLocation,
    @required Orientation orientation,
  }) : assert(actions != null && actions.isNotEmpty),
       assert(contextMenuLocation != null),
       assert(orientation != null),
       _contextMenuLocation = contextMenuLocation,
       _orientation = orientation,
       super(key: key);

  final List<Widget> actions;
  final _ContextMenuLocation _contextMenuLocation;
  final Orientation _orientation;

  // Get the children, whose order depends on orientation and
  // contextMenuLocation.
  List<Widget> get children {
    final Flexible menu = Flexible(
      fit: FlexFit.tight,
      flex: 2,
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actions,
          ),
        ),
      ),
    );

    switch (_contextMenuLocation) {
      case _ContextMenuLocation.center:
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
      case _ContextMenuLocation.right:
        return <Widget>[
          const Spacer(
            flex: 1,
          ),
          menu,
        ];
      default:
        return <Widget>[
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

// An animation that switches between two colors.
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
