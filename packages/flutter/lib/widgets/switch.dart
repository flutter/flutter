// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:sky/painting/radial_reaction.dart';
import 'package:sky/painting/shadows.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/theme/shadows.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/framework.dart';
import 'package:sky/rendering/toggleable.dart';

export 'package:sky/rendering/toggleable.dart' show ValueChanged;

const sky.Color _kThumbOffColor = const sky.Color(0xFFFAFAFA);
const sky.Color _kTrackOffColor = const sky.Color(0x42000000);
const double _kSwitchWidth = 35.0;
const double _kThumbRadius = 10.0;
const double _kSwitchHeight = _kThumbRadius * 2.0;
const double _kTrackHeight = 14.0;
const double _kTrackRadius = _kTrackHeight / 2.0;
const double _kTrackWidth =
    _kSwitchWidth - (_kThumbRadius - _kTrackRadius) * 2.0;
const Duration _kCheckDuration = const Duration(milliseconds: 200);
const Size _kSwitchSize = const Size(_kSwitchWidth + 2.0, _kSwitchHeight + 2.0);
const double _kReactionRadius = _kSwitchWidth / 2.0;

class Switch extends LeafRenderObjectWrapper {
  Switch({ Key key, this.value, this.onChanged })
      : super(key: key);

  final bool value;
  final ValueChanged onChanged;

  _RenderSwitch get renderObject => super.renderObject;
  _RenderSwitch createNode() => new _RenderSwitch(
    value: value,
    thumbColor: null,
    onChanged: onChanged
  );

  void syncRenderObject(Switch old) {
    super.syncRenderObject(old);
    renderObject.value = value;
    renderObject.onChanged = onChanged;
    renderObject.thumbColor = Theme.of(this).accentColor;
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

  EventDisposition handleEvent(sky.Event event, BoxHitTestEntry entry) {
    if (event is sky.PointerEvent) {
      if (event.type == 'pointerdown') {
        _showRadialReaction(entry.localPosition);
        return combineEventDispositions(EventDisposition.processed,
                                        super.handleEvent(event, entry));
      }
      if (event.type == 'pointerup') {
        _hideRadialReaction();
        return combineEventDispositions(EventDisposition.processed,
                                        super.handleEvent(event, entry));
      }
    }
    return super.handleEvent(event, entry);
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
    sky.Paint paint = new sky.Paint()..color = trackColor;
    paint.setStyle(sky.PaintingStyle.fill);
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
    var builder = new ShadowDrawLooperBuilder();
    for (BoxShadow boxShadow in shadows[1]) builder.addShadow(
        boxShadow.offset, boxShadow.color, boxShadow.blur);
    paint.setDrawLooper(builder.build());

    // The thumb contracts slightly during the animation
    double inset = 2.0 - (position.value - 0.5).abs() * 2.0;
    Point thumbPos = new Point(offset.dx +
            _kTrackRadius +
            position.value * (_kTrackWidth - _kTrackRadius * 2),
        offset.dy + _kSwitchHeight / 2.0);
    canvas.drawCircle(thumbPos, _kThumbRadius - inset, paint);
  }
}
