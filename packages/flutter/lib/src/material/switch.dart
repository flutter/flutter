// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'shadows.dart';
import 'theme.dart';
import 'toggleable.dart';

/// A material design switch.
///
/// Used to toggle the on/off state of a single setting.
///
/// The switch itself does not maintain any state. Instead, when the state of
/// the switch changes, the widget calls the [onChanged] callback. Most widgets
/// that use a switch will listen for the [onChanged] callback and rebuild the
/// switch with a new [value] to update the visual appearance of the switch.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [CheckBox]
///  * [Radio]
///  * [Slider]
///  * <https://www.google.com/design/spec/components/selection-controls.html#selection-controls-switch>
class Switch extends StatelessWidget {
  /// Creates a material design switch.
  ///
  /// The switch itself does not maintain any state. Instead, when the state of
  /// the switch changes, the widget calls the [onChanged] callback. Most widgets
  /// that use a switch will listen for the [onChanged] callback and rebuild the
  /// switch with a new [value] to update the visual appearance of the switch.
  ///
  /// * [value] determines this switch is on or off.
  /// * [onChanged] is called when the user toggles with switch on or off.
  Switch({
    Key key,
    this.value,
    this.activeColor,
    this.activeThumbDecoration,
    this.inactiveThumbDecoration,
    this.onChanged
  }) : super(key: key);

  /// Whether this switch is on or off.
  final bool value;

  /// The color to use when this switch is on.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color activeColor;

  /// A decoration to use for the thumb of this switch when the switch is on.
  ///
  /// Defaults to a circular piece of material.
  final Decoration activeThumbDecoration;

  /// A decoration to use for the thumb of this switch when the switch is off.
  ///
  /// Defaults to a circular piece of material.
  final Decoration inactiveThumbDecoration;

  /// Called when the user toggles with switch on or off.
  ///
  /// The switch passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the switch with the new
  /// value.
  ///
  /// If null, the switch will be displayed as disabled.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    final bool isDark = themeData.brightness == ThemeBrightness.dark;

    Color activeThumbColor = activeColor ?? themeData.accentColor;
    Color activeTrackColor = activeThumbColor.withAlpha(0x80);

    Color inactiveThumbColor;
    Color inactiveTrackColor;
    if (onChanged != null) {
      inactiveThumbColor = isDark ? Colors.grey[400] : Colors.grey[50];
      inactiveTrackColor = isDark ? Colors.white30 : Colors.black26;
    } else {
      inactiveThumbColor = isDark ? Colors.grey[800] : Colors.grey[400];
      inactiveTrackColor = isDark ? Colors.white10 : Colors.black12;
    }

    return new _SwitchRenderObjectWidget(
      value: value,
      activeColor: activeThumbColor,
      inactiveColor: inactiveThumbColor,
      activeThumbDecoration: activeThumbDecoration,
      inactiveThumbDecoration: inactiveThumbDecoration,
      activeTrackColor: activeTrackColor,
      inactiveTrackColor: inactiveTrackColor,
      onChanged: onChanged
    );
  }
}

class _SwitchRenderObjectWidget extends LeafRenderObjectWidget {
  _SwitchRenderObjectWidget({
    Key key,
    this.value,
    this.activeColor,
    this.inactiveColor,
    this.activeThumbDecoration,
    this.inactiveThumbDecoration,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.onChanged
  }) : super(key: key);

  final bool value;
  final Color activeColor;
  final Color inactiveColor;
  final Decoration activeThumbDecoration;
  final Decoration inactiveThumbDecoration;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final ValueChanged<bool> onChanged;

  @override
  _RenderSwitch createRenderObject(BuildContext context) => new _RenderSwitch(
    value: value,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    activeThumbDecoration: activeThumbDecoration,
    inactiveThumbDecoration: inactiveThumbDecoration,
    activeTrackColor: activeTrackColor,
    inactiveTrackColor: inactiveTrackColor,
    onChanged: onChanged
  );

  @override
  void updateRenderObject(BuildContext context, _RenderSwitch renderObject) {
    renderObject
      ..value = value
      ..activeColor = activeColor
      ..inactiveColor = inactiveColor
      ..activeThumbDecoration = activeThumbDecoration
      ..inactiveThumbDecoration = inactiveThumbDecoration
      ..activeTrackColor = activeTrackColor
      ..inactiveTrackColor = inactiveTrackColor
      ..onChanged = onChanged;
  }
}

const double _kTrackHeight = 14.0;
const double _kTrackWidth = 29.0;
const double _kTrackRadius = _kTrackHeight / 2.0;
const double _kThumbRadius = 10.0;
const double _kSwitchWidth = _kTrackWidth - 2 * _kTrackRadius + 2 * kRadialReactionRadius;
const double _kSwitchHeight = 2 * kRadialReactionRadius;

