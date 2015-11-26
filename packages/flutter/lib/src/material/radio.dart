// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'theme.dart';
import 'toggleable.dart';

const double _kDiameter = 16.0;
const double _kOuterRadius = _kDiameter / 2.0;
const double _kInnerRadius = 5.0;

class Radio<T> extends StatelessComponent {
  Radio({
    Key key,
    this.value,
    this.groupValue,
    this.onChanged
  }) : super(key: key);

  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  bool get _enabled => onChanged != null;

  Color _getInactiveColor(ThemeData themeData) {
    if (!_enabled)
      return themeData.brightness == ThemeBrightness.light ? Colors.black26 : Colors.white30;
    return themeData.brightness == ThemeBrightness.light ? Colors.black54 : Colors.white70;
  }

  void _handleChanged(bool selected) {
    if (selected)
      onChanged(value);
  }

  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return new _RadioRenderObjectWidget(
      selected: value == groupValue,
      inactiveColor: _getInactiveColor(themeData),
      accentColor: themeData.accentColor,
      onChanged: _enabled ? _handleChanged : null
    );
  }
}

class _RadioRenderObjectWidget extends LeafRenderObjectWidget {
  _RadioRenderObjectWidget({
    Key key,
    this.selected,
    this.inactiveColor,
    this.accentColor,
    this.onChanged
  }) : super(key: key) {
    assert(inactiveColor != null);
    assert(accentColor != null);
  }

  final bool selected;
  final Color inactiveColor;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  _RenderRadio createRenderObject() => new _RenderRadio(
    value: selected,
    accentColor: accentColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged
  );

  void updateRenderObject(_RenderRadio renderObject, _RadioRenderObjectWidget oldWidget) {
    renderObject.value = selected;
    renderObject.inactiveColor = inactiveColor;
    renderObject.accentColor = accentColor;
    renderObject.onChanged = onChanged;
  }
}

class _RenderRadio extends RenderToggleable {
  _RenderRadio({
    bool value,
    Color inactiveColor,
    Color accentColor,
    ValueChanged<bool> onChanged
  }): _inactiveColor = inactiveColor,
      super(
        value: value,
        accentColor: accentColor,
        onChanged: onChanged,
        size: const Size(2 * kRadialReactionRadius, 2 * kRadialReactionRadius)
      ) {
    assert(inactiveColor != null);
    assert(accentColor != null);
  }

  Color get inactiveColor => _inactiveColor;
  Color _inactiveColor;
  void set inactiveColor(Color value) {
    assert(value != null);
    if (value == _inactiveColor)
      return;
    _inactiveColor = value;
    markNeedsPaint();
  }

  bool get isInteractive => super.isInteractive && !value;

  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    paintRadialReaction(canvas, offset + const Offset(kRadialReactionRadius, kRadialReactionRadius));

    Point center = (offset & size).center;
    Color activeColor = onChanged != null ? accentColor : inactiveColor;

    // Outer circle
    Paint paint = new Paint()
      ..color = Color.lerp(inactiveColor, activeColor, position.value)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, _kOuterRadius, paint);

    // Inner circle
    if (!position.isDismissed) {
      paint.style = ui.PaintingStyle.fill;
      canvas.drawCircle(center, _kInnerRadius * position.value, paint);
    }
  }
}
