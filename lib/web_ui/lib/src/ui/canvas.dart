// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of ui;

enum PointMode {
  points,
  lines,
  polygon,
}

enum ClipOp {
  difference,
  intersect,
}

enum VertexMode {
  triangles,
  triangleStrip,
  triangleFan,
}

class Vertices {
  factory Vertices(
    VertexMode mode,
    List<Offset> positions, {
    List<Offset>? textureCoordinates,
    List<Color>? colors,
    List<int>? indices,
  }) {
    if (engine.useCanvasKit) {
      return engine.CkVertices(
        mode,
        positions,
        textureCoordinates: textureCoordinates,
        colors: colors,
        indices: indices,
      );
    }
    return engine.SurfaceVertices(
      mode,
      positions,
      colors: colors,
      indices: indices,
    );
  }
  factory Vertices.raw(
    VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  }) {
    if (engine.useCanvasKit) {
      return engine.CkVertices.raw(
        mode,
        positions,
        textureCoordinates: textureCoordinates,
        colors: colors,
        indices: indices,
      );
    }
    return engine.SurfaceVertices.raw(
      mode,
      positions,
      colors: colors,
      indices: indices,
    );
  }
}

abstract class PictureRecorder {
  factory PictureRecorder() {
    if (engine.useCanvasKit) {
      return engine.CkPictureRecorder();
    } else {
      return engine.EnginePictureRecorder();
    }
  }
  bool get isRecording;
  Picture endRecording();
}

abstract class Canvas {
  factory Canvas(PictureRecorder recorder, [Rect? cullRect]) {
    if (engine.useCanvasKit) {
      return engine.CanvasKitCanvas(recorder, cullRect);
    } else {
      return engine.SurfaceCanvas(recorder as engine.EnginePictureRecorder, cullRect);
    }
  }
  void save();
  void saveLayer(Rect? bounds, Paint paint);
  void restore();
  int getSaveCount();
  void translate(double dx, double dy);
  void scale(double sx, [double? sy]);
  void rotate(double radians);
  void skew(double sx, double sy);
  void transform(Float64List matrix4);
  void clipRect(Rect rect, {ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true});
  void clipRRect(RRect rrect, {bool doAntiAlias = true});
  void clipPath(Path path, {bool doAntiAlias = true});
  void drawColor(Color color, BlendMode blendMode);
  void drawLine(Offset p1, Offset p2, Paint paint);
  void drawPaint(Paint paint);
  void drawRect(Rect rect, Paint paint);
  void drawRRect(RRect rrect, Paint paint);
  void drawDRRect(RRect outer, RRect inner, Paint paint);
  void drawOval(Rect rect, Paint paint);
  void drawCircle(Offset c, double radius, Paint paint);
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint);
  void drawPath(Path path, Paint paint);
  void drawImage(Image image, Offset offset, Paint paint);
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint);
  void drawImageNine(Image image, Rect center, Rect dst, Paint paint);
  void drawPicture(Picture picture);
  void drawParagraph(Paragraph paragraph, Offset offset);
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint);
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint);

  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint);
  void drawAtlas(
    Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  );
  void drawRawAtlas(
    Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  );
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  );
}

abstract class Picture {
  Future<Image> toImage(int width, int height);
  void dispose();
  int get approximateBytesUsed;
}

enum PathFillType {
  nonZero,
  evenOdd,
}
// Must be kept in sync with SkPathOp

enum PathOperation {
  difference,
  intersect,
  union,
  xor,
  reverseDifference,
}
