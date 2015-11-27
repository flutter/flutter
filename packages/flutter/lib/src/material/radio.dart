// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

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
    return _enabled ? themeData.unselectedColor : themeData.disabledColor;
  }

  void _handleChanged(bool selected) {
    if (selected)
      onChanged(value);
  }

  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return new _RadioRenderObjectWidget(
      selected: value == groupValue,
      activeColor: themeData.accentColor,
      inactiveColor: _getInactiveColor(themeData),
      onChanged: _enabled ? _handleChanged : null
    );
  }
}

class _RadioRenderObjectWidget extends LeafRenderObjectWidget {
  _RadioRenderObjectWidget({
    Key key,
    this.selected,
    this.activeColor,
    this.inactiveColor,
    this.onChanged
  }) : super(key: key) {
    assert(selected != null);
    assert(activeColor != null);
    assert(inactiveColor != null);
  }

  final bool selected;
  final Color inactiveColor;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  _RenderRadio createRenderObject() => new _RenderRadio(
    value: selected,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged
  );

  void updateRenderObject(_RenderRadio renderObject, _RadioRenderObjectWidget oldWidget) {
    renderObject.value = selected;
    renderObject.activeColor = activeColor;
    renderObject.inactiveColor = inactiveColor;
    renderObject.onChanged = onChanged;
  }
}

class _RenderRadio extends RenderToggleable {
  _RenderRadio({
    bool value,
    Color activeColor,
    Color inactiveColor,
    ValueChanged<bool> onChanged
  }): super(
    value: value,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged,
    size: const Size(2 * kRadialReactionRadius, 2 * kRadialReactionRadius)
  );

  bool get isInteractive => super.isInteractive && !value;

  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    paintRadialReaction(canvas, offset + const Offset(kRadialReactionRadius, kRadialReactionRadius));

    Point center = (offset & size).center;
    Color radioColor = onChanged != null ? activeColor : inactiveColor;

    // Outer circle
    Paint paint = new Paint()
      ..color = Color.lerp(inactiveColor, radioColor, position.value)
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
