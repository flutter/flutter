// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._simd;

import 'dart:_internal' show FixedLengthListMixin, IterableElementError;

import 'dart:collection' show ListMixin;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:_internal' show WasmTypedDataBase;
import 'dart:_wasm';

final class NaiveInt32x4List extends WasmTypedDataBase
    with ListMixin<Int32x4>, FixedLengthListMixin<Int32x4>
    implements Int32x4List {
  final Int32List _storage;

  NaiveInt32x4List(int length) : _storage = Int32List(length * 4);

  NaiveInt32x4List.externalStorage(Int32List storage) : _storage = storage;

  NaiveInt32x4List._slowFromList(List<Int32x4> list)
      : _storage = Int32List(list.length * 4) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 4) + 0] = e.x;
      _storage[(i * 4) + 1] = e.y;
      _storage[(i * 4) + 2] = e.z;
      _storage[(i * 4) + 3] = e.w;
    }
  }

  factory NaiveInt32x4List.fromList(List<Int32x4> list) {
    if (list is NaiveInt32x4List) {
      return NaiveInt32x4List.externalStorage(
          Int32List.fromList(list._storage));
    } else {
      return NaiveInt32x4List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Int32x4List.bytesPerElement;

  int get length => _storage.length ~/ 4;

  Int32x4 operator [](int index) {
    IndexError.check(index, length, indexable: this, name: "[]");
    int _x = _storage[(index * 4) + 0];
    int _y = _storage[(index * 4) + 1];
    int _z = _storage[(index * 4) + 2];
    int _w = _storage[(index * 4) + 3];
    return NaiveInt32x4._truncated(_x, _y, _z, _w);
  }

  void operator []=(int index, Int32x4 value) {
    IndexError.check(index, length, indexable: this, name: "[]=");
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  Int32x4List asUnmodifiableView() =>
      NaiveUnmodifiableInt32x4List.externalStorage(_storage);

  Int32x4List sublist(int start, [int? end]) {
    int stop = RangeError.checkValidRange(start, end, length);
    return NaiveInt32x4List.externalStorage(
        _storage.sublist(start * 4, stop * 4));
  }

  void setRange(int start, int end, Iterable<Int32x4> from,
      [int skipCount = 0]) {
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
    }
    if (skipCount < 0) {
      throw RangeError.range(skipCount, 0, null, "skipCount");
    }

    final count = end - start;
    if (count == 0) return;

    final List<Int32x4> fromList = from.skip(skipCount).toList(growable: false);

    if (fromList.length < count) {
      throw IterableElementError.tooFew();
    }

    for (int i = start; i < end; i += 1) {
      this[i] = fromList[i - start];
    }
  }
}

final class NaiveUnmodifiableInt32x4List extends NaiveInt32x4List {
  NaiveUnmodifiableInt32x4List.externalStorage(Int32List storage)
      : super.externalStorage(storage);

  @override
  void operator []=(int index, Int32x4 value) {
    throw new UnsupportedError("Cannot modify an unmodifiable list");
  }

  @override
  ByteBuffer get buffer => _storage.asUnmodifiableView().buffer;
}

final class NaiveFloat32x4List extends WasmTypedDataBase
    with ListMixin<Float32x4>, FixedLengthListMixin<Float32x4>
    implements Float32x4List {
  final Float32List _storage;

  NaiveFloat32x4List(int length) : _storage = Float32List(length * 4);

  NaiveFloat32x4List.externalStorage(this._storage);

  NaiveFloat32x4List._slowFromList(List<Float32x4> list)
      : _storage = Float32List(list.length * 4) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 4) + 0] = e.x;
      _storage[(i * 4) + 1] = e.y;
      _storage[(i * 4) + 2] = e.z;
      _storage[(i * 4) + 3] = e.w;
    }
  }

  factory NaiveFloat32x4List.fromList(List<Float32x4> list) {
    if (list is NaiveFloat32x4List) {
      return NaiveFloat32x4List.externalStorage(
          Float32List.fromList(list._storage));
    } else {
      return NaiveFloat32x4List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Float32x4List.bytesPerElement;

  int get length => _storage.length ~/ 4;

  Float32x4 operator [](int index) {
    IndexError.check(index, length, indexable: this, name: "[]");
    double _x = _storage[(index * 4) + 0];
    double _y = _storage[(index * 4) + 1];
    double _z = _storage[(index * 4) + 2];
    double _w = _storage[(index * 4) + 3];
    return NaiveFloat32x4._truncated(_x, _y, _z, _w);
  }

  void operator []=(int index, Float32x4 value) {
    IndexError.check(index, length, indexable: this, name: "[]=");
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  Float32x4List asUnmodifiableView() =>
      NaiveUnmodifiableFloat32x4List.externalStorage(_storage);

  Float32x4List sublist(int start, [int? end]) {
    int stop = RangeError.checkValidRange(start, end, length);
    return NaiveFloat32x4List.externalStorage(
        _storage.sublist(start * 4, stop * 4));
  }

  void setRange(int start, int end, Iterable<Float32x4> from,
      [int skipCount = 0]) {
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
    }
    if (skipCount < 0) {
      throw RangeError.range(skipCount, 0, null, "skipCount");
    }

    final count = end - start;
    if (count == 0) return;

    final List<Float32x4> fromList =
        from.skip(skipCount).toList(growable: false);

    if (fromList.length < count) {
      throw IterableElementError.tooFew();
    }

    for (int i = start; i < end; i += 1) {
      this[i] = fromList[i - start];
    }
  }
}

final class NaiveUnmodifiableFloat32x4List extends NaiveFloat32x4List {
  NaiveUnmodifiableFloat32x4List.externalStorage(Float32List storage)
      : super.externalStorage(storage);

  @override
  void operator []=(int index, Float32x4 value) {
    throw new UnsupportedError("Cannot modify an unmodifiable list");
  }

  @override
  ByteBuffer get buffer => _storage.asUnmodifiableView().buffer;
}

final class NaiveFloat64x2List extends WasmTypedDataBase
    with ListMixin<Float64x2>, FixedLengthListMixin<Float64x2>
    implements Float64x2List {
  final Float64List _storage;

  NaiveFloat64x2List(int length) : _storage = Float64List(length * 2);

  NaiveFloat64x2List.externalStorage(this._storage);

  NaiveFloat64x2List._slowFromList(List<Float64x2> list)
      : _storage = Float64List(list.length * 2) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 2) + 0] = e.x;
      _storage[(i * 2) + 1] = e.y;
    }
  }

  factory NaiveFloat64x2List.fromList(List<Float64x2> list) {
    if (list is NaiveFloat64x2List) {
      return NaiveFloat64x2List.externalStorage(
          Float64List.fromList(list._storage));
    } else {
      return NaiveFloat64x2List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Float64x2List.bytesPerElement;

  int get length => _storage.length ~/ 2;

  Float64x2 operator [](int index) {
    IndexError.check(index, length, indexable: this, name: "[]");
    double _x = _storage[(index * 2) + 0];
    double _y = _storage[(index * 2) + 1];
    return Float64x2(_x, _y);
  }

  void operator []=(int index, Float64x2 value) {
    IndexError.check(index, length, indexable: this, name: "[]=");
    _storage[(index * 2) + 0] = value.x;
    _storage[(index * 2) + 1] = value.y;
  }

  Float64x2List asUnmodifiableView() =>
      NaiveUnmodifiableFloat64x2List.externalStorage(_storage);

  Float64x2List sublist(int start, [int? end]) {
    int stop = RangeError.checkValidRange(start, end, length);
    return NaiveFloat64x2List.externalStorage(
        _storage.sublist(start * 2, stop * 2));
  }

  void setRange(int start, int end, Iterable<Float64x2> from,
      [int skipCount = 0]) {
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
    }
    if (skipCount < 0) {
      throw RangeError.range(skipCount, 0, null, "skipCount");
    }

    final count = end - start;
    if (count == 0) return;

    final List<Float64x2> fromList =
        from.skip(skipCount).toList(growable: false);

    if (fromList.length < count) {
      throw IterableElementError.tooFew();
    }

    for (int i = start; i < end; i += 1) {
      this[i] = fromList[i - start];
    }
  }
}

