// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmCanvas implements LayerCanvas {
  /// Creates a canvas that records drawing commands into [recorder] bounded by [cullRect].
  factory SkwasmCanvas(ui.PictureRecorder recorder, [ui.Rect? cullRect]) {
    if (recorder.isRecording) {
      throw ArgumentError('"recorder" must not already be associated with another Canvas.');
    }
    cullRect ??= ui.Rect.largest;
    final skwasmRecorder = recorder as SkwasmPictureRecorder;
    return skwasmRecorder.beginRecording(cullRect);
  }

  /// Creates a [SkwasmCanvas] wrapping an underlying native [_handle].
  ///
  /// Holds an optional reference to [recorder] to prevent premature garbage
  /// collection of the recorder while this canvas is reachable, and [tracker]
  /// to retain any drawn image sources.
  SkwasmCanvas.fromHandle(
    this._handle, {
    SkwasmPictureRecorder? recorder,
    PictureImageTracker? tracker,
  }) : _recorder = recorder,
       _tracker = tracker;

  CanvasHandle _handle;
  // Holds a reference to the recorder to prevent premature garbage collection
  // of the recorder while this canvas is active. The underlying native SkCanvas
  // is owned by the native SkPictureRecorder, and the recorder also attaches
  // a finalizer that would prematurely release tracked images if collected early.
  // ignore: unused_field
  final SkwasmPictureRecorder? _recorder;
  PictureImageTracker? _tracker;

  /// Clears the tracker reference when recording finishes so subsequent
  /// operations (if any) do not retain images.
  void clearTracker() {
    _tracker = null;
  }

  // Note that we do not need to deal with the finalizer registry here, because
  // the underlying native skia object is tied directly to the lifetime of the
  // associated SkPictureRecorder.

  @override
  void save() {
    canvasSave(_handle);
  }

  @override
  void saveLayer(ui.Rect? bounds, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    if (bounds != null) {
      withStackScope((StackScope s) {
        canvasSaveLayer(_handle, s.convertRectToNative(bounds), backendPaint.handle, nullptr);
      });
    } else {
      canvasSaveLayer(_handle, nullptr, backendPaint.handle, nullptr);
    }
    backendPaint.dispose();
  }

  @override
  void saveLayerWithFilter(ui.Rect? bounds, ui.Paint paint, ui.ImageFilter imageFilter) {
    _tracker?.recordPaint(paint);
    // There are 2 ImageFilter objects applied here. The filter in the paint
    // object is applied to the contents and its default tile mode is decal
    // (automatically applied by createBackendPaint).
    // The filter supplied as an argument to this function [nativeFilter] will
    // be applied to the backdrop and its default tile mode will be mirror.
    // We also pass in the blur tile mode as an argument to saveLayer because
    // that operation will not adopt the tile mode from the backdrop filter
    // and instead needs it supplied to the saveLayer call itself as a
    // separate argument.
    final EngineImageFilter engineFilter;
    if (imageFilter is ui.ColorFilter) {
      engineFilter = EngineColorFilterImageFilter(colorFilter: imageFilter as EngineColorFilter);
    } else {
      engineFilter = imageFilter as EngineImageFilter;
    }
    final backendFilter =
        engineFilter.getBackendFilter(defaultBlurTileMode: ui.TileMode.mirror) as SkwasmImageFilter;
    final ImageFilterHandle nativeFilterHandle = backendFilter.nativeFilter;

    final backendPaint =
        (paint as EnginePaint).createBackendPaint(/*ui.TileMode.decal*/) as SkwasmPaint;
    if (bounds != null) {
      withStackScope((StackScope s) {
        canvasSaveLayer(
          _handle,
          s.convertRectToNative(bounds),
          backendPaint.handle,
          nativeFilterHandle,
        );
      });
    } else {
      canvasSaveLayer(_handle, nullptr, backendPaint.handle, nativeFilterHandle);
    }
    backendPaint.dispose();
  }

  @override
  void restore() {
    canvasRestore(_handle);
  }

  @override
  void restoreToCount(int count) {
    canvasRestoreToCount(_handle, count);
  }

  @override
  int getSaveCount() => canvasGetSaveCount(_handle);

  @override
  void translate(double dx, double dy) => canvasTranslate(_handle, dx, dy);

  @override
  void scale(double sx, [double? sy]) => canvasScale(_handle, sx, sy ?? sx);

  @override
  void rotate(double radians) => canvasRotate(_handle, ui.toDegrees(radians));

  @override
  void skew(double sx, double sy) => canvasSkew(_handle, sx, sy);

  @override
  void transform(Float64List matrix4) {
    withStackScope((StackScope s) {
      canvasTransform(_handle, s.convertMatrix44toNative(matrix4));
    });
  }

  @override
  void clipRect(ui.Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    withStackScope((StackScope s) {
      canvasClipRect(_handle, s.convertRectToNative(rect), clipOp.index, doAntiAlias);
    });
  }

  @override
  void clipRRect(ui.RRect rrect, {bool doAntiAlias = true}) {
    withStackScope((StackScope s) {
      canvasClipRRect(_handle, s.convertRRectToNative(rrect), doAntiAlias);
    });
  }

  @override
  void clipRSuperellipse(ui.RSuperellipse rsuperellipse, {bool doAntiAlias = true}) {
    final (ui.Path path, ui.Offset offset) = rsuperellipse.toPathOffset();
    translate(offset.dx, offset.dy);
    clipPath(path, doAntiAlias: doAntiAlias);
    translate(-offset.dx, -offset.dy);
  }

  @override
  void clipPath(ui.Path path, {bool doAntiAlias = true}) {
    canvasClipPath(_handle, ((path as EnginePath).backendPath as SkwasmPath).handle, doAntiAlias);
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) =>
      canvasDrawColor(_handle, color.value, blendMode.index);

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    canvasDrawLine(_handle, p1.dx, p1.dy, p2.dx, p2.dy, backendPaint.handle);
    backendPaint.dispose();
  }

  @override
  void drawPaint(ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    canvasDrawPaint(_handle, backendPaint.handle);
    backendPaint.dispose();
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawRect(_handle, s.convertRectToNative(rect), backendPaint.handle);
    });
    backendPaint.dispose();
  }

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawRRect(_handle, s.convertRRectToNative(rrect), backendPaint.handle);
    });
    backendPaint.dispose();
  }

  @override
  void drawRSuperellipse(ui.RSuperellipse rsuperellipse, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final (ui.Path path, ui.Offset offset) = rsuperellipse.toPathOffset();
    translate(offset.dx, offset.dy);
    drawPath(path, paint);
    translate(-offset.dx, -offset.dy);
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawDRRect(
        _handle,
        s.convertRRectToNative(outer),
        s.convertRRectToNative(inner),
        backendPaint.handle,
      );
    });
    backendPaint.dispose();
  }

  @override
  void drawOval(ui.Rect rect, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawOval(_handle, s.convertRectToNative(rect), backendPaint.handle);
    });
    backendPaint.dispose();
  }

  @override
  void drawCircle(ui.Offset center, double radius, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    canvasDrawCircle(_handle, center.dx, center.dy, radius, backendPaint.handle);
    backendPaint.dispose();
  }

  @override
  void drawArc(ui.Rect rect, double startAngle, double sweepAngle, bool useCenter, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawArc(
        _handle,
        s.convertRectToNative(rect),
        ui.toDegrees(startAngle),
        ui.toDegrees(sweepAngle),
        useCenter,
        backendPaint.handle,
      );
    });
    backendPaint.dispose();
  }

  @override
  void drawPath(ui.Path path, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    final enginePath = path as EnginePath;
    final skwasmPath = enginePath.backendPath as SkwasmPath;
    canvasDrawPath(_handle, skwasmPath.handle, backendPaint.handle);
    backendPaint.dispose();
  }

  ImageHandle _getImageHandle(ui.Image image) {
    if (image case EngineImage(backendImage: SkwasmImage(:final handle))) {
      return handle;
    }
    throw ArgumentError('The image being drawn must be a Skwasm image.');
  }

  @override
  void drawImage(ui.Image image, ui.Offset offset, ui.Paint paint) {
    _tracker?.recordImage(image);
    _tracker?.recordPaint(paint);
    final ImageHandle imageHandle = _getImageHandle(image);
    final backendPaint = (paint as EnginePaint).createBackendPaint(
      defaultBlurTileMode: ui.TileMode.clamp,
    ) as SkwasmPaint;
    canvasDrawImage(
      _handle,
      imageHandle,
      offset.dx,
      offset.dy,
      backendPaint.handle,
      paint.filterQuality.index,
    );
    backendPaint.dispose();
  }

  @override
  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {
    _tracker?.recordImage(image);
    _tracker?.recordPaint(paint);
    final ImageHandle imageHandle = _getImageHandle(image);
    withStackScope((StackScope scope) {
      final Pointer<Float> sourceRect = scope.convertRectToNative(src);
      final Pointer<Float> destRect = scope.convertRectToNative(dst);
      final backendPaint = (paint as EnginePaint).createBackendPaint(
        defaultBlurTileMode: ui.TileMode.clamp,
      ) as SkwasmPaint;
      canvasDrawImageRect(
        _handle,
        imageHandle,
        sourceRect,
        destRect,
        backendPaint.handle,
        paint.filterQuality.index,
      );
      backendPaint.dispose();
    });
  }

  @override
  void drawImageNine(ui.Image image, ui.Rect center, ui.Rect dst, ui.Paint paint) {
    _tracker?.recordImage(image);
    _tracker?.recordPaint(paint);
    final ImageHandle imageHandle = _getImageHandle(image);
    withStackScope((StackScope scope) {
      final Pointer<Int32> centerRect = scope.convertIRectToNative(center);
      final Pointer<Float> destRect = scope.convertRectToNative(dst);
      final backendPaint = (paint as EnginePaint).createBackendPaint(
        defaultBlurTileMode: ui.TileMode.clamp,
      ) as SkwasmPaint;
      canvasDrawImageNine(
        _handle,
        imageHandle,
        centerRect,
        destRect,
        backendPaint.handle,
        paint.filterQuality.index,
      );
      backendPaint.dispose();
    });
  }

  @override
  void drawPicture(ui.Picture picture) {
    if (picture case SkwasmPicture(:final imageTracker?)) {
      _tracker?.recordFrom(imageTracker);
    }
    canvasDrawPicture(_handle, (picture as SkwasmPicture).handle);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    // Note: Skwasm paragraphs are pre-built via ParagraphBuilder and their
    // paint styles/shaders are managed directly by Skwasm's native paragraph.
    canvasDrawParagraph(
      _handle,
      ((paragraph as EngineParagraph).backendParagraph as SkwasmParagraph).handle,
      offset.dx,
      offset.dy,
    );
  }

  /// Draws a sequence of points according to [pointMode].
  ///
  /// Retains any image sources referenced by [paint] (such as an [ImageShader]).
  @override
  void drawPoints(ui.PointMode pointMode, List<ui.Offset> points, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    withStackScope((StackScope scope) {
      final RawPointArray rawPoints = scope.convertPointArrayToNative(points);
      final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
      canvasDrawPoints(_handle, pointMode.index, rawPoints, points.length, backendPaint.handle);
      backendPaint.dispose();
    });
  }

  /// Draws a sequence of points from raw float coordinates according to [pointMode].
  ///
  /// Retains any image sources referenced by [paint] (such as an [ImageShader]).
  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, ui.Paint paint) {
    _tracker?.recordPaint(paint);
    withStackScope((StackScope scope) {
      final RawPointArray rawPoints = scope.convertDoublesToNative(points);
      final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
      canvasDrawPoints(
        _handle,
        pointMode.index,
        rawPoints,
        points.length ~/ 2,
        backendPaint.handle,
      );
      backendPaint.dispose();
    });
  }

  /// Draws a set of triangles/vertices with optional texture coordinates and colors.
  ///
  /// Retains any image sources referenced by [paint] (such as an [ImageShader]).
  @override
  void drawVertices(ui.Vertices vertices, ui.BlendMode blendMode, ui.Paint paint) {
    final skwasmVertices = (vertices as EngineVertices).delegate as SkwasmVertices?;
    if (skwasmVertices == null) {
      return;
    }
    _tracker?.recordPaint(paint);
    final backendPaint = (paint as EnginePaint).createBackendPaint() as SkwasmPaint;
    canvasDrawVertices(_handle, skwasmVertices.handle, blendMode.index, backendPaint.handle);
    backendPaint.dispose();
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
    _tracker?.recordImage(atlas);
    _tracker?.recordPaint(paint);
    final ImageHandle atlasHandle = _getImageHandle(atlas);
    withStackScope((StackScope scope) {
      final RawRSTransformArray rawTransforms = scope.convertRSTransformsToNative(transforms);
      final RawRect rawRects = scope.convertRectsToNative(rects);
      final RawColorArray rawColors = colors != null
          ? scope.convertColorArrayToNative(colors)
          : nullptr;
      final RawRect rawCullRect = cullRect != null ? scope.convertRectToNative(cullRect) : nullptr;

      final backendPaint = (paint as EnginePaint).createBackendPaint(
        defaultBlurTileMode: ui.TileMode.clamp,
      ) as SkwasmPaint;

      canvasDrawAtlas(
        _handle,
        atlasHandle,
        rawTransforms,
        rawRects,
        rawColors,
        transforms.length,
        (blendMode ?? ui.BlendMode.src).index,
        rawCullRect,
        backendPaint.handle,
        paint.filterQuality.index,
      );

      backendPaint.dispose();
    });
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
    _tracker?.recordImage(atlas);
    _tracker?.recordPaint(paint);
    final ImageHandle atlasHandle = _getImageHandle(atlas);
    withStackScope((StackScope scope) {
      final RawRSTransformArray rawTransforms = scope.convertDoublesToNative(rstTransforms);
      final RawRect rawRects = scope.convertDoublesToNative(rects);
      final RawColorArray rawColors = colors != null
          ? scope.convertIntsToUint32Native(colors)
          : nullptr;
      final RawRect rawCullRect = cullRect != null ? scope.convertRectToNative(cullRect) : nullptr;

      final backendPaint = (paint as EnginePaint).createBackendPaint(
        defaultBlurTileMode: ui.TileMode.clamp,
      ) as SkwasmPaint;

      canvasDrawAtlas(
        _handle,
        atlasHandle,
        rawTransforms,
        rawRects,
        rawColors,
        rstTransforms.length ~/ 4,
        (blendMode ?? ui.BlendMode.src).index,
        rawCullRect,
        backendPaint.handle,
        paint.filterQuality.index,
      );

      backendPaint.dispose();
    });
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation, bool transparentOccluder) {
    canvasDrawShadow(
      _handle,
      ((path as EnginePath).backendPath as SkwasmPath).handle,
      elevation,
      EngineFlutterDisplay.instance.devicePixelRatio,
      color.value,
      transparentOccluder,
    );
  }

  @override
  ui.Rect getDestinationClipBounds() {
    return withStackScope((StackScope scope) {
      final Pointer<Int32> outRect = scope.allocInt32Array(4);
      canvasGetDeviceClipBounds(_handle, outRect);
      return scope.convertIRectFromNative(outRect);
    });
  }

  @override
  ui.Rect getLocalClipBounds() {
    final Float64List transform = getTransform();
    final matrix = Matrix4.fromFloat32List(Float32List.fromList(transform));
    if (matrix.invert() == 0) {
      // non-invertible transforms collapse space to a line or point
      return ui.Rect.zero;
    }
    return matrix.transformRect(getDestinationClipBounds());
  }

  @override
  Float64List getTransform() {
    return withStackScope((StackScope scope) {
      final Pointer<Float> outMatrix = scope.allocFloatArray(16);
      canvasGetTransform(_handle, outMatrix);
      return scope.convertMatrix44FromNative(outMatrix);
    });
  }

  @override
  void clear(ui.Color color) {
    canvasClear(_handle, color.value);
  }

  @override
  bool quickReject(ui.Rect rect) {
    return withStackScope((StackScope s) {
      return canvasQuickReject(_handle, s.convertRectToNative(rect));
    });
  }
}
