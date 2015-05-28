// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// Holds 4 floating-point coordinates for a rectangle.
class Rect {
  final Float32List _value = new Float32List(4);
  double get left => _value[0];
  double get top => _value[1];
  double get right => _value[2];
  double get bottom => _value[3];

  Rect();

  Rect.fromPointAndSize(Point point, Size size) {
    _value
      ..[0] = point.x
      ..[1] = point.y
      ..[2] = point.x + size.width
      ..[3] = point.y + size.height;
  }

  Rect.fromSize(Size size) {
    _value
      ..[2] = size.width
      ..[3] = size.height;
  }

  Rect.fromLTRB(double left, double top, double right, double bottom) {
    _value
      ..[0] = left
      ..[1] = top
      ..[2] = right
      ..[3] = bottom;
  }

  Point get upperLeft => new Point(left, top);
  Point get lowerRight => new Point(right, bottom);
  Point get center => new Point(left + right / 2.0, top + bottom / 2.0);

  Size get size => new Size(right - left, bottom - top);

  // Rects are inclusive of the top and left edges but exclusive of the bottom
  // right edges.
  bool contains(Point point) =>
      point.x >= left && point.x < right && point.y >= top && point.y < bottom;

  bool operator ==(other) {
    if (!(other is Rect)) return false;
    for (var i = 0; i < 4; ++i) {
      if (_value[i] != other._value[i]) return false;
    }
    return true;
  }
  int get hashCode {
    return _value.fold(373, (value, item) => (37 * value + item.hashCode));
  }
  String toString() => "Rect.LTRB($left, $top, $right, $bottom)";
}
