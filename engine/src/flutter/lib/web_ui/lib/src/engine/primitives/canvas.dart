// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// The implementation of [ui.Canvas] shared by all renderers.
///
/// This class is the frontend of a recording canvas. It owns every decision
/// that doesn't depend on the renderer, and forwards each operation to a
/// stateless [BackendCanvas]:
///
///  * Argument checks that match native `dart:ui` (the same asserts and
///    [ArgumentError]s as the native `Canvas`). They run before anything
///    reaches the backend.
///  * Image retention: every image and paint drawn is recorded in the
///    picture's [PictureImageTracker].
///  * The per-draw paint lifecycle: a [BackendPaint] is created right before
///    each backend call and disposed right after it.
///  * Unwrapping frontend objects ([EnginePath], [EngineImage],
///    [EngineVertices], [EngineParagraph], [EngineImageFilter]) into their
///    backend delegates.
class EngineCanvas implements LayerCanvas {
  /// Creates a canvas that forwards every operation to the given backend.
  ///
  /// When recording, [recorder] is the picture recorder that owns the native
  /// canvas, and [tracker] retains the image sources drawn into it. Canvases
  /// that draw directly into a surface pass neither.
  EngineCanvas(this._backend, {ui.PictureRecorder? recorder, PictureImageTracker? tracker})
    : _recorder = recorder,
      _tracker = tracker;

  /// Checks that [recorder] can start a new recording, and returns the cull
  /// rect to record with.
  static ui.Rect resolveCullRect(ui.PictureRecorder recorder, ui.Rect? cullRect) {
    if (recorder.isRecording) {
      throw ArgumentError('"recorder" must not already be associated with another Canvas.');
    }
    return cullRect ?? ui.Rect.largest;
  }

  final BackendCanvas _backend;

  // Holds a reference to the recorder to prevent premature garbage collection
  // of the recorder while this canvas is active. This ensures the recorder's
  // finalizer does not run prematurely to release tracked image sources.
  // ignore: unused_field
  final ui.PictureRecorder? _recorder;

  PictureImageTracker? _tracker;

  /// Clears the tracker reference when recording finishes so subsequent
  /// operations (if any) do not retain images.
  void clearTracker() => _tracker = null;

  @override
  void save() => _backend.save();