class _RenderSwitch extends RenderToggleable {
  _RenderSwitch({
    bool value,
    Color activeColor,
    Color inactiveColor,
    Decoration activeThumbDecoration,
    Decoration inactiveThumbDecoration,
    Color activeTrackColor,
    Color inactiveTrackColor,
    ValueChanged<bool> onChanged
  }) : _activeThumbDecoration = activeThumbDecoration,
       _inactiveThumbDecoration = inactiveThumbDecoration,
       _activeTrackColor = activeTrackColor,
       _inactiveTrackColor = inactiveTrackColor,
       super(
         value: value,
         activeColor: activeColor,
         inactiveColor: inactiveColor,
         onChanged: onChanged,
         size: const Size(_kSwitchWidth, _kSwitchHeight)
       ) {
    _drag = new HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
  }

  Decoration get activeThumbDecoration => _activeThumbDecoration;
  Decoration _activeThumbDecoration;
  void set activeThumbDecoration(Decoration value) {
    if (value == _activeThumbDecoration)
      return;
    _activeThumbDecoration = value;
    markNeedsPaint();
  }

  Decoration get inactiveThumbDecoration => _inactiveThumbDecoration;
  Decoration _inactiveThumbDecoration;
  void set inactiveThumbDecoration(Decoration value) {
    if (value == _inactiveThumbDecoration)
      return;
    _inactiveThumbDecoration = value;
    markNeedsPaint();
  }

  Color get activeTrackColor => _activeTrackColor;
  Color _activeTrackColor;
  void set activeTrackColor(Color value) {
    assert(value != null);
    if (value == _activeTrackColor)
      return;
    _activeTrackColor = value;
    markNeedsPaint();
  }

  Color get inactiveTrackColor => _inactiveTrackColor;
  Color _inactiveTrackColor;
  void set inactiveTrackColor(Color value) {
    assert(value != null);
    if (value == _inactiveTrackColor)
      return;
    _inactiveTrackColor = value;
    markNeedsPaint();
  }

  double get _trackInnerLength => size.width - 2.0 * kRadialReactionRadius;

  HorizontalDragGestureRecognizer _drag;

  void _handleDragStart(Point globalPosition) {
    if (onChanged != null)
      reactionController.forward();
  }

  void _handleDragUpdate(double delta) {
    if (onChanged != null) {
      position
        ..curve = null
        ..reverseCurve = null;
      positionController.value += delta / _trackInnerLength;
    }
  }

  void _handleDragEnd(Velocity velocity) {
    if (position.value >= 0.5)
      positionController.forward();
    else
      positionController.reverse();
    reactionController.reverse();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && onChanged != null)
      _drag.addPointer(event);
    super.handleEvent(event, entry);
  }

  Color _cachedThumbColor;
  BoxPainter _cachedThumbPainter;

  BoxDecoration _createDefaultThumbDecoration(Color color) {
    return new BoxDecoration(
      backgroundColor: color,
      shape: BoxShape.circle,
      boxShadow: kElevationToShadow[1]
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final bool isActive = onChanged != null;
    final double currentPosition = position.value;

    Color trackColor = isActive ? Color.lerp(inactiveTrackColor, activeTrackColor, currentPosition) : inactiveTrackColor;

    // Paint the track
    Paint paint = new Paint()
      ..color = trackColor;
    double trackHorizontalPadding = kRadialReactionRadius - _kTrackRadius;
    Rect trackRect = new Rect.fromLTWH(
      offset.dx + trackHorizontalPadding,
      offset.dy + (size.height - _kTrackHeight) / 2.0,
      size.width - 2.0 * trackHorizontalPadding,
      _kTrackHeight
    );
    RRect trackRRect = new RRect.fromRectXY(trackRect, _kTrackRadius, _kTrackRadius);
    canvas.drawRRect(trackRRect, paint);

    Point thumbPosition = new Point(
      kRadialReactionRadius + currentPosition * _trackInnerLength,
      size.height / 2.0
    );

    paintRadialReaction(canvas, offset, thumbPosition);

    BoxPainter thumbPainter;
    if (_inactiveThumbDecoration == null && _activeThumbDecoration == null) {
      Color thumbColor = isActive ? Color.lerp(inactiveColor, activeColor, currentPosition) : inactiveColor;
      if (thumbColor != _cachedThumbColor || _cachedThumbPainter == null) {
        _cachedThumbColor = thumbColor;
        _cachedThumbPainter = _createDefaultThumbDecoration(thumbColor).createBoxPainter();
      }
      thumbPainter = _cachedThumbPainter;
    } else {
      Decoration startDecoration = _inactiveThumbDecoration ?? _createDefaultThumbDecoration(inactiveColor);
      Decoration endDecoration = _activeThumbDecoration ?? _createDefaultThumbDecoration(isActive ? activeTrackColor : inactiveColor);
      thumbPainter = Decoration.lerp(startDecoration, endDecoration, currentPosition).createBoxPainter();
    }

    // The thumb contracts slightly during the animation
    double inset = 2.0 - (currentPosition - 0.5).abs() * 2.0;
    double radius = _kThumbRadius - inset;
    Rect thumbRect = new Rect.fromLTRB(thumbPosition.x + offset.dx - radius,
                                       thumbPosition.y + offset.dy - radius,
                                       thumbPosition.x + offset.dx + radius,
                                       thumbPosition.y + offset.dy + radius);
    thumbPainter.paint(canvas, thumbRect);
  }
}
