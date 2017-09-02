// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export 'dart:ui' show
  BlendMode,
  BlurStyle,
  Canvas,
  Color,
  ColorFilter,
  FilterQuality,
  FontStyle,
  FontWeight,
  ImageShader,
  MaskFilter,
  Offset,
  Paint,
  PaintingStyle,
  Path,
  PathFillType,
  Radius,
  RRect,
  RSTransform,
  Rect,
  Shader,
  Size,
  StrokeCap,
  StrokeJoin,
  TextAlign,
  TextBaseline,
  TextDecoration,
  TextDecorationStyle,
  TextDirection,
  TileMode,
  VertexMode,
  VoidCallback,
  hashValues,
  hashList;

// Intentionally not exported:
//  - Image, decodeImageFromDataPipe, decodeImageFromList:
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

/// The two cardinal directions in two dimensions.
///
/// The axis is always relative to the current coordinate space. This means, for
/// example, that a [horizontal] axis might actually be diagonally from top
/// right to bottom left, due to some local [Transform] applied to the scene.
///
/// See also:
///
///  * [AxisDirection], which is a directional version of this enum (with values
///    light left and right, rather than just horizontal).
///  * [TextDirection], which disambiguates between left-to-right horizontal
///    content and right-to-left horizontal content.
enum Axis {
  /// Left and right.
  ///
  /// See also:
  ///
  ///  * [TextDirection], which disambiguates between left-to-right horizontal
  ///    content and right-to-left horizontal content.
  horizontal,

  /// Up and down.
  vertical,
}

/// Returns the opposite of the given [Axis].
///
/// Specifically, returns [Axis.horizontal] for [Axis.vertical], and
/// vice versa.
///
/// See also:
///
///  * [flipAxisDirection], which does the same thing for [AxisDirection] values.
Axis flipAxis(Axis direction) {
  assert(direction != null);
  switch (direction) {
    case Axis.horizontal:
      return Axis.vertical;
    case Axis.vertical:
      return Axis.horizontal;
  }
  return null;
}

/// A direction in which boxes flow vertically.
///
/// This is used by the flex algorithm (e.g. [Column]) to decide in which
/// direction to draw boxes.
///
/// This is also used to disambiguate `start` and `end` values (e.g.
/// [MainAxisAlignment.start] or [CrossAxisAlignment.end]).
///
/// See also:
///
///  * [TextDirection], which controls the same thing but horizontally.
enum VerticalDirection {
  /// Boxes should start at the bottom and be stacked vertically towards the top.
  ///
  /// The "start" is at the bottom, the "end" is at the top.
  up,

  /// Boxes should start at the top and be stacked vertically towards the bottom.
  ///
  /// The "start" is at the top, the "end" is at the bottom.
  down,
}
