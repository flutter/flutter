// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

/// The Skwasm [BackendCanvas]: translates canvas operations into calls on a
/// native canvas.
///
/// This class is stateless apart from the native canvas handle it wraps.
/// Validation, image tracking and paint lifetimes are handled by
/// [EngineCanvas].
class SkwasmCanvas implements BackendCanvas {
  /// Creates a backend canvas that draws into the native canvas [handle].
  SkwasmCanvas(CanvasHandle handle) : _handle = handle;

  // Note that we do not need to deal with the finalizer registry here, because
  // the underlying native skia object is tied directly to the lifetime of the
  // associated SkPictureRecorder.
  final CanvasHandle _handle;

  static ImageHandle _getImageHandle(BackendImage image) {
    return image is SkwasmImage
        ? image.handle
        : throw ArgumentError('The image being drawn must be a Skwasm image.');
  }

  @override
  void save() {
    canvasSave(_handle);
  }

  @override
  void saveLayer(ui.Rect? bounds, BackendPaint paint) {
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    if (bounds != null) {
      withStackScope((StackScope s) {
        canvasSaveLayer(_handle, s.convertRectToNative(bounds), paintHandle, nullptr);
      });
    } else {
      canvasSaveLayer(_handle, nullptr, paintHandle, nullptr);
    }
  }

