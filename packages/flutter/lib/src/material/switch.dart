// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'shadows.dart';
import 'theme.dart';
import 'toggleable.dart';

class Switch extends StatelessComponent {
  Switch({ Key key, this.value, this.onChanged })
      : super(key: key);

  final bool value;
  final ValueChanged<bool> onChanged;

  Widget build(BuildContext context) {
    return new _SwitchRenderObjectWidget(
      value: value,
      accentColor: Theme.of(context).accentColor,
      onChanged: onChanged
    );
  }
}

class _SwitchRenderObjectWidget extends LeafRenderObjectWidget {
  _SwitchRenderObjectWidget({
    Key key,
    this.value,
    this.accentColor,
    this.onChanged
  }) : super(key: key);

  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  _RenderSwitch createRenderObject() => new _RenderSwitch(
    value: value,
    accentColor: accentColor,
    onChanged: onChanged
  );

  void updateRenderObject(_RenderSwitch renderObject, _SwitchRenderObjectWidget oldWidget) {
    renderObject.value = value;
    renderObject.accentColor = accentColor;
    renderObject.onChanged = onChanged;
  }
}

const Color _kThumbOffColor = const Color(0xFFFAFAFA);
const Color _kTrackOffColor = const Color(0x42000000);
const double _kTrackHeight = 14.0;
const double _kTrackWidth = 29.0;
const double _kTrackRadius = _kTrackHeight / 2.0;
const double _kThumbRadius = 10.0;
const double _kSwitchWidth = _kTrackWidth - 2 * _kTrackRadius + 2 * kRadialReactionRadius;
const double _kSwitchHeight = 2 * kRadialReactionRadius;
const int _kTrackAlpha = 0x80;

class _RenderSwitch extends RenderToggleable {
  _RenderSwitch({
    bool value,
    Color accentColor,
    ValueChanged<bool> onChanged
  }) : super(
         value: value,
         accentColor: accentColor,
         onChanged: onChanged,
         minRadialReactionRadius: _kThumbRadius,
         size: const Size(_kSwitchWidth, _kSwitchHeight)
       ) {
    _drag = new HorizontalDragGestureRecognizer(router: FlutterBinding.instance.pointerRouter)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
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

  void handleEvent(InputEvent event, BoxHitTestEntry entry) {
    if (event.type == 'pointerdown' && onChanged != null)
      _drag.addPointer(event);
    super.handleEvent(event, entry);
  }

  final BoxPainter _thumbPainter = new BoxPainter(const BoxDecoration());

  void paint(PaintingContext context, Offset offset) {
    final PaintingCanvas canvas = context.canvas;

    Color thumbColor = _kThumbOffColor;
    Color trackColor = _kTrackOffColor;
    if (position.status == PerformanceStatus.forward
        || position.status == PerformanceStatus.completed) {
      thumbColor = accentColor;
      trackColor = accentColor.withAlpha(_kTrackAlpha);
    }

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

    _thumbPainter.decoration = new BoxDecoration(
      backgroundColor: thumbColor,
      shape: Shape.circle,
      boxShadow: elevationToShadow[1]
    );

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
