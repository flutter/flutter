// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// Holds a 2D floating-point size.
/// Think of this as a vector from Point(0,0) to Point(size.width, size.height)
class Size {
  const Size(this.width, this.height);
  const Size.fromWidth(this.width) : height = double.INFINITY;
  const Size.fromHeight(this.height) : width = double.INFINITY;

  final double width;
  final double height;

  static const Size zero = const Size(0.0, 0.0);
  static const Size infinite = const Size(double.INFINITY, double.INFINITY);

  bool operator ==(other) => other is Size && width == other.width && height == other.height;
  Size operator +(Size other) => new Size(width + other.width, height + other.height);
  Size operator -(Size other) => new Size(width - other.width, height - other.height);

  // does the equivalent of "return new Point(0,0) + this"
  Point toPoint() => new Point(this.width, this.height);

  int get hashCode {
    int result = 373;
    result = 37 * result + width.hashCode;
    result = 37 * result + height.hashCode;
    return result;
  }
  String toString() => "Size($width, $height)";
}
