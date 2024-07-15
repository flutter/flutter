// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter/rendering.dart';
///
/// @docImport 'text_span.dart';
/// @docImport 'text_style.dart';
library;

import 'dart:ui' show TextDirection;
import 'package:flutter/foundation.dart' show Axis, AxisDirection;

export 'dart:ui' show
  BlendMode,
  BlurStyle,
  Canvas,
  Clip,
  Color,
  ColorFilter,
  FilterQuality,
  FontFeature,
  FontStyle,
  FontVariation,
  FontWeight,
  GlyphInfo,
  ImageShader,
  Locale,
  MaskFilter,
  Offset,
  Paint,
  PaintingStyle,
  Path,
  PathFillType,
  PathOperation,
  RRect,
  RSTransform,
  Radius,
  Rect,
  Shader,
  Shadow,
  Size,
  StrokeCap,
  StrokeJoin,
  TextAffinity,
  TextAlign,
  TextBaseline,
  TextBox,
  TextDecoration,
  TextDecorationStyle,
  TextDirection,
  TextHeightBehavior,
  TextLeadingDistribution,
  TextPosition,
  TileMode,
  VertexMode,
  hashList,
  hashValues;

export 'package:flutter/foundation.dart' show Axis, AxisDirection, VerticalDirection, VoidCallback;

// Intentionally not exported:
//  - Image, instantiateImageCodec, decodeImageFromList:
//      We use ui.* to make it very explicit that these are low-level image APIs.
//      Generally, higher layers provide more reasonable APIs around images.
//  - lerpDouble:
//      Hopefully this will eventually become Double.lerp.
//  - Paragraph, ParagraphBuilder, ParagraphStyle, TextBox:
//      These are low-level text primitives. Use this package's TextPainter API.
//  - Picture, PictureRecorder, Scene, SceneBuilder:
//      These are low-level primitives. Generally, the rendering layer makes these moot.
//  - Gradient:
//      Use this package's higher-level Gradient API instead.
//  - window, WindowPadding
//      These are generally wrapped by other APIs so we always refer to them directly
//      as ui.* to avoid making them seem like high-level APIs.

/// The description of the difference between two objects, in the context of how
/// it will affect the rendering.
///
/// Used by [TextSpan.compareTo] and [TextStyle.compareTo].
///
/// The values in this enum are ordered such that they are in increasing order
/// of cost. A value with index N implies all the values with index less than N.
/// For example, [layout] (index 3) implies [paint] (2).
enum RenderComparison {
  /// The two objects are identical (meaning deeply equal, not necessarily
  /// [dart:core.identical]).
  identical,

  /// The two objects are identical for the purpose of layout, but may be different
  /// in other ways.
  ///
  /// For example, maybe some event handlers changed.
  metadata,

  /// The two objects are different but only in ways that affect paint, not layout.
  ///
  /// For example, only the color is changed.
  ///
  /// [RenderObject.markNeedsPaint] would be necessary to handle this kind of
  /// change in a render object.
  paint,

  /// The two objects are different in ways that affect layout (and therefore paint).
  ///
  /// For example, the size is changed.
  ///
  /// This is the most drastic level of change possible.
  ///
  /// [RenderObject.markNeedsLayout] would be necessary to handle this kind of
  /// change in a render object.
  layout,
}

/// Returns the opposite of the given [Axis].
///
/// Specifically, returns [Axis.horizontal] for [Axis.vertical], and
/// vice versa.
///
/// See also:
///
///  * [flipAxisDirection], which does the same thing for [AxisDirection] values.
@Deprecated(
  'Use the ".flipped" getter instead. '
  "The getter's behavior is identical to this function and is less verbose. "
  'This feature was deprecated after v3.23.0-0.1.pre.',
)
Axis flipAxis(Axis direction) {
  return switch (direction) {
    Axis.horizontal => Axis.vertical,
    Axis.vertical => Axis.horizontal,
  };
}

/// Returns the [Axis] that contains the given [AxisDirection].
///
/// Specifically, returns [Axis.vertical] for [AxisDirection.up] and
/// [AxisDirection.down] and returns [Axis.horizontal] for [AxisDirection.left]
/// and [AxisDirection.right].
@Deprecated(
  'Use the ".axis" getter instead. '
  "The getter's behavior is identical to this function and is less verbose. "
  'This feature was deprecated after v3.23.0-0.1.pre.',
)
Axis axisDirectionToAxis(AxisDirection axisDirection) {
  return switch (axisDirection) {
    AxisDirection.up   || AxisDirection.down  => Axis.vertical,
    AxisDirection.left || AxisDirection.right => Axis.horizontal,
  };
}

/// Returns the [AxisDirection] in which reading occurs in the given [TextDirection].
///
/// Specifically, returns [AxisDirection.left] for [TextDirection.rtl] and
/// [AxisDirection.right] for [TextDirection.ltr].
AxisDirection textDirectionToAxisDirection(TextDirection textDirection) {
  return switch (textDirection) {
    TextDirection.rtl => AxisDirection.left,
    TextDirection.ltr => AxisDirection.right,
  };
}

/// Returns the opposite of the given [AxisDirection].
///
/// Specifically, returns [AxisDirection.up] for [AxisDirection.down] (and
/// vice versa), as well as [AxisDirection.left] for [AxisDirection.right] (and
/// vice versa).
///
/// See also:
///
///  * [flipAxis], which does the same thing for [Axis] values.
@Deprecated(
  'Use the ".flipped" getter instead. '
  "The getter's behavior is identical to this function and is less verbose. "
  'This feature was deprecated after v3.23.0-0.1.pre.',
)
AxisDirection flipAxisDirection(AxisDirection axisDirection) {
  return switch (axisDirection) {
    AxisDirection.up    => AxisDirection.down,
    AxisDirection.right => AxisDirection.left,
    AxisDirection.down  => AxisDirection.up,
    AxisDirection.left  => AxisDirection.right,
  };
}

/// Returns whether traveling along the given axis direction visits coordinates
/// along that axis in numerically decreasing order.
///
/// Specifically, returns true for [AxisDirection.up] and [AxisDirection.left]
/// and false for [AxisDirection.down] and [AxisDirection.right].
@Deprecated(
  'Use the ".isReversed" getter instead. '
  "The getter's behavior is identical to this function and is less verbose. "
  'This feature was deprecated after v3.23.0-0.1.pre.',
)
bool axisDirectionIsReversed(AxisDirection axisDirection) {
  return switch (axisDirection) {
    AxisDirection.up   || AxisDirection.left  => true,
    AxisDirection.down || AxisDirection.right => false,
  };
}
