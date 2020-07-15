// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

/// Applies a [ColorFilter] to its child.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=F7Cll22Dno8}
@immutable
class ColorFiltered extends SingleChildRenderObjectWidget {
  /// Creates a widget that applies a [ColorFilter] to its child.
  ///
  /// The [colorFilter] must not be null.
  const ColorFiltered({@required this.colorFilter, Widget child, Key key})
      : assert(colorFilter != null),
        super(key: key, child: child);

  /// The color filter to apply to the child of this widget.
  final ColorFilter colorFilter;

  @override
  RenderObject createRenderObject(BuildContext context) => _ColorFilterRenderObject(colorFilter);

  @override
  void updateRenderObject(BuildContext context, _ColorFilterRenderObject renderObject) {
    renderObject.colorFilter = colorFilter;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ColorFilter>('colorFilter', colorFilter));
  }
}

class _ColorFilterRenderObject extends RenderProxyBox {
  _ColorFilterRenderObject(this._colorFilter);

  ColorFilter get colorFilter => _colorFilter;
  ColorFilter _colorFilter;
  set colorFilter(ColorFilter value) {
    assert(value != null);
    if (value != _colorFilter) {
      _colorFilter = value;
      markNeedsPaint();
    }
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    layer = context.pushColorFilter(offset, colorFilter, super.paint, oldLayer: layer as ColorFilterLayer);
  }
}
