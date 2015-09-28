// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:sky/material.dart';
import 'package:sky/painting.dart';
import 'package:sky/rendering.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/theme.dart';
import 'package:sky/src/fn3/framework.dart';

export 'package:sky/rendering.dart' show ValueChanged;

const sky.Color _kThumbOffColor = const sky.Color(0xFFFAFAFA);
const sky.Color _kTrackOffColor = const sky.Color(0x42000000);
const double _kSwitchWidth = 35.0;
const double _kThumbRadius = 10.0;
const double _kSwitchHeight = _kThumbRadius * 2.0;
const double _kTrackHeight = 14.0;
const double _kTrackRadius = _kTrackHeight / 2.0;
const double _kTrackWidth =
    _kSwitchWidth - (_kThumbRadius - _kTrackRadius) * 2.0;
const Size _kSwitchSize = const Size(_kSwitchWidth + 2.0, _kSwitchHeight + 2.0);
const double _kReactionRadius = _kSwitchWidth / 2.0;

class Switch extends StatelessComponent {
  Switch({ Key key, this.value, this.onChanged })
      : super(key: key);

  final bool value;
  final ValueChanged onChanged;

  Widget build(BuildContext context) {
    return new _SwitchWrapper(
      value: value,
      thumbColor: Theme.of(context).accentColor,
      onChanged: onChanged
    );
  }
}

class _SwitchWrapper extends LeafRenderObjectWidget {
  _SwitchWrapper({ Key key, this.value, this.thumbColor, this.onChanged })
      : super(key: key);

  final bool value;
  final Color thumbColor;
  final ValueChanged onChanged;

  _RenderSwitch createRenderObject() => new _RenderSwitch(
    value: value,
    thumbColor: thumbColor,
    onChanged: onChanged
  );

  void updateRenderObject(_RenderSwitch renderObject, _SwitchWrapper oldWidget) {
    renderObject.value = value;
    renderObject.thumbColor = thumbColor;
    renderObject.onChanged = onChanged;
  }
}

class _RenderSwitch extends RenderToggleable {
  _RenderSwitch({
    bool value,
    Color thumbColor: _kThumbOffColor,
    ValueChanged onChanged
  }) : _thumbColor = thumbColor,
        super(value: value, onChanged: onChanged, size: _kSwitchSize) {}

  Color _thumbColor;
  Color get thumbColor => _thumbColor;
  void set thumbColor(Color value) {
    if (value == _thumbColor) return;
    _thumbColor = value;
    markNeedsPaint();
  }

  RadialReaction _radialReaction;

  void handleEvent(sky.Event event, BoxHitTestEntry entry) {
    if (event is sky.PointerEvent) {
      if (event.type == 'pointerdown')
        _showRadialReaction(entry.localPosition);
      else if (event.type == 'pointerup')
        _hideRadialReaction();
    }
    super.handleEvent(event, entry);
  }

  void _showRadialReaction(Point startLocation) {
    if (_radialReaction != null)
      return;
    _radialReaction = new RadialReaction(
      center: new Point(_kSwitchSize.width / 2.0, _kSwitchSize.height / 2.0),
      radius: _kReactionRadius,
      startPosition: startLocation)
      ..addListener(markNeedsPaint)
      ..show();
  }

  Future _hideRadialReaction() async {
    if (_radialReaction == null)
      return;
    await _radialReaction.hide();
    _radialReaction = null;
  }

  void paint(PaintingContext context, Offset offset) {
    final PaintingCanvas canvas = context.canvas;
    sky.Color thumbColor = _kThumbOffColor;
    sky.Color trackColor = _kTrackOffColor;
    if (value) {
      thumbColor = _thumbColor;
      trackColor = new sky.Color(_thumbColor.value & 0x80FFFFFF);
    }

    // Draw the track rrect
    sky.Paint paint = new sky.Paint()
      ..color = trackColor
      ..style = sky.PaintingStyle.fill;
    sky.Rect rect = new sky.Rect.fromLTWH(offset.dx,
        offset.dy + _kSwitchHeight / 2.0 - _kTrackHeight / 2.0, _kTrackWidth,
        _kTrackHeight);
    sky.RRect rrect = new sky.RRect()
      ..setRectXY(rect, _kTrackRadius, _kTrackRadius);
    canvas.drawRRect(rrect, paint);

    if (_radialReaction != null)
      _radialReaction.paint(canvas, offset);

    // Draw the raised thumb with a shadow
    paint.color = thumbColor;
    ShadowDrawLooperBuilder builder = new ShadowDrawLooperBuilder();
    for (BoxShadow boxShadow in shadows[1])
      builder.addShadow(boxShadow.offset, boxShadow.color, boxShadow.blur);
    paint.drawLooper = builder.build();

    // The thumb contracts slightly during the animation
    double inset = 2.0 - (position.value - 0.5).abs() * 2.0;
    Point thumbPos = new Point(offset.dx +
            _kTrackRadius +
            position.value * (_kTrackWidth - _kTrackRadius * 2),
        offset.dy + _kSwitchHeight / 2.0);
    canvas.drawCircle(thumbPos, _kThumbRadius - inset, paint);
  }
}
