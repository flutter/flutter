// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

bool rectIsValid(ui.Rect rect) {
  assert(rect != null, 'Rect argument was null.'); // ignore: unnecessary_null_comparison
  assert(
      !(rect.left.isNaN ||
          rect.right.isNaN ||
          rect.top.isNaN ||
          rect.bottom.isNaN),
      'Rect argument contained a NaN value.');
  return true;
}

bool rrectIsValid(ui.RRect rrect) {
  assert(rrect != null, 'RRect argument was null.'); // ignore: unnecessary_null_comparison
  assert(
      !(rrect.left.isNaN ||
          rrect.right.isNaN ||
          rrect.top.isNaN ||
          rrect.bottom.isNaN),
      'RRect argument contained a NaN value.');
  return true;
}

bool offsetIsValid(ui.Offset offset) {
  assert(offset != null, 'Offset argument was null.'); // ignore: unnecessary_null_comparison
  assert(!offset.dx.isNaN && !offset.dy.isNaN,
      'Offset argument contained a NaN value.');
  return true;
}

bool matrix4IsValid(Float32List matrix4) {
  assert(matrix4 != null, 'Matrix4 argument was null.'); // ignore: unnecessary_null_comparison
  assert(matrix4.length == 16, 'Matrix4 must have 16 entries.');
  return true;
}

bool radiusIsValid(ui.Radius radius) {
  assert(radius != null, 'Radius argument was null.'); // ignore: unnecessary_null_comparison
  assert(!radius.x.isNaN && !radius.y.isNaN,
      'Radius argument contained a NaN value.');
  return true;
}