  /// Saves a layer with a backdrop filter.
  ///
  /// [backdropTileMode] is ignored: the native Skwasm `saveLayer` doesn't take
  /// a backdrop tile mode yet. That needs a change in the Skwasm C++ code.
  @override
  void saveLayerWithFilter(
    ui.Rect? bounds,
    BackendPaint paint,
    BackendImageFilter backdropFilter,
    ui.TileMode backdropTileMode,
  ) {
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    final ImageFilterHandle nativeFilterHandle = (backdropFilter as SkwasmImageFilter).nativeFilter;
    if (bounds != null) {
      withStackScope((StackScope s) {
        canvasSaveLayer(_handle, s.convertRectToNative(bounds), paintHandle, nativeFilterHandle);
      });
    } else {
      canvasSaveLayer(_handle, nullptr, paintHandle, nativeFilterHandle);
    }
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
  void scale(double sx, double sy) => canvasScale(_handle, sx, sy);

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
  Float64List getTransform() {
    return withStackScope((StackScope scope) {
      final Pointer<Float> outMatrix = scope.allocFloatArray(16);
      canvasGetTransform(_handle, outMatrix);
      return scope.convertMatrix44FromNative(outMatrix);
    });
  }

  @override
  void clipRect(ui.Rect rect, ui.ClipOp clipOp, bool doAntiAlias) {
    withStackScope((StackScope s) {
      canvasClipRect(_handle, s.convertRectToNative(rect), clipOp.index, doAntiAlias);
    });
  }

  @override
  void clipRRect(ui.RRect rrect, bool doAntiAlias) {
    withStackScope((StackScope s) {
      canvasClipRRect(_handle, s.convertRRectToNative(rrect), doAntiAlias);
    });
  }

  @override
  void clipPath(BackendPath path, bool doAntiAlias) {
    canvasClipPath(_handle, (path as SkwasmPath).handle, doAntiAlias);
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
  void clear(ui.Color color) {
    canvasClear(_handle, color.value);
  }

  @override
  bool quickReject(ui.Rect rect) {
    return withStackScope((StackScope s) {
      return canvasQuickReject(_handle, s.convertRectToNative(rect));
    });
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) =>
      canvasDrawColor(_handle, color.value, blendMode.index);

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, BackendPaint paint) {
    canvasDrawLine(_handle, p1.dx, p1.dy, p2.dx, p2.dy, (paint as SkwasmPaint).handle);
  }

  @override
  void drawPaint(BackendPaint paint) {
    canvasDrawPaint(_handle, (paint as SkwasmPaint).handle);
  }

  @override
  void drawRect(ui.Rect rect, BackendPaint paint) {
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    withStackScope((StackScope s) {
      canvasDrawRect(_handle, s.convertRectToNative(rect), paintHandle);
    });
  }

  @override
  void drawRRect(ui.RRect rrect, BackendPaint paint) {
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    withStackScope((StackScope s) {
      canvasDrawRRect(_handle, s.convertRRectToNative(rrect), paintHandle);
    });
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, BackendPaint paint) {
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    withStackScope((StackScope s) {
      canvasDrawDRRect(
        _handle,
        s.convertRRectToNative(outer),
        s.convertRRectToNative(inner),
        paintHandle,
      );
    });
  }

  @override
  void drawOval(ui.Rect rect, BackendPaint paint) {
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    withStackScope((StackScope s) {
      canvasDrawOval(_handle, s.convertRectToNative(rect), paintHandle);
    });
  }

  @override
  void drawCircle(ui.Offset center, double radius, BackendPaint paint) {
    canvasDrawCircle(_handle, center.dx, center.dy, radius, (paint as SkwasmPaint).handle);
  }

  @override
  void drawArc(
    ui.Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    BackendPaint paint,
  ) {
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    withStackScope((StackScope s) {
      canvasDrawArc(
        _handle,
        s.convertRectToNative(rect),
        ui.toDegrees(startAngle),
        ui.toDegrees(sweepAngle),
        useCenter,
        paintHandle,
      );
    });
  }

  @override
  void drawPath(BackendPath path, BackendPaint paint) {
    canvasDrawPath(_handle, (path as SkwasmPath).handle, (paint as SkwasmPaint).handle);
  }

  @override
  void drawImage(
    BackendImage image,
    ui.Offset offset,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  ) {
    canvasDrawImage(
      _handle,
      _getImageHandle(image),
      offset.dx,
      offset.dy,
      (paint as SkwasmPaint).handle,
      filterQuality.index,
    );
  }

  @override
  void drawImageRect(
    BackendImage image,
    ui.Rect src,
    ui.Rect dst,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  ) {
    final ImageHandle imageHandle = _getImageHandle(image);
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    withStackScope((StackScope scope) {
      final Pointer<Float> sourceRect = scope.convertRectToNative(src);
      final Pointer<Float> destRect = scope.convertRectToNative(dst);
      canvasDrawImageRect(
        _handle,
        imageHandle,
        sourceRect,
        destRect,
        paintHandle,
        filterQuality.index,
      );
    });
  }

  @override
  void drawImageNine(
    BackendImage image,
    ui.Rect center,
    ui.Rect dst,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  ) {
    final ImageHandle imageHandle = _getImageHandle(image);
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    withStackScope((StackScope scope) {
      final Pointer<Int32> centerRect = scope.convertIRectToNative(center);
      final Pointer<Float> destRect = scope.convertRectToNative(dst);
      canvasDrawImageNine(
        _handle,
        imageHandle,
        centerRect,
        destRect,
        paintHandle,
        filterQuality.index,
      );
    });
  }

  @override
  void drawPicture(ui.Picture picture) {
    canvasDrawPicture(_handle, (picture as SkwasmPicture).handle);
  }

  @override
  void drawParagraph(BackendParagraph paragraph, ui.Offset offset) {
    canvasDrawParagraph(_handle, (paragraph as SkwasmParagraph).handle, offset.dx, offset.dy);
  }

  @override
  void drawPoints(ui.PointMode pointMode, Float32List points, BackendPaint paint) {
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    withStackScope((StackScope scope) {
      final RawPointArray rawPoints = scope.convertFloat32ListToNative(points);
      canvasDrawPoints(_handle, pointMode.index, rawPoints, points.length ~/ 2, paintHandle);
    });
  }

  @override
  void drawVertices(BackendVertices vertices, ui.BlendMode blendMode, BackendPaint paint) {
    canvasDrawVertices(
      _handle,
      (vertices as SkwasmVertices).handle,
      blendMode.index,
      (paint as SkwasmPaint).handle,
    );
  }

  @override
  void drawAtlas(
    BackendImage atlas,
    Float32List rstTransforms,
    Float32List rects,
    Uint32List? colors,
    ui.BlendMode blendMode,
    ui.Rect? cullRect,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  ) {
    final ImageHandle atlasHandle = _getImageHandle(atlas);
    final PaintHandle paintHandle = (paint as SkwasmPaint).handle;
    withStackScope((StackScope scope) {
      final RawRSTransformArray rawTransforms = scope.convertFloat32ListToNative(rstTransforms);
      final RawRect rawRects = scope.convertFloat32ListToNative(rects);
      final RawColorArray rawColors = (colors == null || colors.isEmpty)
          ? nullptr
          : scope.convertUint32ListToNative(colors);
      final RawRect rawCullRect = cullRect == null ? nullptr : scope.convertRectToNative(cullRect);

      canvasDrawAtlas(
        _handle,
        atlasHandle,
        rawTransforms,
        rawRects,
        rawColors,
        rstTransforms.length ~/ 4,
        blendMode.index,
        rawCullRect,
        paintHandle,
        filterQuality.index,
      );
    });
  }

  @override
  void drawShadow(
    BackendPath path,
    ui.Color color,
    double elevation,
    bool transparentOccluder,
    double devicePixelRatio,
  ) {
    canvasDrawShadow(
      _handle,
      (path as SkwasmPath).handle,
      elevation,
      devicePixelRatio,
      color.value,
      transparentOccluder,
    );
  }
}
