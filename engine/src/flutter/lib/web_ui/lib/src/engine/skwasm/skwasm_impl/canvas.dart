// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmCanvas implements ui.Canvas {
  factory SkwasmCanvas(SkwasmPictureRecorder recorder, ui.Rect cullRect) =>
      SkwasmCanvas.fromHandle(withStackScope((StackScope s) =>
          pictureRecorderBeginRecording(
              recorder.handle, s.convertRectToNative(cullRect))));

  SkwasmCanvas.fromHandle(this._handle);
  CanvasHandle _handle;

  void delete() {
    canvasDestroy(_handle);
  }

  @override
  void save() {
    canvasSave(_handle);
  }

  @override
  void saveLayer(ui.Rect? bounds, ui.Paint paint) {
    paint as SkwasmPaint;
    if (bounds != null) {
      withStackScope((StackScope s) {
        canvasSaveLayer(_handle, s.convertRectToNative(bounds), paint.handle);
      });
    } else {
      canvasSaveLayer(_handle, nullptr, paint.handle);
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
  void clipRect(ui.Rect rect,
      {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
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
  void clipPath(ui.Path path, {bool doAntiAlias = true}) {
    path as SkwasmPath;
    canvasClipPath(_handle, path.handle, doAntiAlias);
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) =>
      canvasDrawColor(_handle, color.value, blendMode.index);

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {
    paint as SkwasmPaint;
    canvasDrawLine(_handle, p1.dx, p1.dy, p2.dx, p2.dy, paint.handle);
  }

  @override
  void drawPaint(ui.Paint paint) {
    paint as SkwasmPaint;
    canvasDrawPaint(_handle, paint.handle);
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    paint as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawRect(
        _handle,
        s.convertRectToNative(rect),
        paint.handle
      );
    });
  }

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) {
    paint as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawRRect(
        _handle,
        s.convertRRectToNative(rrect),
        paint.handle
      );
    });
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {
    paint as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawDRRect(
        _handle,
        s.convertRRectToNative(outer),
        s.convertRRectToNative(inner),
        paint.handle
      );
    });
  }

  @override
  void drawOval(ui.Rect rect, ui.Paint paint) {
    paint as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawOval(_handle, s.convertRectToNative(rect), paint.handle);
    });
  }

  @override
  void drawCircle(ui.Offset center, double radius, ui.Paint paint) {
    paint as SkwasmPaint;
    canvasDrawCircle(_handle, center.dx, center.dy, radius, paint.handle);
  }

  @override
  void drawArc(ui.Rect rect, double startAngle, double sweepAngle,
      bool useCenter, ui.Paint paint) {
    paint as SkwasmPaint;
    withStackScope((StackScope s) {
      canvasDrawArc(
        _handle,
        s.convertRectToNative(rect),
        ui.toDegrees(startAngle),
        ui.toDegrees(sweepAngle),
        useCenter,
        paint.handle
      );
    });
  }

  @override
  void drawPath(ui.Path path, ui.Paint paint) {
    paint as SkwasmPaint;
    path as SkwasmPath;
    canvasDrawPath(_handle, path.handle, paint.handle);
  }

  @override
  void drawImage(ui.Image uiImage, ui.Offset offset, ui.Paint uiPaint) {
    throw UnimplementedError();
  }

  @override
  void drawImageRect(
      ui.Image uiImage, ui.Rect src, ui.Rect dst, ui.Paint uiPaint) {
    throw UnimplementedError();
  }

  @override
  void drawImageNine(
      ui.Image uiImage, ui.Rect center, ui.Rect dst, ui.Paint uiPaint) {
    throw UnimplementedError();
  }

  @override
  void drawPicture(ui.Picture picture) {
    canvasDrawPicture(_handle, (picture as SkwasmPicture).handle);
  }

  @override
  void drawParagraph(ui.Paragraph uiParagraph, ui.Offset offset) {
    // TODO(jacksongardner): implement this
  }

  @override
  void drawPoints(
      ui.PointMode pointMode, List<ui.Offset> points, ui.Paint paint) {
    throw UnimplementedError();
  }

  @override
  void drawRawPoints(
      ui.PointMode pointMode, Float32List points, ui.Paint paint) {
    throw UnimplementedError();
  }

  @override
  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, ui.Paint paint) {
    throw UnimplementedError();
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
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  void drawShadow(
    ui.Path path,
    ui.Color color,
    double elevation,
    bool transparentOccluder,
  ) {
    path as SkwasmPath;
    canvasDrawShadow(
      _handle,
      path.handle,
      elevation,
      ui.window.devicePixelRatio,
      color.value,
      transparentOccluder);
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
    final Matrix4 matrix = Matrix4.fromFloat32List(Float32List.fromList(transform));
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
}
