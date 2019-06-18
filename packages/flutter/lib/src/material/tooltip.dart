// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'feedback.dart';
import 'theme.dart';
import 'theme_data.dart';

/// A material design tooltip.
///
/// Tooltips provide text labels that help explain the function of a button or
/// other user interface action. Wrap the button in a [Tooltip] widget to
/// show a label when the widget long pressed (or when the user takes some
/// other appropriate action).
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=EeEfD5fI-5Q}
///
/// Many widgets, such as [IconButton], [FloatingActionButton], and
/// [PopupMenuButton] have a `tooltip` property that, when non-null, causes the
/// widget to include a [Tooltip] in its build.
///
/// Tooltips improve the accessibility of visual widgets by proving a textual
/// representation of the widget, which, for example, can be vocalized by a
/// screen reader.
///
/// See also:
///
///  * <https://material.io/design/components/tooltips.html>
class Tooltip extends StatefulWidget {
  /// Creates a tooltip.
  ///
  /// By default, tooltips prefer to appear below the [child] widget when the
  /// user long presses on the widget.
  ///
  /// All of the arguments except [child] and [decoration] must not be null.
  const Tooltip({
    Key key,
    @required this.message,
    this.height = _defaultTooltipHeight,
    this.padding = _defaultPadding,
    this.verticalOffset = _defaultVerticalOffset,
    this.preferBelow = true,
    this.excludeFromSemantics = false,
    this.decoration,
    this.waitDuration = _defaultWaitDuration,
    this.showDuration = _defaultShowDuration,
    this.child,
  }) : assert(message != null),
       assert(height != null),
       assert(padding != null),
       assert(verticalOffset != null),
       assert(preferBelow != null),
       assert(excludeFromSemantics != null),
       assert(waitDuration != null),
       assert(showDuration != null),
       super(key: key);

  static const Duration _defaultShowDuration = Duration(milliseconds: 1500);
  static const Duration _defaultWaitDuration = Duration(milliseconds: 0);
  static const double _defaultTooltipHeight = 32.0;
  static const double _defaultVerticalOffset = 24.0;
  static const EdgeInsetsGeometry _defaultPadding = EdgeInsets.symmetric(horizontal: 16.0);

  /// The text to display in the tooltip.
  final String message;

  /// They height of the tooltip's [child].
  ///
  /// If the [child] is null, then this is the intrinsic height.
  final double height;

  /// The amount of space by which to inset the child.
  ///
  /// Defaults to 16.0 logical pixels in each direction.
  final EdgeInsetsGeometry padding;

  /// The vertical gap between the widget and the displayed tooltip.
  final double verticalOffset;

  /// Whether the tooltip defaults to being displayed below the widget.
  ///
  /// Defaults to true. If there is insufficient space to display the tooltip in
  /// the preferred direction, the tooltip will be displayed in the opposite
  /// direction.
  final bool preferBelow;

  /// Whether the tooltip's [message] should be excluded from the semantics
  /// tree.
  final bool excludeFromSemantics;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Specifies the tooltip's shape and background color.
  ///
  /// If not specified, defaults to a rounded rectangle with a border radius of
  /// 4.0, and a color derived from the [ThemeData.textTheme] if the
  /// [ThemeData.brightness] is dark, and [ThemeData.primaryTextTheme] if not.
  final Decoration decoration;

  /// The amount of time that a pointer must hover over the widget before it
  /// will show a tooltip.
  ///
  /// Defaults to 0 milliseconds (tooltips show immediately upon hover).
  final Duration waitDuration;

  /// The amount of time that the tooltip will be shown once it has appeared.
  ///
  /// Defaults to 1.5 seconds.
  final Duration showDuration;

  @override
  _TooltipState createState() => _TooltipState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message, showName: false));
    properties.add(DoubleProperty('height', height, defaultValue: _defaultTooltipHeight));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: _defaultPadding));
    properties.add(DoubleProperty('vertical offset', verticalOffset, defaultValue: _defaultVerticalOffset));
    properties.add(FlagProperty('position', value: preferBelow, ifTrue: 'below', ifFalse: 'above', showName: true));
    properties.add(FlagProperty('semantics', value: excludeFromSemantics, ifTrue: 'excluded', showName: true, defaultValue: false));
    properties.add(DiagnosticsProperty<Duration>('wait duration', waitDuration, defaultValue: _defaultWaitDuration));
    properties.add(DiagnosticsProperty<Duration>('show duration', showDuration, defaultValue: _defaultShowDuration));
  }
}

class _TooltipState extends State<Tooltip> with SingleTickerProviderStateMixin {
  static const Duration _fadeInDuration = Duration(milliseconds: 150);
  static const Duration _fadeOutDuration = Duration(milliseconds: 75);

  AnimationController _controller;
  OverlayEntry _entry;
  Timer _hideTimer;
  Timer _showTimer;
  bool _mouseIsConnected;
  bool _longPressActivated = false;

