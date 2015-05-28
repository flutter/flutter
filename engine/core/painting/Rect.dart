// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

class Rect {
  Float32List _value;
  double get left => _value[0];
  double get top => _value[1];
  double get right => _value[2];
  double get bottom => _value[3];

  Rect() : new Float32List(4);

  Rect.fromPointAndSize(Point point, Size size) {
    _value = new Float32List(4)
        ..[0] = point.x
        ..[1] = point.y
        ..[2] = point.x + size.width
        ..[3] = point.y + size.height;
  }

  Rect.fromLTRB(double left, double top, double right, double bottom) {
    _value = new Float32List(4)
        ..[0] = left
        ..[1] = top
        ..[2] = right
        ..[3] = bottom;
  }

  Point get upperLeft => new Point(left, top);
  Point get lowerRight => new Point(right, bottom);

  Size get size => new Size(right - left, bottom - top);

  // Rects are inclusive of the top and left edges but exclusive of the bottom
  // right edges.
  bool contains(Point point) => point.x >= left && point.x < right
                             && point.y >= top && point.y < bottom;

  void setLTRB(double left, double top, double right, double bottom) {
    _value[0] = left
        ..[1] = top
        ..[2] = right
        ..[3] = bottom;
  }
}
