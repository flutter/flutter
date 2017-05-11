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
