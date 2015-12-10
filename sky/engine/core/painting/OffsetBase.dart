// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

abstract class OffsetBase {
  const OffsetBase(this._dx, this._dy);

  final double _dx;
  final double _dy;

  bool get isInfinite => _dx >= double.INFINITY || _dy >= double.INFINITY;

  bool operator <(OffsetBase other) => _dx < other._dx && _dy < other._dy;
  bool operator <=(OffsetBase other) => _dx <= other._dx && _dy <= other._dy;
  bool operator >(OffsetBase other) => _dx > other._dx && _dy > other._dy;
  bool operator >=(OffsetBase other) => _dx > other._dx && _dy >= other._dy;

  bool operator ==(dynamic other) {
    if (other is! OffsetBase)
      return false;
    final OffsetBase typedOther = other;
    return _dx == typedOther._dx &&
           _dy == typedOther._dy;
  }

  int get hashCode => hashValues(_dx, _dy);
}
