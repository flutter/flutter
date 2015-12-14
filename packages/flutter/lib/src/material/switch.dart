// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'shadows.dart';
import 'theme.dart';
import 'toggleable.dart';

class Switch extends StatelessComponent {
  Switch({ Key key, this.value, this.activeColor, this.onChanged })
      : super(key: key);

  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    final isDark = themeData.brightness == ThemeBrightness.dark;

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
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.onChanged
  }) : super(key: key);

  final bool value;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final ValueChanged<bool> onChanged;

  _RenderSwitch createRenderObject() => new _RenderSwitch(
    value: value,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    activeTrackColor: activeTrackColor,
    inactiveTrackColor: inactiveTrackColor,
    onChanged: onChanged
  );

  void updateRenderObject(_RenderSwitch renderObject, _SwitchRenderObjectWidget oldWidget) {
    renderObject.value = value;
    renderObject.activeColor = activeColor;
    renderObject.inactiveColor = inactiveColor;
    renderObject.activeTrackColor = activeTrackColor;
    renderObject.inactiveTrackColor = inactiveTrackColor;
    renderObject.onChanged = onChanged;
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
    Color activeTrackColor,
    Color inactiveTrackColor,
    ValueChanged<bool> onChanged
  }) : super(
     value: value,
     activeColor: activeColor,
     inactiveColor: inactiveColor,
     onChanged: onChanged,
     minRadialReactionRadius: _kThumbRadius,
     size: const Size(_kSwitchWidth, _kSwitchHeight)
   ) {
    _activeTrackColor = activeTrackColor;
    _inactiveTrackColor = inactiveTrackColor;
    _drag = new HorizontalDragGestureRecognizer(router: Gesturer.instance.pointerRouter, gestureArena: Gesturer.instance.gestureArena)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
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
      reaction.forward();
  }

  void _handleDragUpdate(double delta) {
    if (onChanged != null) {
      position.variable
        ..curve = null
        ..reverseCurve = null;
      position.progress += delta / _trackInnerLength;
    }
  }

  void _handleDragEnd(Offset velocity) {
    if (position.progress >= 0.5)
      position.forward();
    else
      position.reverse();
    reaction.reverse();
  }

  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && onChanged != null)
      _drag.addPointer(event);
    super.handleEvent(event, entry);
  }

  Color _cachedThumbColor;
  BoxPainter _thumbPainter;

  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final bool isActive = onChanged != null;

    Color thumbColor = isActive ? Color.lerp(inactiveColor, activeColor, position.progress) : inactiveColor;
    Color trackColor = isActive ? Color.lerp(inactiveTrackColor, activeTrackColor, position.progress) : inactiveTrackColor;

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
    ui.RRect trackRRect = new ui.RRect.fromRectXY(
        trackRect, _kTrackRadius, _kTrackRadius);
    canvas.drawRRect(trackRRect, paint);

    Offset thumbOffset = new Offset(
      offset.dx + kRadialReactionRadius + position.value * _trackInnerLength,
      offset.dy + size.height / 2.0);

    paintRadialReaction(canvas, thumbOffset);

    if (_cachedThumbColor != thumbColor) {
      _thumbPainter = new BoxDecoration(
        backgroundColor: thumbColor,
        shape: BoxShape.circle,
        boxShadow: elevationToShadow[1]
      ).createBoxPainter();
      _cachedThumbColor = thumbColor;
    }

    // The thumb contracts slightly during the animation
    double inset = 2.0 - (position.value - 0.5).abs() * 2.0;
    double radius = _kThumbRadius - inset;
    Rect thumbRect = new Rect.fromLTRB(thumbOffset.dx - radius,
                                       thumbOffset.dy - radius,
                                       thumbOffset.dx + radius,
                                       thumbOffset.dy + radius);
    _thumbPainter.paint(canvas, thumbRect);
  }
}
