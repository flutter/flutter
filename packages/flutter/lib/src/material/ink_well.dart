// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'feedback.dart';
import 'ink_highlight.dart';
import 'ink_splash.dart';
import 'material.dart';
import 'theme.dart';

/// An area of a [Material] that responds to touch. Has a configurable shape and
/// can be configured to clip splashes that extend outside its bounds or not.
///
/// For a variant of this widget that is specialized for rectangular areas that
/// always clip splashes, see [InkWell].
///
/// An [InkResponse] widget does two things when responding to a tap:
///
///  * It starts to animate a _highlight_. The shape of the highlight is
///    determined by [highlightShape]. If it is a [BoxShape.circle], the
///    default, then the highlight is a circle of fixed size centered in the
///    [InkResponse]. If it is [BoxShape.rectangle], then the highlight is a box
///    the size of the [InkResponse] itself, unless [getRectCallback] is
///    provided, in which case that callback defines the rectangle. The color of
///    the highlight is set by [highlightColor].
///
///  * Simultaneously, it starts to animate a _splash_. This is a growing circle
///    initially centered on the tap location. If this is a [containedInkWell],
///    the splash grows to the [radius] while remaining centered at the tap
///    location. Otherwise, the splash migrates to the center of the box as it
///    grows.
///
/// The following two diagrams show how [InkResponse] looks when tapped if the
/// [highlightShape] is [BoxShape.circle] (the default) and [containedInkWell]
/// is false (also the default).
///
/// The first diagram shows how it looks if the [InkResponse] is relatively
/// large:
///
/// ![The highlight is a disc centered in the box, smaller than the child widget.](https://flutter.github.io/assets-for-api-docs/material/ink_response_large.png)
///
/// The second diagram shows how it looks if the [InkResponse] is small:
///
/// ![The highlight is a disc overflowing the box, centered on the child.](https://flutter.github.io/assets-for-api-docs/material/ink_response_small.png)
///
/// The main thing to notice from these diagrams is that the splashes happily
/// exceed the bounds of the widget (because [containedInkWell] is false).
///
/// The following diagram shows the effect when the [InkResponse] has a
/// [highlightShape] of [BoxShape.rectangle] with [containedInkWell] set to
/// true. These are the values used by [InkWell].
///
/// ![The highlight is a rectangle the size of the box.](https://flutter.github.io/assets-for-api-docs/material/ink_well.png)
///
/// The [InkResponse] widget must have a [Material] widget as an ancestor. The
/// [Material] widget is where the ink reactions are actually painted. This
/// matches the material design premise wherein the [Material] is what is
/// actually reacting to touches by spreading ink.
///
/// If a Widget uses this class directly, it should include the following line
/// at the top of its build function to call [debugCheckHasMaterial]:
///
/// ```dart
/// assert(debugCheckHasMaterial(context));
/// ```
/// The parameter [enableFeedback] must not be `null`.
///
/// See also:
///
///  * [GestureDetector], for listening for gestures without ink splashes.
///  * [RaisedButton] and [FlatButton], two kinds of buttons in material design.
///  * [IconButton], which combines [InkResponse] with an [Icon].
class InkResponse extends StatefulWidget {
  /// Creates an area of a [Material] that responds to touch.
  ///
  /// Must have an ancestor [Material] widget in which to cause ink reactions.
  const InkResponse({
    Key key,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.containedInkWell: false,
    this.highlightShape: BoxShape.circle,
    this.radius,
    this.borderRadius: BorderRadius.zero,
    this.highlightColor,
    this.splashColor,
    this.enableFeedback: true,
  }) : assert(enableFeedback != null), super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when the user taps this part of the material.
  final GestureTapCallback onTap;

  /// Called when the user double taps this part of the material.
  final GestureTapCallback onDoubleTap;

  /// Called when the user long-presses on this part of the material.
  final GestureLongPressCallback onLongPress;

  /// Called when this part of the material either becomes highlighted or stops
  /// being highlighted.
  ///
  /// The value passed to the callback is true if this part of the material has
  /// become highlighted and false if this part of the material has stopped
  /// being highlighted.
  final ValueChanged<bool> onHighlightChanged;

  /// Whether this ink response should be clipped its bounds.
  ///
  /// This flag also controls whether the splash migrates to the center of the
  /// [InkResponse] or not. If [containedInkWell] is true, the splash remains
  /// centered around the tap location. If it is false, the splash migrates to
  /// the center of the [InkResponse] as it grows.
  ///
  /// See also:
  ///
  ///  * [highlightShape], which determines the shape of the highlight.
  ///  * [borderRadius], which controls the corners when the box is a rectangle.
  ///  * [getRectCallback], which controls the size and position of the box when
  ///    it is a rectangle.
  final bool containedInkWell;