  @override
  void initState() {
    super.initState();
    _mouseIsConnected = RendererBinding.instance.mouseTracker.mouseIsConnected;
    _controller = AnimationController(
      duration: _fadeInDuration,
      reverseDuration: _fadeOutDuration,
      vsync: this,
    )
      ..addStatusListener(_handleStatusChanged);
    // Listen to see when a mouse is added.
    RendererBinding.instance.mouseTracker.addListener(_handleMouseTrackerChange);
    // Listen to global pointer events so that we can hide a tooltip immediately
    // if some other control is clicked on.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  // Forces a rebuild if a mouse has been added or removed.
  void _handleMouseTrackerChange() {
    if (!mounted) {
      return;
    }
    final bool mouseIsConnected = RendererBinding.instance.mouseTracker.mouseIsConnected;
    if (mouseIsConnected != _mouseIsConnected) {
      setState((){
        _mouseIsConnected = mouseIsConnected;
      });
    }
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _hideTooltip(immediately: true);
    }
  }

  void _hideTooltip({ bool immediately = false }) {
    _showTimer?.cancel();
    _showTimer = null;
    if (immediately) {
      _removeEntry();
      return;
    }
    if (_longPressActivated) {
      // Tool tips activated by long press should stay around for 1.5s.
      _hideTimer ??= Timer(widget.showDuration, _controller.reverse);
    } else {
      // Tool tips activated by hover should disappear as soon as the mouse
      // leaves the control.
      _controller.reverse();
    }
    _longPressActivated = false;
  }

  void _showTooltip({ bool immediately = false }) {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (immediately) {
      ensureTooltipVisible();
      return;
    }
    _showTimer ??= Timer(widget.waitDuration, ensureTooltipVisible);
  }

  /// Shows the tooltip if it is not already visible.
  ///
  /// Returns `false` when the tooltip was already visible.
  bool ensureTooltipVisible() {
    _showTimer?.cancel();
    _showTimer = null;
    if (_entry != null) {
      // Stop trying to hide, if we were.
      _hideTimer?.cancel();
      _hideTimer = null;
      _controller.forward();
      return false; // Already visible.
    }
    _createNewEntry();
    _controller.forward();
    return true;
  }

  void _createNewEntry() {
    final RenderBox box = context.findRenderObject();
    final Offset target = box.localToGlobal(box.size.center(Offset.zero));

    // We create this widget outside of the overlay entry's builder to prevent
    // updated values from happening to leak into the overlay when the overlay
    // rebuilds.
    final Widget overlay = _TooltipOverlay(
      message: widget.message,
      height: widget.height,
      padding: widget.padding,
      decoration: widget.decoration,
      animation: CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn,
      ),
      target: target,
      verticalOffset: widget.verticalOffset,
      preferBelow: widget.preferBelow,
    );
    _entry = OverlayEntry(builder: (BuildContext context) => overlay);
    Overlay.of(context, debugRequiredFor: widget).insert(_entry);
    SemanticsService.tooltip(widget.message);
  }

  void _removeEntry() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _showTimer?.cancel();
    _showTimer = null;
    _entry?.remove();
    _entry = null;
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_entry == null) {
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _hideTooltip();
    } else if (event is PointerDownEvent) {
      _hideTooltip(immediately: true);
    }
  }

  @override
  void deactivate() {
    if (_entry != null) {
      _hideTooltip(immediately: true);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    RendererBinding.instance.mouseTracker.removeListener(_handleMouseTrackerChange);
    if (_entry != null)
      _removeEntry();
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    _longPressActivated = true;
    final bool tooltipCreated = ensureTooltipVisible();
    if (tooltipCreated)
      Feedback.forLongPress(context);
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context, debugRequiredFor: widget) != null);
    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _handleLongPress,
      excludeFromSemantics: true,
      child: Semantics(
        label: widget.excludeFromSemantics ? null : widget.message,
        child: widget.child,
      ),
    );

    // Only check for hovering if there is a mouse connected.
    if (_mouseIsConnected) {
      result = Listener(
        onPointerEnter: (PointerEnterEvent event) => _showTooltip(),
        onPointerExit: (PointerExitEvent event) => _hideTooltip(),
        child: result,
      );
    }

    return result;
  }
}

/// A delegate for computing the layout of a tooltip to be displayed above or
/// bellow a target specified in the global coordinate system.
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  ///
  /// The arguments must not be null.
  _TooltipPositionDelegate({
    @required this.target,
    @required this.verticalOffset,
    @required this.preferBelow,
  }) : assert(target != null),
       assert(verticalOffset != null),
       assert(preferBelow != null);

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final double verticalOffset;

  /// Whether the tooltip defaults to being displayed below the widget.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferBelow;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return positionDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
    );
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target
        || verticalOffset != oldDelegate.verticalOffset
        || preferBelow != oldDelegate.preferBelow;
  }
}

class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    Key key,
    this.message,
    this.height,
    this.padding,
    this.decoration,
    this.animation,
    this.target,
    this.verticalOffset,
    this.preferBelow,
  }) : super(key: key);

  final String message;
  final double height;
  final EdgeInsetsGeometry padding;
  final Decoration decoration;
  final Animation<double> animation;
  final Offset target;
  final double verticalOffset;
  final bool preferBelow;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemeData tooltipTheme = ThemeData(
      brightness: Brightness.dark,
      textTheme: theme.brightness == Brightness.dark ? theme.textTheme : theme.primaryTextTheme,
      platform: theme.platform,
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _TooltipPositionDelegate(
            target: target,
            verticalOffset: verticalOffset,
            preferBelow: preferBelow,
          ),
          child: FadeTransition(
            opacity: animation,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Container(
                decoration: decoration ?? BoxDecoration(
                  color: tooltipTheme.backgroundColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                padding: padding,
                child: Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: Text(message, style: tooltipTheme.textTheme.body1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
