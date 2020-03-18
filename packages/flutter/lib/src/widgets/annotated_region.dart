// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

/// Annotates a region on the screen with a value (known as an annotation).
/// 
/// Annotations do not affect painting, but can be searched between frames.
///
/// See also:
///
///  * [RenderView.search] and [RenderView.searchFirst], which search annotations
///    at a location.
class AnnotatedRegion<T> extends SingleChildRenderObjectWidget {
  /// Creates a new annotated region to insert [value] into the layer tree.
  ///
  /// Neither [child] nor [value] may be null.
  ///
  /// The [sized] defaults to true and controls whether the boundary of this
  /// widget will be used to clip the annotation.
  const AnnotatedRegion({
    Key key,
    @required Widget child,
    @required this.value,
    this.sized = true,
  }) : assert(value != null),
       assert(child != null),
       super(key: key, child: child);

  /// A value which can be retrieved using [RenderView.search] and
  /// [RenderView.searchFirst].
  final T value;

  /// If true, the size of this widget will be used to bound the annotated
  /// region.
  /// 
  /// If false, the annotated region is unbounded except for clips along its
  /// ancestors.
  ///
  /// Annotations will only be added to the result if the bound contains
  /// the target position of the search.
  final bool sized;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderAnnotatedRegion<T>(value: value, sized: sized);
  }

  @override
  void updateRenderObject(BuildContext context, RenderAnnotatedRegion<T> renderObject) {
    renderObject
      ..value = value
      ..sized = sized;
  }
}