  /// The shape (e.g., circle, rectangle) to use for the highlight drawn around
  /// this part of the material.
  ///
  /// If the shape is [BoxShape.circle], then the highlight is centered on the
  /// [InkResponse]. If the shape is [BoxShape.rectangle], then the highlight
  /// fills the [InkResponse], or the rectangle provided by [getRectCallback] if
  /// the callback is specified.
  ///
  /// See also:
  ///
  ///  * [containedInkWell], which controls clipping behavior.
  ///  * [borderRadius], which controls the corners when the box is a rectangle.
  ///  * [highlightColor], the color of the highlight.
  ///  * [getRectCallback], which controls the size and position of the box when
  ///    it is a rectangle.
  final BoxShape highlightShape;

  /// The radius of the ink splash.
  ///
  /// Splashes grow up to this size. By default, this size is determined from
  /// the size of the rectangle provided by [getRectCallback], or the size of
  /// the [InkResponse] itself.
  ///
  /// See also:
  ///
  ///  * [splashColor], the color of the splash.
  final double radius;

  /// The clipping radius of the containing rect.
  final BorderRadius borderRadius;

  /// The highlight color of the ink response. If this property is null then the
  /// highlight color of the theme, [ThemeData.highlightColor], will be used.
  ///
  /// See also:
  ///
  ///  * [highlightShape], the shape of the highlight.
  ///  * [splashColor], the color of the splash.
  final Color highlightColor;

  /// The splash color of the ink response. If this property is null then the
  /// splash color of the theme, [ThemeData.splashColor], will be used.
  ///
  /// See also:
  ///
  ///  * [radius], the (maximum) size of the ink splash.
  ///  * [highlightColor], the color of the highlight.
  final Color splashColor;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool enableFeedback;

  /// The rectangle to use for the highlight effect and for clipping
  /// the splash effects if [containedInkWell] is true.
  ///
  /// This method is intended to be overridden by descendants that
  /// specialize [InkResponse] for unusual cases. For example,
  /// [TableRowInkWell] implements this method to return the rectangle
  /// corresponding to the row that the widget is in.
  ///
  /// The default behavior returns null, which is equivalent to
  /// returning the referenceBox argument's bounding box (though
  /// slightly more efficient).
  RectCallback getRectCallback(RenderBox referenceBox) => null;

  /// Asserts that the given context satisfies the prerequisites for
  /// this class.
  ///
  /// This method is intended to be overridden by descendants that
  /// specialize [InkResponse] for unusual cases. For example,
  /// [TableRowInkWell] implements this method to verify that the widget is
  /// in a table.
  @mustCallSuper
  bool debugCheckContext(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return true;
  }

  @override
  _InkResponseState<InkResponse> createState() => new _InkResponseState<InkResponse>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    final List<String> gestures = <String>[];
    if (onTap != null)
      gestures.add('tap');
    if (onDoubleTap != null)
      gestures.add('double tap');
    if (onLongPress != null)
      gestures.add('long press');
    description.add(new IterableProperty<String>('gestures', gestures, ifEmpty: '<none>'));
    description.add(new DiagnosticsProperty<bool>('containedInkWell', containedInkWell, level: DiagnosticLevel.fine));
    description.add(new DiagnosticsProperty<BoxShape>(
      'highlightShape',
      highlightShape,
      description: '${containedInkWell ? "clipped to " : ""}$highlightShape',
      showName: false,
    ));
  }
}

class _InkResponseState<T extends InkResponse> extends State<T> with AutomaticKeepAliveClientMixin {
  Set<InkSplash> _splashes;
  InkSplash _currentSplash;
  InkHighlight _lastHighlight;

  @override
  bool get wantKeepAlive => _lastHighlight != null || (_splashes != null && _splashes.isNotEmpty);

  void updateHighlight(bool value) {
    if (value == (_lastHighlight != null && _lastHighlight.active))
      return;
    if (value) {
      if (_lastHighlight == null) {
        final RenderBox referenceBox = context.findRenderObject();
        _lastHighlight = new InkHighlight(
          controller: Material.of(context),
          referenceBox: referenceBox,
          color: widget.highlightColor ?? Theme.of(context).highlightColor,
          shape: widget.highlightShape,
          borderRadius: widget.borderRadius,
          rectCallback: widget.getRectCallback(referenceBox),
          onRemoved: _handleInkHighlightRemoval,
        );
        updateKeepAlive();
      } else {
        _lastHighlight.activate();
      }
    } else {
      _lastHighlight.deactivate();
    }
    assert(value == (_lastHighlight != null && _lastHighlight.active));
    if (widget.onHighlightChanged != null)
      widget.onHighlightChanged(value);
  }

  void _handleInkHighlightRemoval() {
    assert(_lastHighlight != null);
    _lastHighlight = null;
    updateKeepAlive();
  }

