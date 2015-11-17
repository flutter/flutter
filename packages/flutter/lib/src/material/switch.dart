// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'radial_reaction.dart';
import 'shadows.dart';
import 'theme.dart';

const Color _kThumbOffColor = const Color(0xFFFAFAFA);
const Color _kTrackOffColor = const Color(0x42000000);
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
  final ValueChanged<bool> onChanged;

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
  final ValueChanged<bool> onChanged;

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
    ValueChanged<bool> onChanged
  }) : _thumbColor = thumbColor,
        super(value: value, onChanged: onChanged, size: _kSwitchSize);

  Color _thumbColor;
  Color get thumbColor => _thumbColor;
  void set thumbColor(Color value) {
    if (value == _thumbColor) return;
    _thumbColor = value;
    markNeedsPaint();
  }

  RadialReaction _radialReaction;

  void handleEvent(InputEvent event, BoxHitTestEntry entry) {
    if (event is PointerInputEvent) {
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
      startPosition: startLocation
    )..addListener(markNeedsPaint)
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
    Color thumbColor = _kThumbOffColor;
    Color trackColor = _kTrackOffColor;
    if (value) {
      thumbColor = _thumbColor;
      trackColor = new Color(_thumbColor.value & 0x80FFFFFF);
    }

    // Draw the track rrect
    Paint paint = new Paint()
      ..color = trackColor
      ..style = ui.PaintingStyle.fill;
    Rect rect = new Rect.fromLTWH(offset.dx,
        offset.dy + _kSwitchHeight / 2.0 - _kTrackHeight / 2.0, _kTrackWidth,
        _kTrackHeight);
    ui.RRect rrect = new ui.RRect.fromRectXY(
        rect, _kTrackRadius, _kTrackRadius);
    canvas.drawRRect(rrect, paint);

    if (_radialReaction != null)
      _radialReaction.paint(canvas, offset);

    // Draw the raised thumb with a shadow
    paint.color = thumbColor;
    ShadowDrawLooperBuilder builder = new ShadowDrawLooperBuilder();
    for (BoxShadow boxShadow in elevationToShadow[1])
      builder.addShadow(boxShadow.offset, boxShadow.color, boxShadow.blurRadius);
    paint.drawLooper = builder.build();

    // The thumb contracts slightly during the animation
    double inset = 2.0 - (position - 0.5).abs() * 2.0;
    Point thumbPos = new Point(offset.dx +
            _kTrackRadius +
            position * (_kTrackWidth - _kTrackRadius * 2),
        offset.dy + _kSwitchHeight / 2.0);
    canvas.drawCircle(thumbPos, _kThumbRadius - inset, paint);
  }
}