  @override
  void saveLayer(ui.Rect? bounds, ui.Paint paint) {
    if (bounds != null) {
      assert(rectIsValid(bounds));
    }
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.saveLayer(bounds, backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  @override
  void saveLayerWithFilter(ui.Rect? bounds, ui.Paint paint, ui.ImageFilter backdropFilter) {
    if (bounds != null) {
      assert(rectIsValid(bounds));
    }
    final EngineImageFilter engineFilter;
    if (backdropFilter is ui.ColorFilter) {
      engineFilter = EngineColorFilterImageFilter(colorFilter: backdropFilter as EngineColorFilter);
    } else {
      engineFilter = backdropFilter as EngineImageFilter;
    }

    // There are 2 ImageFilter objects applied here. The filter in the paint
    // object is applied to the contents and its default tile mode is decal
    // (automatically applied by createBackendPaint).
    // The filter supplied as an argument to this function [engineFilter] will
    // be applied to the backdrop and its default tile mode will be mirror.
    // We also pass in the blur tile mode as an argument to saveLayer because
    // that operation will not adopt the tile mode from the backdrop filter
    // and instead needs it supplied to the saveLayer call itself as a
    // separate argument.
    final BackendImageFilter backendFilter = engineFilter.getBackendFilter(
      defaultBlurTileMode: ui.TileMode.mirror,
    );
    final ui.TileMode backdropTileMode = engineFilter.backdropTileMode ?? ui.TileMode.mirror;

    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    try {
      _backend.saveLayerWithFilter(bounds, backendPaint, backendFilter, backdropTileMode);
    } finally {
      backendPaint.dispose();
    }
    _tracker?.recordPaint(paint);
  }

  @override
  void restore() => _backend.restore();

  @override
  void restoreToCount(int count) => _backend.restoreToCount(count);

  @override
  int getSaveCount() => _backend.getSaveCount();

  @override
  void translate(double dx, double dy) => _backend.translate(dx, dy);

  @override
  void scale(double sx, [double? sy]) => _backend.scale(sx, sy ?? sx);

  @override
  void rotate(double radians) => _backend.rotate(radians);

  @override
  void skew(double sx, double sy) => _backend.skew(sx, sy);

  @override
  void transform(Float64List matrix4) {
    if (matrix4.length != 16) {
      throw ArgumentError('"matrix4" must have 16 entries.');
    }
    _backend.transform(matrix4);
  }

  @override
  Float64List getTransform() => _backend.getTransform();

  @override
  void clipRect(ui.Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    assert(rectIsValid(rect));
    _backend.clipRect(rect, clipOp, doAntiAlias);
  }

  @override
  void clipRRect(ui.RRect rrect, {bool doAntiAlias = true}) {
    assert(rrectIsValid(rrect));
    _backend.clipRRect(rrect, doAntiAlias);
  }

  @override
  void clipRSuperellipse(ui.RSuperellipse rsuperellipse, {bool doAntiAlias = true}) {
    assert(rsuperellipseIsValid(rsuperellipse));
    final (ui.Path path, ui.Offset offset) = rsuperellipse.toPathOffset();
    final BackendPath backendPath = (path as EnginePath).backendPath;
    _backend.translate(offset.dx, offset.dy);
    _backend.clipPath(backendPath, doAntiAlias);
    _backend.translate(-offset.dx, -offset.dy);
  }

  @override
  void clipPath(ui.Path path, {bool doAntiAlias = true}) {
    _backend.clipPath((path as EnginePath).backendPath, doAntiAlias);
  }

  @override
  ui.Rect getLocalClipBounds() {
    final transform = Matrix4.fromFloat32List(toMatrix32(_backend.getTransform()));
    if (transform.invert() == 0) {
      // Non-invertible transforms collapse space to a line or point.
      return ui.Rect.zero;
    }
    return transform.transformRect(_backend.getDestinationClipBounds());
  }

  @override
  ui.Rect getDestinationClipBounds() => _backend.getDestinationClipBounds();

  @override
  void clear(ui.Color color) => _backend.clear(color);

  @override
  bool quickReject(ui.Rect rect) => _backend.quickReject(rect);

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) => _backend.drawColor(color, blendMode);

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {
    assert(offsetIsValid(p1));
    assert(offsetIsValid(p2));
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.drawLine(p1, p2, backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  @override
  void drawPaint(ui.Paint paint) {
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.drawPaint(backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    assert(rectIsValid(rect));
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.drawRect(rect, backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) {
    assert(rrectIsValid(rrect));
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.drawRRect(rrect, backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  @override
  void drawRSuperellipse(ui.RSuperellipse rsuperellipse, ui.Paint paint) {
    assert(rsuperellipseIsValid(rsuperellipse));
    final (ui.Path path, ui.Offset offset) = rsuperellipse.toPathOffset();
    final BackendPath backendPath = (path as EnginePath).backendPath;
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    try {
      _backend.translate(offset.dx, offset.dy);
      _backend.drawPath(backendPath, backendPaint);
      _backend.translate(-offset.dx, -offset.dy);
    } finally {
      backendPaint.dispose();
    }
    _tracker?.recordPaint(paint);
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {
    assert(rrectIsValid(outer));
    assert(rrectIsValid(inner));
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.drawDRRect(outer, inner, backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  @override
  void drawOval(ui.Rect rect, ui.Paint paint) {
    assert(rectIsValid(rect));
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.drawOval(rect, backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  @override
  void drawCircle(ui.Offset c, double radius, ui.Paint paint) {
    assert(offsetIsValid(c));
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.drawCircle(c, radius, backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  @override
  void drawArc(ui.Rect rect, double startAngle, double sweepAngle, bool useCenter, ui.Paint paint) {
    assert(rectIsValid(rect));
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.drawArc(rect, startAngle, sweepAngle, useCenter, backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  @override
  void drawPath(ui.Path path, ui.Paint paint) {
    final BackendPath backendPath = (path as EnginePath).backendPath;
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    try {
      _backend.drawPath(backendPath, backendPaint);
    } finally {
      backendPaint.dispose();
    }
    _tracker?.recordPaint(paint);
  }

  /// Draws [image] onto the canvas with its top-left corner at [offset].
  ///
  /// Retains the underlying DOM [ImageSource] for [image] and any shader
  /// images in [paint] until the recorded picture is disposed.
  @override
  void drawImage(ui.Image image, ui.Offset offset, ui.Paint paint) {
    assert(!image.debugDisposed);
    assert(offsetIsValid(offset));
    final BackendImage backendImage = (image as EngineImage).backendImage;
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint(
      defaultBlurTileMode: ui.TileMode.clamp,
    );
    try {
      _backend.drawImage(backendImage, offset, backendPaint, paint.filterQuality);
    } finally {
      backendPaint.dispose();
    }
    _tracker?.recordImage(image);
    _tracker?.recordPaint(paint);
  }

  @override
  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {
    assert(!image.debugDisposed);
    assert(rectIsValid(src));
    assert(rectIsValid(dst));
    final BackendImage backendImage = (image as EngineImage).backendImage;
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint(
      defaultBlurTileMode: ui.TileMode.clamp,
    );
    try {
      _backend.drawImageRect(backendImage, src, dst, backendPaint, paint.filterQuality);
    } finally {
      backendPaint.dispose();
    }
    _tracker?.recordImage(image);
    _tracker?.recordPaint(paint);
  }

  @override
  void drawImageNine(ui.Image image, ui.Rect center, ui.Rect dst, ui.Paint paint) {
    assert(!image.debugDisposed);
    assert(rectIsValid(center));
    assert(rectIsValid(dst));
    final BackendImage backendImage = (image as EngineImage).backendImage;
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint(
      defaultBlurTileMode: ui.TileMode.clamp,
    );
    try {
      _backend.drawImageNine(backendImage, center, dst, backendPaint, paint.filterQuality);
    } finally {
      backendPaint.dispose();
    }
    _tracker?.recordImage(image);
    _tracker?.recordPaint(paint);
  }

  @override
  void drawPicture(ui.Picture picture) {
    assert(!picture.debugDisposed);
    _backend.drawPicture(picture);
    if (picture case LayerPicture(:final imageTracker?)) {
      _tracker?.recordFrom(imageTracker);
    }
  }

  /// Draws a text [paragraph] at [offset].
  ///
  /// Note: When [paragraph] is an [EngineParagraph], its layout and shaders are
  /// encapsulated natively by the backend paragraph. When [paragraph] is a
  /// [WebParagraph], painting is dispatched back to this canvas where paints
  /// with image shaders are automatically tracked.
  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    assert(!paragraph.debugDisposed);
    assert(offsetIsValid(offset));
    if (paragraph is EngineParagraph) {
      _backend.drawParagraph(paragraph.backendParagraph, offset);
    } else if (paragraph is WebParagraph) {
      paragraph.paint(this, offset);
    } else {
      throw UnimplementedError('Unknown paragraph type.');
    }
  }

  /// Draws a sequence of points according to [pointMode].
  ///
  /// Retains any image sources referenced by [paint] (such as an [ui.ImageShader]).
  @override
  void drawPoints(ui.PointMode pointMode, List<ui.Offset> points, ui.Paint paint) {
    final int pointCount = points.length;
    if (pointCount == 0) {
      return;
    }
    final flatPoints = Float32List(pointCount * 2);
    for (var i = 0; i < pointCount; i++) {
      final ui.Offset point = points[i];
      assert(offsetIsValid(point));
      flatPoints[i * 2] = point.dx;
      flatPoints[i * 2 + 1] = point.dy;
    }
    _drawPoints(pointMode, flatPoints, paint);
  }

  /// Draws a sequence of points from raw float coordinates according to
  /// [pointMode].
  ///
  /// Retains any image sources referenced by [paint] (such as an [ui.ImageShader]).
  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, ui.Paint paint) {
    if (points.isEmpty) {
      return;
    }
    if (points.length % 2 != 0) {
      throw ArgumentError('"points" must have an even number of values.');
    }
    _drawPoints(pointMode, points, paint);
  }

  void _drawPoints(ui.PointMode pointMode, Float32List points, ui.Paint paint) {
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    _backend.drawPoints(pointMode, points, backendPaint);
    backendPaint.dispose();
    _tracker?.recordPaint(paint);
  }

  /// Draws a set of triangles/vertices with optional texture coordinates and
  /// colors.
  ///
  /// Retains any image sources referenced by [paint] (such as an [ui.ImageShader]).
  @override
  void drawVertices(ui.Vertices vertices, ui.BlendMode blendMode, ui.Paint paint) {
    assert(!vertices.debugDisposed);
    final BackendVertices? backendVertices = (vertices as EngineVertices).delegate;
    if (backendVertices == null) {
      // Vertices with no positions have no backend delegate and draw nothing.
      return;
    }
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint();
    try {
      _backend.drawVertices(backendVertices, blendMode, backendPaint);
    } finally {
      backendPaint.dispose();
    }
    _tracker?.recordPaint(paint);
  }

  @override
  void drawAtlas(
    ui.Image atlas,
    List<ui.RSTransform> transforms,
    List<ui.Rect> rects,
    List<ui.Color>? colors,
    ui.BlendMode? blendMode,
    ui.Rect? cullRect,
    ui.Paint paint,
  ) {
    assert(!atlas.debugDisposed);
    assert(colors == null || colors.isEmpty || blendMode != null);

    final int rectCount = rects.length;
    if (transforms.length != rectCount) {
      throw ArgumentError('"transforms" and "rects" lengths must match.');
    }
    if (colors != null && colors.isNotEmpty && colors.length != rectCount) {
      throw ArgumentError(
        'If non-null, "colors" length must match that of "transforms" and "rects".',
      );
    }
    if (rectCount == 0) {
      return;
    }

    final rstTransformBuffer = Float32List(rectCount * 4);
    final rectBuffer = Float32List(rectCount * 4);
    for (var i = 0; i < rectCount; ++i) {
      final int index0 = i * 4;
      final int index1 = index0 + 1;
      final int index2 = index0 + 2;
      final int index3 = index0 + 3;
      final ui.RSTransform rstTransform = transforms[i];
      final ui.Rect rect = rects[i];
      assert(rectIsValid(rect));
      rstTransformBuffer[index0] = rstTransform.scos;
      rstTransformBuffer[index1] = rstTransform.ssin;
      rstTransformBuffer[index2] = rstTransform.tx;
      rstTransformBuffer[index3] = rstTransform.ty;
      rectBuffer[index0] = rect.left;
      rectBuffer[index1] = rect.top;
      rectBuffer[index2] = rect.right;
      rectBuffer[index3] = rect.bottom;
    }

    Uint32List? colorBuffer;
    if (colors != null && colors.isNotEmpty) {
      final int colorCount = colors.length;
      colorBuffer = Uint32List(colorCount);
      for (var i = 0; i < colorCount; i++) {
        colorBuffer[i] = colors[i].value;
      }
    }

    _drawAtlas(
      atlas,
      rstTransformBuffer,
      rectBuffer,
      colorBuffer,
      blendMode ?? ui.BlendMode.src,
      cullRect,
      paint,
    );
  }

  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    ui.BlendMode? blendMode,
    ui.Rect? cullRect,
    ui.Paint paint,
  ) {
    assert(!atlas.debugDisposed);
    assert(colors == null || blendMode != null);

    final int rectCount = rects.length;
    if (rstTransforms.length != rectCount) {
      throw ArgumentError('"rstTransforms" and "rects" lengths must match.');
    }
    if (rectCount % 4 != 0) {
      throw ArgumentError('"rstTransforms" and "rects" lengths must be a multiple of four.');
    }
    if (colors != null && colors.length * 4 != rectCount) {
      throw ArgumentError(
        'If non-null, "colors" length must be one fourth the length of "rstTransforms" and "rects".',
      );
    }
    if (rectCount == 0) {
      return;
    }

    // An empty color list means "no colors": pass null so that backends don't
    // allocate an empty native buffer.
    final Uint32List? unsignedColors = (colors == null || colors.isEmpty)
        ? null
        : colors.buffer.asUint32List(colors.offsetInBytes, colors.length);

    _drawAtlas(
      atlas,
      rstTransforms,
      rects,
      unsignedColors,
      blendMode ?? ui.BlendMode.src,
      cullRect,
      paint,
    );
  }

  void _drawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Uint32List? colors,
    ui.BlendMode blendMode,
    ui.Rect? cullRect,
    ui.Paint paint,
  ) {
    final BackendImage backendAtlas = (atlas as EngineImage).backendImage;
    final BackendPaint backendPaint = (paint as EnginePaint).createBackendPaint(
      defaultBlurTileMode: ui.TileMode.clamp,
    );
    try {
      _backend.drawAtlas(
        backendAtlas,
        rstTransforms,
        rects,
        colors,
        blendMode,
        cullRect,
        backendPaint,
        paint.filterQuality,
      );
    } finally {
      backendPaint.dispose();
    }
    _tracker?.recordImage(atlas);
    _tracker?.recordPaint(paint);
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation, bool transparentOccluder) {
    _backend.drawShadow(
      (path as EnginePath).backendPath,
      color,
      elevation,
      transparentOccluder,
      EngineFlutterDisplay.instance.devicePixelRatio,
    );
  }
}
