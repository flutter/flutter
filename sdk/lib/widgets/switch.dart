// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/theme2/colors.dart' as colors;
import 'package:sky/theme2/shadows.dart';

import '../painting/shadows.dart';
import '../rendering/box.dart';
import 'basic.dart';
import 'toggleable.dart';
export 'toggleable.dart' show ValueChanged;

// TODO(jackson): This should change colors with the theme
sky.Color _kThumbOnColor = colors.Purple[500];
const sky.Color _kThumbOffColor = const sky.Color(0xFFFAFAFA);
sky.Color _kTrackOnColor = new sky.Color(_kThumbOnColor.value & (0x80 << 24));
const sky.Color _kTrackOffColor = const sky.Color(0x42000000);
const double _kSwitchWidth = 35.0;
const double _kThumbRadius = 10.0;
const double _kSwitchHeight = _kThumbRadius * 2.0;
const double _kTrackHeight = 14.0;
const double _kTrackRadius = _kTrackHeight / 2.0;
const double _kTrackWidth = _kSwitchWidth - (_kThumbRadius - _kTrackRadius) * 2.0;

class Switch extends Toggleable {
  // TODO(jackson): Hit-test the switch so that it can respond to both taps and swipe gestures

  Switch({
    Object key,
    bool value,
    ValueChanged onChanged
  }) : super(key: key, value: value, onChanged: onChanged);

  Size get size => const Size(_kSwitchWidth + 2.0, _kSwitchHeight + 2.0);

  void customPaintCallback(sky.Canvas canvas, Size size) {
    sky.Color thumbColor = value ? _kThumbOnColor : _kThumbOffColor;
    sky.Color trackColor = value ? _kTrackOnColor : _kTrackOffColor;

    // Draw the track rrect
    sky.Paint paint = new sky.Paint()..color = trackColor;
    paint.setStyle(sky.PaintingStyle.fill);
    sky.Rect rect = new sky.Rect.fromLTRB(
      0.0,
      _kSwitchHeight / 2.0 - _kTrackHeight / 2.0,
      _kTrackWidth,
      _kSwitchHeight / 2.0 + _kTrackHeight / 2.0
    );
    sky.RRect rrect = new sky.RRect()..setRectXY(rect, _kTrackRadius, _kTrackRadius);
    canvas.drawRRect(rrect, paint);

    // Draw the raised thumb with a shadow
    paint.color = thumbColor;
    var builder = new ShadowDrawLooperBuilder();
    for (BoxShadow boxShadow in shadows[1])
      builder.addShadow(boxShadow.offset, boxShadow.color, boxShadow.blur);
    paint.setDrawLooper(builder.build());

    // The thumb contracts slightly during the animation
    double inset = 2.0 - (toggleAnimation.value - 0.5).abs() * 2.0;
    Point thumbPos = new Point(
      _kTrackRadius + toggleAnimation.value * (_kTrackWidth - _kTrackRadius * 2),
      _kSwitchHeight / 2.0
    );
    canvas.drawCircle(thumbPos.x, thumbPos.y, _kThumbRadius - inset, paint);
  }
}