  void _handleTapDown(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject();
    final RectCallback rectCallback = widget.getRectCallback(referenceBox);
    InkSplash splash;
    splash = new InkSplash(
      controller: Material.of(context),
      referenceBox: referenceBox,
      position: referenceBox.globalToLocal(details.globalPosition),
      color: widget.splashColor ?? Theme.of(context).splashColor,
      containedInkWell: widget.containedInkWell,
      rectCallback: widget.containedInkWell ? rectCallback : null,
      radius: widget.radius,
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      onRemoved: () {
        if (_splashes != null) {
          assert(_splashes.contains(splash));
          _splashes.remove(splash);
          if (_currentSplash == splash)
            _currentSplash = null;
          updateKeepAlive();
        } // else we're probably in deactivate()
      }
    );
    _splashes ??= new HashSet<InkSplash>();
    _splashes.add(splash);
    _currentSplash = splash;
    updateKeepAlive();
    updateHighlight(true);
  }

  void _handleTap(BuildContext context) {
    _currentSplash?.confirm();
    _currentSplash = null;
    updateHighlight(false);
    if (widget.onTap != null) {
      if (widget.enableFeedback)
        Feedback.forTap(context);
      widget.onTap();
    }
  }

  void _handleTapCancel() {
    _currentSplash?.cancel();
    _currentSplash = null;
    updateHighlight(false);
  }

  void _handleDoubleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (widget.onDoubleTap != null)
      widget.onDoubleTap();
  }

  void _handleLongPress(BuildContext context) {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (widget.onLongPress != null) {
      if (widget.enableFeedback)
        Feedback.forLongPress(context);
      widget.onLongPress();
    }
  }

  @override
  void deactivate() {
    if (_splashes != null) {
      final Set<InkSplash> splashes = _splashes;
      _splashes = null;
      for (InkSplash splash in splashes)
        splash.dispose();
      _currentSplash = null;
    }
    assert(_currentSplash == null);
    _lastHighlight?.dispose();
    _lastHighlight = null;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.debugCheckContext(context));
    super.build(context); // See AutomaticKeepAliveClientMixin.
    final ThemeData themeData = Theme.of(context);
    _lastHighlight?.color = widget.highlightColor ?? themeData.highlightColor;
    _currentSplash?.color = widget.splashColor ?? themeData.splashColor;
    final bool enabled = widget.onTap != null || widget.onDoubleTap != null || widget.onLongPress != null;
    return new GestureDetector(
      onTapDown: enabled ? _handleTapDown : null,
      onTap: enabled ? () => _handleTap(context) : null,
      onTapCancel: enabled ? _handleTapCancel : null,
      onDoubleTap: widget.onDoubleTap != null ? _handleDoubleTap : null,
      onLongPress: widget.onLongPress != null ? () => _handleLongPress(context) : null,
      behavior: HitTestBehavior.opaque,
      child: widget.child
    );
  }

}

/// A rectangular area of a [Material] that responds to touch.
///
/// For a variant of this widget that does not clip splashes, see [InkResponse].
///
/// The following diagram shows how an [InkWell] looks when tapped, when using
/// default values.
///
/// ![The highlight is a rectangle the size of the box.](https://flutter.github.io/assets-for-api-docs/material/ink_well.png)
///
/// The [InkResponse] widget must have a [Material] widget as an ancestor. The
/// [Material] widget is where the ink reactions are actually painted. This
/// matches the material design premise wherein the [Material] is what is
/// actually reacting to touches by spreading ink.
///
/// If a Widget uses this class directly, it should include the following line
/// at the top of its build function to call [debugCheckHasMaterial]:
///
/// ```dart
/// assert(debugCheckHasMaterial(context));
/// ```
///
/// See also:
///
///  * [GestureDetector], for listening for gestures without ink splashes.
///  * [RaisedButton] and [FlatButton], two kinds of buttons in material design.
///  * [InkResponse], a variant of [InkWell] that doesn't force a rectangular
///    shape on the ink reaction.
class InkWell extends InkResponse {
  /// Creates an ink well.
  ///
  /// Must have an ancestor [Material] widget in which to cause ink reactions.
  const InkWell({
    Key key,
    Widget child,
    GestureTapCallback onTap,
    GestureTapCallback onDoubleTap,
    GestureLongPressCallback onLongPress,
    ValueChanged<bool> onHighlightChanged,
    Color highlightColor,
    Color splashColor,
    BorderRadius borderRadius,
    bool enableFeedback: true,
  }) : super(
    key: key,
    child: child,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onHighlightChanged: onHighlightChanged,
    containedInkWell: true,
    highlightShape: BoxShape.rectangle,
    highlightColor: highlightColor,
    splashColor: splashColor,
    borderRadius: borderRadius,
    enableFeedback: enableFeedback,
  );
}