final class NaiveUnmodifiableFloat64x2List extends NaiveFloat64x2List {
  NaiveUnmodifiableFloat64x2List.externalStorage(Float64List storage)
      : super.externalStorage(storage);

  @override
  void operator []=(int index, Float64x2 value) {
    throw new UnsupportedError("Cannot modify an unmodifiable list");
  }

  @override
  ByteBuffer get buffer => _storage.asUnmodifiableView().buffer;
}

final class NaiveFloat32x4 extends WasmTypedDataBase implements Float32x4 {
  final double x;
  final double y;
  final double z;
  final double w;

  static final Float32List _list = Float32List(4);
  static final Uint32List _uint32view = _list.buffer.asUint32List();

  static double _truncate(x) {
    _list[0] = x;
    return _list[0];
  }

  NaiveFloat32x4(double x, double y, double z, double w)
      : this.x = _truncate(x),
        this.y = _truncate(y),
        this.z = _truncate(z),
        this.w = _truncate(w);

  NaiveFloat32x4.splat(double v) : this(v, v, v, v);
  NaiveFloat32x4.zero() : this._truncated(0.0, 0.0, 0.0, 0.0);

  factory NaiveFloat32x4.fromInt32x4Bits(Int32x4 i) {
    _uint32view[0] = i.x;
    _uint32view[1] = i.y;
    _uint32view[2] = i.z;
    _uint32view[3] = i.w;
    return NaiveFloat32x4._truncated(_list[0], _list[1], _list[2], _list[3]);
  }

