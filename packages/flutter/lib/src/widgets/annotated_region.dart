// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/widgets/framework.dart';

/// Annotates a region of the layer tree with a value.
class AnnotatedRegion<T> extends SingleChildRenderObjectWidget {
  /// Creates a new annotated region.
  const AnnotatedRegion({
    Key key,
    @required Widget child,
    @required this.value,
  }) : assert(value != null),
       assert(child != null),
       super(key: key, child: child);

  /// The value inserted into the layer tree.
  final T value;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new AnnotatedRegionRenderObject<T>()
      ..value = value;
  }

  @override
  void updateRenderObject(BuildContext context, AnnotatedRegionRenderObject<T> renderObject) {
    renderObject.value = value;
  }
}

/// Render object for the [AnnotatedRegion].
class AnnotatedRegionRenderObject<T> extends RenderProxyBox {
  /// The value to be annotated in the layer tree.
  T value;

  @override
  final bool alwaysNeedsCompositing = true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.pushLayer(
        new AnnotatedRegionLayer<T>(value),
        super.paint,
        offset,
      );
    }
  }
}
