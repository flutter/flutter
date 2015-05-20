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

  void setLTRB(double left, double top, double right, double bottom) {
    _value = new Float32List.fromList([left, top, right, bottom]);
  }
}
