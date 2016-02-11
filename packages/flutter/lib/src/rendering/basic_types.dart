// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

typedef void ValueChanged<T>(T value);

/// A BitField over an enum (or other class whose values implement "index").
/// Only the first 63 values of the enum can be used as indices.
class BitField<T extends dynamic> {
  static const _kSMIBits = 63; // see https://www.dartlang.org/articles/numeric-computation/#smis-and-mints
  static const _kAllZeros = 0;
  static const _kAllOnes = 0x7FFFFFFFFFFFFFFF; // 2^(_kSMIBits+1)-1
  BitField(this._length) : _bits = _kAllZeros {
    assert(_length <= _kSMIBits);
  }
  BitField.filled(this._length, bool value) : _bits = value ? _kAllOnes : _kAllZeros {
    assert(_length <= _kSMIBits);
  }
  final int _length;
  int _bits;
  bool operator [](T index) {
    assert(index.index < _length);
    return (_bits & 1 << index.index) > 0;
  }
  void operator []=(T index, bool value) {
    assert(index.index < _length);
    if (value)
      _bits = _bits | (1 << index.index);
    else
      _bits = _bits & ~(1 << index.index);
  }
  void reset([ bool value = false ]) {
    _bits = value ? _kAllOnes : _kAllZeros;
  }
}
