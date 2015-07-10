// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

abstract class OffsetBase {
  const OffsetBase(this._dx, this._dy);

  final double _dx;
  final double _dy;

  bool get isInfinite => _dx >= double.INFINITY || _dy >= double.INFINITY;

  bool operator <(OffsetBase other) => _dx < other._dx && _dy < other._dy;
  bool operator <=(OffsetBase other) => _dx <= other._dx && _dy <= other._dy;
  bool operator >(OffsetBase other) => _dx > other._dx && _dy > other._dy;
  bool operator >=(OffsetBase other) => _dx > other._dx && _dy >= other._dy;

  bool operator ==(other) {
    return other is OffsetBase &&
           other.runtimeType == runtimeType &&
           other._dx == _dx &&
           other._dy == _dy;
  }

  int get hashCode {
    int result = 373;
    result = 37 * result + _dx.hashCode;
    result = 37 * result + _dy.hashCode;
    return result;
  }
}