  NaiveFloat32x4.fromFloat64x2(Float64x2 v)
      : this._truncated(_truncate(v.x), _truncate(v.y), 0.0, 0.0);

  NaiveFloat32x4._doubles(double x, double y, double z, double w)
      : this.x = _truncate(x),
        this.y = _truncate(y),
        this.z = _truncate(z),
        this.w = _truncate(w);

  NaiveFloat32x4._truncated(this.x, this.y, this.z, this.w);

  @override
  String toString() {
    return '[${x.toStringAsFixed(6)}, '
        '${y.toStringAsFixed(6)}, '
        '${z.toStringAsFixed(6)}, '
        '${w.toStringAsFixed(6)}]';
  }

  Float32x4 operator +(Float32x4 other) {
    double _x = x + other.x;
    double _y = y + other.y;
    double _z = z + other.z;
    double _w = w + other.w;
    return NaiveFloat32x4._doubles(_x, _y, _z, _w);
  }

  Float32x4 operator -() {
    return NaiveFloat32x4._truncated(-x, -y, -z, -w);
  }

  Float32x4 operator -(Float32x4 other) {
    double _x = x - other.x;
    double _y = y - other.y;
    double _z = z - other.z;
    double _w = w - other.w;
    return NaiveFloat32x4._doubles(_x, _y, _z, _w);
  }

  Float32x4 operator *(Float32x4 other) {
    double _x = x * other.x;
    double _y = y * other.y;
    double _z = z * other.z;
    double _w = w * other.w;
    return NaiveFloat32x4._doubles(_x, _y, _z, _w);
  }

  Float32x4 operator /(Float32x4 other) {
    double _x = x / other.x;
    double _y = y / other.y;
    double _z = z / other.z;
    double _w = w / other.w;
    return NaiveFloat32x4._doubles(_x, _y, _z, _w);
  }

