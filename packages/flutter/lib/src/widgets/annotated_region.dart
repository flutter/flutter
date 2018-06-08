// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'framework.dart';

/// Annotates a region of the layer tree with a value.
///
/// See also:
///
///   * [Layer.findRegion], for an example of how this value is retrieved.
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

