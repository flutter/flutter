// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The largest SMI value.
///
/// See <https://www.dartlang.org/articles/numeric-computation/#smis-and-mints>
///
/// When compiling to JavaScript, this value is not supported since it is
/// larger than the maximum safe 32bit integer.
const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;

/// A BitField over an enum (or other class whose values implement "index").
/// Only the first 62 values of the enum can be used as indices.
///
/// When compiling to JavaScript, this class is not supported.
class BitField<T extends dynamic> {
  /// Creates a bit field of all zeros.
  ///
  /// The given length must be at most 62.
  BitField(this._length)
    : assert(_length <= _smiBits),
      _bits = _allZeros;

  /// Creates a bit field filled with a particular value.
  ///
  /// If the value argument is true, the bits are filled with ones. Otherwise,
  /// the bits are filled with zeros.
  ///
  /// The given length must be at most 62.
  BitField.filled(this._length, bool value)
    : assert(_length <= _smiBits),
      _bits = value ? _allOnes : _allZeros;

  final int _length;
  int _bits;

  static const int _smiBits = 62; // see https://www.dartlang.org/articles/numeric-computation/#smis-and-mints
  static const int _allZeros = 0;
  static const int _allOnes = kMaxUnsignedSMI; // 2^(_kSMIBits+1)-1

  /// Returns whether the bit with the given index is set to one.
  bool operator [](T index) {
    assert(index.index < _length);
    return (_bits & 1 << index.index) > 0;
  }

  /// Sets the bit with the given index to the given value.
  ///
  /// If value is true, the bit with the given index is set to one. Otherwise,
  /// the bit is set to zero.
  void operator []=(T index, bool value) {
    assert(index.index < _length);
    if (value)
      _bits = _bits | (1 << index.index);
    else
      _bits = _bits & ~(1 << index.index);
  }

  /// Sets all the bits to the given value.
  ///
  /// If the value is true, the bits are all set to one. Otherwise, the bits are
  /// all set to zero. Defaults to setting all the bits to zero.
  void reset([ bool value = false ]) {
    _bits = value ? _allOnes : _allZeros;
  }
}
