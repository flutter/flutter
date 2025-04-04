// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Wraps a [Widget], initializing various state and properties to allow for
/// previewing of the [Widget] in the widget previewer.
///
/// WARNING: This interface is not stable and **will change**.
///
/// See also:
///
///  * [Preview], an annotation class used to mark functions returning widget
///    previews.
// TODO(bkonyi): link to actual documentation when available.
class WidgetPreview {
  /// Wraps [builder] in a [WidgetPreview] instance that applies some set of
  /// properties.
  const WidgetPreview({
    required this.builder,
    this.name,
    this.width,
    this.height,
    this.textScaleFactor,
  });

  /// A description to be displayed alongside the preview.
  ///
  /// If not provided, no name will be associated with the preview.
  final String? name;

  /// A callback to build the [Widget] to be rendered in the preview.
  final Widget Function() builder;

  /// Artificial width constraint to be applied to the [Widget] returned by [builder].
  ///
  /// If not provided, the previewed widget will attempt to set its own width
  /// constraints and may result in an unbounded constraint error.
  final double? width;

  /// Artificial height constraint to be applied to the [Widget] returned by [builder].
  ///
  /// If not provided, the previewed widget will attempt to set its own height
  /// constraints and may result in an unbounded constraint error.
  final double? height;

  /// Applies font scaling to text within the [Widget] returned by [builder].
  ///
  /// If not provided, the default text scaling factor provided by [MediaQuery]
  /// will be used.
  final double? textScaleFactor;
}
