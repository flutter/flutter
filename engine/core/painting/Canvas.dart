// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This extends the Canvas.dart generated from Canvas.idl.

class Rect {
  List<double> _value;
  double get left => _value[0];
  double get top => _value[1];
  double get right => _value[2];
  double get bottom => _value[3];

  void setLTRB(double left, double top, double right, double bottom) {
    _value = [left, top, right, bottom];
  }
}

class Canvas extends _Canvas {
  double get height => _height;
  double get width => _width;

  void save() => _save();
  void saveLayer(Rect bounds, Paint paint) =>
      _saveLayer(bounds._value, Paint paint);
  void restore() => _restore();
  void translate(double dx, double dy) => _translate(dx, dy);
  void scale(double sx, double sy) => _scale(sx, sy);
  void rotateDegrees(double degrees) => _rotateDegrees(degrees);
  void skew(double sx, double sy) => _skew(sx, sy);
  void concat(List<double> matrix9) => _concat(matrix9);
  void clipRect(Rect rect) => _clipRect(rect._value);

  void drawPicture(Picture picture) => _drawPicture(picture);
  void drawPaint(Paint paint) => _drawPaint(paint);
  void drawRect(Rect rect, Paint paint) => _drawRect(rect._value, paint);
  void drawOval(Rect rect, Paint paint) => _drawOval(rect._value, paint);
  void drawCircle(double x, double y, double radius, Paint paint) =>
      _drawCircle(x, y, radius, paint);
}
