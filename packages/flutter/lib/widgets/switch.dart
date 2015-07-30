// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/painting/shadows.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/theme/shadows.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';

export 'package:sky/widgets/basic.dart' show ValueChanged;

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

class Switch extends Component {
  Switch({Key key, this.value, this.onChanged}) : super(key: key);

  final bool value;
  final ValueChanged onChanged;

  Widget build() {
    return new _SwitchWrapper(
        value: value,
        onChanged: onChanged,
        thumbColor: Theme.of(this).accentColor);
  }
}

// This wrapper class exists only because Switch needs to be a Component in
// order to get an accent color from a Theme but Components do not know how to
// host RenderObjects.
class _SwitchWrapper extends LeafRenderObjectWrapper {
  _SwitchWrapper({Key key, this.value, this.onChanged, this.thumbColor})
      : super(key: key);

  final bool value;
  final ValueChanged onChanged;
  final Color thumbColor;

  _RenderSwitch get root => super.root;
  _RenderSwitch createNode() => new _RenderSwitch(
      value: value, thumbColor: thumbColor, onChanged: onChanged);

  void syncRenderObject(_SwitchWrapper old) {
    super.syncRenderObject(old);
    root.value = value;
    root.onChanged = onChanged;
    root.thumbColor = thumbColor;
  }
}

class _RenderSwitch extends RenderConstrainedBox {
  _RenderSwitch(
      {bool value, Color thumbColor: _kThumbOffColor, ValueChanged onChanged})
      : _value = value,
        _thumbColor = thumbColor,
        _onChanged = onChanged,
        super(additionalConstraints: new BoxConstraints.tight(_kSwitchSize)) {
    _performance = new AnimationPerformance()
      ..variable = _position
      ..duration = _kCheckDuration
      ..progress = _value ? 1.0 : 0.0
      ..addListener(markNeedsPaint);
  }

  void handleEvent(sky.Event event, BoxHitTestEntry entry) {
    if (event is sky.GestureEvent &&
        event.type == 'gesturetap') _onChanged(!_value);
  }

  bool _value;
  bool get value => _value;

  void set value(bool value) {
    if (value == _value) return;
    _value = value;
    // TODO(abarth): Setting the curve on the position means there's a
    // discontinuity when we reverse the timeline.
    if (value) {
      _position.curve = easeIn;
      _performance.play();
    } else {
      _position.curve = easeOut;
      _performance.reverse();
    }
  }

  Color _thumbColor;
  Color get thumbColor  => _thumbColor;

  void set thumbColor(Color value) {
    if (value == _thumbColor) return;
    _thumbColor = value;
    markNeedsPaint();
  }

  ValueChanged _onChanged;
  ValueChanged get onChanged => _onChanged;

  void set onChanged(ValueChanged onChanged) {
    _onChanged = onChanged;
  }

  final AnimatedValue<double> _position =
      new AnimatedValue<double>(0.0, end: 1.0);

  AnimationPerformance _performance;

  void paint(PaintingCanvas canvas, Offset offset) {
    sky.Color thumbColor = _kThumbOffColor;
    sky.Color trackColor = _kTrackOffColor;
    if (_value) {
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

    // Draw the raised thumb with a shadow
    paint.color = thumbColor;
    var builder = new ShadowDrawLooperBuilder();
    for (BoxShadow boxShadow in shadows[1]) builder.addShadow(
        boxShadow.offset, boxShadow.color, boxShadow.blur);
    paint.setDrawLooper(builder.build());

    // The thumb contracts slightly during the animation
    double inset = 2.0 - (_position.value - 0.5).abs() * 2.0;
    Point thumbPos = new Point(offset.dx +
            _kTrackRadius +
            _position.value * (_kTrackWidth - _kTrackRadius * 2),
        offset.dy + _kSwitchHeight / 2.0);
    canvas.drawCircle(thumbPos, _kThumbRadius - inset, paint);
  }
}