  Int32x4 lessThan(Float32x4 other) {
    bool _cx = x < other.x;
    bool _cy = y < other.y;
    bool _cz = z < other.z;
    bool _cw = w < other.w;
    return NaiveInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  Int32x4 lessThanOrEqual(Float32x4 other) {
    bool _cx = x <= other.x;
    bool _cy = y <= other.y;
    bool _cz = z <= other.z;
    bool _cw = w <= other.w;
    return NaiveInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  Int32x4 greaterThan(Float32x4 other) {
    bool _cx = x > other.x;
    bool _cy = y > other.y;
    bool _cz = z > other.z;
    bool _cw = w > other.w;
    return NaiveInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  Int32x4 greaterThanOrEqual(Float32x4 other) {
    bool _cx = x >= other.x;
    bool _cy = y >= other.y;
    bool _cz = z >= other.z;
    bool _cw = w >= other.w;
    return NaiveInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  Int32x4 equal(Float32x4 other) {
    bool _cx = x == other.x;
    bool _cy = y == other.y;
    bool _cz = z == other.z;
    bool _cw = w == other.w;
    return NaiveInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  Int32x4 notEqual(Float32x4 other) {
    bool _cx = x != other.x;
    bool _cy = y != other.y;
    bool _cz = z != other.z;
    bool _cw = w != other.w;
    return NaiveInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  Float32x4 scale(double s) {
    double _x = s * x;
    double _y = s * y;
    double _z = s * z;
    double _w = s * w;
    return NaiveFloat32x4._doubles(_x, _y, _z, _w);
  }

  Float32x4 abs() {
    double _x = x.abs();
    double _y = y.abs();
    double _z = z.abs();
    double _w = w.abs();
    return NaiveFloat32x4._truncated(_x, _y, _z, _w);
  }

  Float32x4 clamp(Float32x4 lowerLimit, Float32x4 upperLimit) {
    double _lx = lowerLimit.x;
    double _ly = lowerLimit.y;
    double _lz = lowerLimit.z;
    double _lw = lowerLimit.w;
    double _ux = upperLimit.x;
    double _uy = upperLimit.y;
    double _uz = upperLimit.z;
    double _uw = upperLimit.w;
    double _x = x;
    double _y = y;
    double _z = z;
    double _w = w;
    // MAX(MIN(self, upper), lower).
    _x = _x > _ux ? _ux : _x;
    _y = _y > _uy ? _uy : _y;
    _z = _z > _uz ? _uz : _z;
    _w = _w > _uw ? _uw : _w;
    _x = _x < _lx ? _lx : _x;
    _y = _y < _ly ? _ly : _y;
    _z = _z < _lz ? _lz : _z;
    _w = _w < _lw ? _lw : _w;
    return NaiveFloat32x4._truncated(_x, _y, _z, _w);
  }

  int get signMask {
    var view = _uint32view;
    int mx, my, mz, mw;
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    mx = (view[0] & 0x80000000) >> 31;
    my = (view[1] & 0x80000000) >> 30;
    mz = (view[2] & 0x80000000) >> 29;
    mw = (view[3] & 0x80000000) >> 28;
    return mx | my | mz | mw;
  }

  Float32x4 shuffle(int mask) {
    // mask < 0 || mask > 255
    if (mask.gtU(255)) {
      throw RangeError.range(mask, 0, 255, 'mask');
    }
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;

    double _x = _list[mask & 0x3];
    double _y = _list[(mask >> 2) & 0x3];
    double _z = _list[(mask >> 4) & 0x3];
    double _w = _list[(mask >> 6) & 0x3];
    return NaiveFloat32x4._truncated(_x, _y, _z, _w);
  }

  Float32x4 shuffleMix(Float32x4 other, int mask) {
    // mask < 0 || mask > 255
    if (mask.gtU(255)) {
      throw RangeError.range(mask, 0, 255, 'mask');
    }
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    double _x = _list[mask & 0x3];
    double _y = _list[(mask >> 2) & 0x3];

    _list[0] = other.x;
    _list[1] = other.y;
    _list[2] = other.z;
    _list[3] = other.w;
    double _z = _list[(mask >> 4) & 0x3];
    double _w = _list[(mask >> 6) & 0x3];
    return NaiveFloat32x4._truncated(_x, _y, _z, _w);
  }

  Float32x4 withX(double newX) {
    double _newX = _truncate(newX);
    return NaiveFloat32x4._truncated(_newX, y, z, w);
  }

  Float32x4 withY(double newY) {
    double _newY = _truncate(newY);
    return NaiveFloat32x4._truncated(x, _newY, z, w);
  }

  Float32x4 withZ(double newZ) {
    double _newZ = _truncate(newZ);
    return NaiveFloat32x4._truncated(x, y, _newZ, w);
  }

  Float32x4 withW(double newW) {
    double _newW = _truncate(newW);
    return NaiveFloat32x4._truncated(x, y, z, _newW);
  }

  Float32x4 min(Float32x4 other) {
    double _x = x < other.x ? x : other.x;
    double _y = y < other.y ? y : other.y;
    double _z = z < other.z ? z : other.z;
    double _w = w < other.w ? w : other.w;
    return NaiveFloat32x4._truncated(_x, _y, _z, _w);
  }

  Float32x4 max(Float32x4 other) {
    double _x = x > other.x ? x : other.x;
    double _y = y > other.y ? y : other.y;
    double _z = z > other.z ? z : other.z;
    double _w = w > other.w ? w : other.w;
    return NaiveFloat32x4._truncated(_x, _y, _z, _w);
  }

  Float32x4 sqrt() {
    double _x = math.sqrt(x);
    double _y = math.sqrt(y);
    double _z = math.sqrt(z);
    double _w = math.sqrt(w);
    return NaiveFloat32x4._doubles(_x, _y, _z, _w);
  }

  Float32x4 reciprocal() {
    double _x = 1.0 / x;
    double _y = 1.0 / y;
    double _z = 1.0 / z;
    double _w = 1.0 / w;
    return NaiveFloat32x4._doubles(_x, _y, _z, _w);
  }

  Float32x4 reciprocalSqrt() {
    double _x = math.sqrt(1.0 / x);
    double _y = math.sqrt(1.0 / y);
    double _z = math.sqrt(1.0 / z);
    double _w = math.sqrt(1.0 / w);
    return NaiveFloat32x4._doubles(_x, _y, _z, _w);
  }
}

final class NaiveFloat64x2 extends WasmTypedDataBase implements Float64x2 {
  final double x;
  final double y;

  static Float64List _list = Float64List(2);
  static Uint32List _uint32View = _list.buffer.asUint32List();

  NaiveFloat64x2(this.x, this.y);

  NaiveFloat64x2.splat(double v) : this(v, v);

  NaiveFloat64x2.zero() : this.splat(0.0);

  NaiveFloat64x2.fromFloat32x4(Float32x4 v) : this(v.x, v.y);

  NaiveFloat64x2._doubles(this.x, this.y);

  String toString() => '[$x, $y]';

  Float64x2 operator +(Float64x2 other) =>
      NaiveFloat64x2._doubles(x + other.x, y + other.y);

  Float64x2 operator -() => NaiveFloat64x2._doubles(-x, -y);

  Float64x2 operator -(Float64x2 other) =>
      NaiveFloat64x2._doubles(x - other.x, y - other.y);

  Float64x2 operator *(Float64x2 other) =>
      NaiveFloat64x2._doubles(x * other.x, y * other.y);

  Float64x2 operator /(Float64x2 other) =>
      NaiveFloat64x2._doubles(x / other.x, y / other.y);

  Float64x2 scale(double s) => NaiveFloat64x2._doubles(x * s, y * s);

  Float64x2 abs() => NaiveFloat64x2._doubles(x.abs(), y.abs());

  Float64x2 clamp(Float64x2 lowerLimit, Float64x2 upperLimit) {
    double _lx = lowerLimit.x;
    double _ly = lowerLimit.y;
    double _ux = upperLimit.x;
    double _uy = upperLimit.y;
    double _x = x;
    double _y = y;
    // MAX(MIN(self, upper), lower).
    _x = _x > _ux ? _ux : _x;
    _y = _y > _uy ? _uy : _y;
    _x = _x < _lx ? _lx : _x;
    _y = _y < _ly ? _ly : _y;
    return NaiveFloat64x2._doubles(_x, _y);
  }

  int get signMask {
    var view = _uint32View;
    _list[0] = x;
    _list[1] = y;
    var mx = (view[1] & 0x80000000) >> 31;
    var my = (view[3] & 0x80000000) >> 31;
    return mx | my << 1;
  }

  Float64x2 withX(double x) => NaiveFloat64x2._doubles(x, y);

  Float64x2 withY(double y) => NaiveFloat64x2._doubles(x, y);

  Float64x2 min(Float64x2 other) => NaiveFloat64x2._doubles(
      x < other.x ? x : other.x, y < other.y ? y : other.y);

  Float64x2 max(Float64x2 other) => NaiveFloat64x2._doubles(
      x > other.x ? x : other.x, y > other.y ? y : other.y);

  Float64x2 sqrt() => NaiveFloat64x2._doubles(math.sqrt(x), math.sqrt(y));
}

final class NaiveInt32x4 extends WasmTypedDataBase implements Int32x4 {
  final int x;
  final int y;
  final int z;
  final int w;

  static final Int32List _list = Int32List(4);

  static int _truncate(x) {
    _list[0] = x;
    return _list[0];
  }

  NaiveInt32x4(int x, int y, int z, int w)
      : this.x = _truncate(x),
        this.y = _truncate(y),
        this.z = _truncate(z),
        this.w = _truncate(w);

  NaiveInt32x4.bool(bool x, bool y, bool z, bool w)
      : this.x = x ? -1 : 0,
        this.y = y ? -1 : 0,
        this.z = z ? -1 : 0,
        this.w = w ? -1 : 0;

  factory NaiveInt32x4.fromFloat32x4Bits(Float32x4 f) {
    Float32List floatList = NaiveFloat32x4._list;
    floatList[0] = f.x;
    floatList[1] = f.y;
    floatList[2] = f.z;
    floatList[3] = f.w;
    var view = floatList.buffer.asInt32List();
    return NaiveInt32x4._truncated(view[0], view[1], view[2], view[3]);
  }

  NaiveInt32x4._truncated(this.x, this.y, this.z, this.w);

  String toString() => '[${_int32ToHex(x)}, ${_int32ToHex(y)}, '
      '${_int32ToHex(z)}, ${_int32ToHex(w)}]';

  Int32x4 operator |(Int32x4 other) {
    int _x = x | other.x;
    int _y = y | other.y;
    int _z = z | other.z;
    int _w = w | other.w;
    return NaiveInt32x4._truncated(_x, _y, _z, _w);
  }

  Int32x4 operator &(Int32x4 other) {
    int _x = x & other.x;
    int _y = y & other.y;
    int _z = z & other.z;
    int _w = w & other.w;
    return NaiveInt32x4._truncated(_x, _y, _z, _w);
  }

  Int32x4 operator ^(Int32x4 other) {
    int _x = x ^ other.x;
    int _y = y ^ other.y;
    int _z = z ^ other.z;
    int _w = w ^ other.w;
    return NaiveInt32x4._truncated(_x, _y, _z, _w);
  }

  Int32x4 operator +(Int32x4 other) {
    int _x = x + other.x;
    int _y = y + other.y;
    int _z = z + other.z;
    int _w = w + other.w;
    return NaiveInt32x4._truncated(_x, _y, _z, _w);
  }

  Int32x4 operator -(Int32x4 other) {
    int _x = x - other.x;
    int _y = y - other.y;
    int _z = z - other.z;
    int _w = w - other.w;
    return NaiveInt32x4._truncated(_x, _y, _z, _w);
  }

  Int32x4 operator -() {
    return NaiveInt32x4._truncated(-x, -y, -z, -w);
  }

  int get signMask {
    int mx = (x & 0x80000000) >> 31;
    int my = (y & 0x80000000) >> 31;
    int mz = (z & 0x80000000) >> 31;
    int mw = (w & 0x80000000) >> 31;
    return mx | my << 1 | mz << 2 | mw << 3;
  }

  Int32x4 shuffle(int mask) {
    // mask < 0 || mask > 255
    if (mask.gtU(255)) {
      throw RangeError.range(mask, 0, 255, 'mask');
    }
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    int _x = _list[mask & 0x3];
    int _y = _list[(mask >> 2) & 0x3];
    int _z = _list[(mask >> 4) & 0x3];
    int _w = _list[(mask >> 6) & 0x3];
    return NaiveInt32x4._truncated(_x, _y, _z, _w);
  }

  Int32x4 shuffleMix(Int32x4 other, int mask) {
    // mask < 0 || mask > 255
    if (mask.gtU(255)) {
      throw RangeError.range(mask, 0, 255, 'mask');
    }
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    int _x = _list[mask & 0x3];
    int _y = _list[(mask >> 2) & 0x3];

    _list[0] = other.x;
    _list[1] = other.y;
    _list[2] = other.z;
    _list[3] = other.w;
    int _z = _list[(mask >> 4) & 0x3];
    int _w = _list[(mask >> 6) & 0x3];
    return NaiveInt32x4._truncated(_x, _y, _z, _w);
  }

  Int32x4 withX(int x) {
    int _x = _truncate(x);
    return NaiveInt32x4._truncated(_x, y, z, w);
  }

  Int32x4 withY(int y) {
    int _y = _truncate(y);
    return NaiveInt32x4._truncated(x, _y, z, w);
  }

  Int32x4 withZ(int z) {
    int _z = _truncate(z);
    return NaiveInt32x4._truncated(x, y, _z, w);
  }

  Int32x4 withW(int w) {
    int _w = _truncate(w);
    return NaiveInt32x4._truncated(x, y, z, _w);
  }

  bool get flagX => x != 0;

  bool get flagY => y != 0;

  bool get flagZ => z != 0;

  bool get flagW => w != 0;

  Int32x4 withFlagX(bool flagX) {
    int _x = flagX ? -1 : 0;
    return NaiveInt32x4._truncated(_x, y, z, w);
  }

  Int32x4 withFlagY(bool flagY) {
    int _y = flagY ? -1 : 0;
    return NaiveInt32x4._truncated(x, _y, z, w);
  }

  Int32x4 withFlagZ(bool flagZ) {
    int _z = flagZ ? -1 : 0;
    return NaiveInt32x4._truncated(x, y, _z, w);
  }

  Int32x4 withFlagW(bool flagW) {
    int _w = flagW ? -1 : 0;
    return NaiveInt32x4._truncated(x, y, z, _w);
  }

  Float32x4 select(Float32x4 trueValue, Float32x4 falseValue) {
    var floatList = NaiveFloat32x4._list;
    var intView = NaiveFloat32x4._uint32view;

    floatList[0] = trueValue.x;
    floatList[1] = trueValue.y;
    floatList[2] = trueValue.z;
    floatList[3] = trueValue.w;
    int stx = intView[0];
    int sty = intView[1];
    int stz = intView[2];
    int stw = intView[3];

    floatList[0] = falseValue.x;
    floatList[1] = falseValue.y;
    floatList[2] = falseValue.z;
    floatList[3] = falseValue.w;
    int sfx = intView[0];
    int sfy = intView[1];
    int sfz = intView[2];
    int sfw = intView[3];
    int _x = (x & stx) | (~x & sfx);
    int _y = (y & sty) | (~y & sfy);
    int _z = (z & stz) | (~z & sfz);
    int _w = (w & stw) | (~w & sfw);
    intView[0] = _x;
    intView[1] = _y;
    intView[2] = _z;
    intView[3] = _w;
    return NaiveFloat32x4._truncated(
        floatList[0], floatList[1], floatList[2], floatList[3]);
  }
}

String _int32ToHex(int i) => i.toRadixString(16).padLeft(8, '0');
