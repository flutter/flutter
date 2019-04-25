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

const Duration _kFadeInDuration = Duration(milliseconds: 150);
const Duration _kFadeOutDuration = Duration(milliseconds: 75);
const Duration _kDefaultShowDuration = Duration(milliseconds: 1500);
const Duration _kDefaultWaitDuration = Duration(milliseconds: 0);

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
    this.height = 32.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.verticalOffset = 24.0,
    this.preferBelow = true,
    this.excludeFromSemantics = false,
    this.decoration,
    this.waitDuration = _kDefaultWaitDuration,
    this.showDuration = _kDefaultShowDuration,
    this.child,
  })  : assert(message != null),
        assert(height != null),
        assert(padding != null),
        assert(verticalOffset != null),
        assert(preferBelow != null),
        assert(excludeFromSemantics != null),
        assert(waitDuration != null),
        assert(showDuration != null),
        super(key: key);

  /// The text to display in the tooltip.
  final String message;

  /// The amount of vertical space the tooltip should occupy (inside its
  /// padding).
  final double height;

  /// The amount of space by which to inset the child.
  ///
  /// Defaults to 16.0 logical pixels in each direction.
  final EdgeInsetsGeometry padding;

  /// The amount of vertical distance between the widget and the displayed
  /// tooltip.
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

  /// Specifies the decoration of the tooltip window.
  ///
  /// If not specified, defaults to a rounded rectangle with a border radius of
  /// 4.0, and a color derived from the text theme.
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
    properties.add(DoubleProperty('vertical offset', verticalOffset));
    properties.add(FlagProperty('position', value: preferBelow, ifTrue: 'below', ifFalse: 'above', showName: true));
    properties.add(DiagnosticsProperty<Duration>('waitDuration', waitDuration, defaultValue: _kDefaultWaitDuration));
    properties.add(DiagnosticsProperty<Duration>('showDuration', showDuration, defaultValue: _kDefaultShowDuration));
  }
}

class _TooltipState extends State<Tooltip> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  OverlayEntry _entry;
  Timer _hideTimer;
  Timer _showTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _kFadeInDuration, vsync: this)
      ..addStatusListener(_handleStatusChanged);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _hideTooltip(immediately: true);
    }
  }

  void _hideTooltip({bool immediately = false}) {
    _showTimer?.cancel();
    _showTimer = null;
    if (immediately) {
      _removeEntry();
      return;
    }
    _hideTimer ??= Timer(widget.showDuration, _controller.reverse);
  }

  void _showTooltip({bool immediately = false}) {
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
        // Add an interval here to make the fade out use a different (shorter)
        // duration than the fade in. If _kFadeOutDuration is made longer than
        // _kFadeInDuration, then the equation below will need to change.
        reverseCurve: Interval(
          0.0,
          _kFadeOutDuration.inMilliseconds / _kFadeInDuration.inMilliseconds,
          curve: Curves.fastOutSlowIn,
        ),
      ),
      target: target,
      verticalOffset: widget.verticalOffset,
      preferBelow: widget.preferBelow,
    );
    _entry = OverlayEntry(builder: (BuildContext context) => overlay);
    Overlay.of(context, debugRequiredFor: widget).insert(_entry);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    SemanticsService.tooltip(widget.message);
  }

  void _removeEntry() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _entry?.remove();
    _entry = null;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
  }

  void _handlePointerEvent(PointerEvent event) {
    assert(_entry != null);
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
    if (_entry != null)
      _removeEntry();
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    final bool tooltipCreated = ensureTooltipVisible();
    if (tooltipCreated)
      Feedback.forLongPress(context);
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context, debugRequiredFor: widget) != null);
    return Listener(
      onPointerEnter: (PointerEnterEvent event) => _showTooltip(),
      onPointerExit: (PointerExitEvent event) => _hideTooltip(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: _handleLongPress,
        excludeFromSemantics: true,
        child: Semantics(
          label: widget.excludeFromSemantics ? null : widget.message,
          child: widget.child,
        ),
      ),
    );
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
  })  : assert(target != null),
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
    final ThemeData darkTheme = ThemeData(
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
                  color: darkTheme.backgroundColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                padding: padding,
                child: Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: Text(message, style: darkTheme.textTheme.body1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
