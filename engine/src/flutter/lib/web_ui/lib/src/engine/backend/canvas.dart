// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import 'filter.dart';
import 'image.dart';
import 'paint.dart';
import 'paragraph.dart';
import 'path.dart';
import 'vertices.dart';

/// The backend side of a recording canvas: one method per native canvas
/// operation.
///
/// A [BackendCanvas] is driven by `EngineCanvas`, the `ui.Canvas`
/// implementation shared by all renderers. Implementations are stateless
/// translators to native calls:
///
///  * They hold only their native canvas.
///  * They take only backend delegates ([BackendPaint], [BackendPath],
///    [BackendImage], ...), `dart:ui` value types and typed arrays. They never
///    take frontend (`Engine*`) objects, FFI pointers or JS interop types.
///  * They don't validate arguments, track images, or create or dispose
///    paints. The caller owns every [BackendPaint] it passes in.
///
/// [drawPicture] is a temporary exception that takes a [ui.Picture], until
/// `PictureRecorder` and `Picture` are unified.
abstract class BackendCanvas {
  void save();

  void saveLayer(ui.Rect? bounds, BackendPaint paint);

  /// Saves a new layer that first applies [backdropFilter] to the content
  /// behind it, sampling past the backdrop edges with [backdropTileMode].
  void saveLayerWithFilter(
    ui.Rect? bounds,
    BackendPaint paint,
    BackendImageFilter backdropFilter,
    ui.TileMode backdropTileMode,
  );

  void restore();

  /// Pops the save stack until its depth is [count].
  void restoreToCount(int count);

  /// The current save stack depth; a fresh canvas has a depth of 1.
  int getSaveCount();

  void translate(double dx, double dy);

  void scale(double sx, double sy);

  /// Rotates the current transform clockwise by [radians].
  void rotate(double radians);

  void skew(double sx, double sy);

  /// Multiplies the current transform by [matrix4].
  ///
  /// The caller has already checked that [matrix4] has 16 entries.
  void transform(Float64List matrix4);

  /// The current transform as a 16-entry column-major matrix.
  Float64List getTransform();

  void clipRect(ui.Rect rect, ui.ClipOp clipOp, bool doAntiAlias);

  void clipRRect(ui.RRect rrect, bool doAntiAlias);

  void clipPath(BackendPath path, bool doAntiAlias);

  /// The current clip in device space, rounded out to whole pixels.
  ui.Rect getDestinationClipBounds();

  /// Fills the current clip with [color], replacing the existing pixels.
  void clear(ui.Color color);

  /// Whether [rect], in local coordinates, lies entirely outside the clip.
  bool quickReject(ui.Rect rect);

  void drawColor(ui.Color color, ui.BlendMode blendMode);

  void drawLine(ui.Offset p1, ui.Offset p2, BackendPaint paint);

  void drawPaint(BackendPaint paint);

  void drawRect(ui.Rect rect, BackendPaint paint);

  void drawRRect(ui.RRect rrect, BackendPaint paint);

  void drawDRRect(ui.RRect outer, ui.RRect inner, BackendPaint paint);

  void drawOval(ui.Rect rect, BackendPaint paint);

  void drawCircle(ui.Offset center, double radius, BackendPaint paint);

  /// Draws an arc. [startAngle] and [sweepAngle] are in radians.
  void drawArc(
    ui.Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    BackendPaint paint,
  );

  void drawPath(BackendPath path, BackendPaint paint);

  void drawImage(
    BackendImage image,
    ui.Offset offset,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  );

  void drawImageRect(
    BackendImage image,
    ui.Rect src,
    ui.Rect dst,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  );

  /// Draws [image] as a nine-slice into [dst], where [center] is in image
  /// coordinates.
  void drawImageNine(
    BackendImage image,
    ui.Rect center,
    ui.Rect dst,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  );

  /// Draws [picture], which must have been recorded by the same renderer.
  void drawPicture(ui.Picture picture);

  void drawParagraph(BackendParagraph paragraph, ui.Offset offset);

  /// Draws points from [points], a flat list of x, y pairs of even length.
  void drawPoints(ui.PointMode pointMode, Float32List points, BackendPaint paint);

  void drawVertices(BackendVertices vertices, ui.BlendMode blendMode, BackendPaint paint);

  /// Draws sprites from [atlas].
  ///
  /// [rstTransforms] and [rects] have four values per sprite. [colors] is
  /// either null or has one value per sprite.
  void drawAtlas(
    BackendImage atlas,
    Float32List rstTransforms,
    Float32List rects,
    Uint32List? colors,
    ui.BlendMode blendMode,
    ui.Rect? cullRect,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  );

  /// Draws the shadow of [path]. [devicePixelRatio] scales the light
  /// geometry from logical to physical pixels.
  void drawShadow(
    BackendPath path,
    ui.Color color,
    double elevation,
    bool transparentOccluder,
    double devicePixelRatio,
  );
}
