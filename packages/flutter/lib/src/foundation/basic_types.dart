// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export 'dart:ui' show VoidCallback;

/// Signature for callbacks that report that an underlying value has changed.
///
/// See also [ValueSetter].
typedef void ValueChanged<T>(T value);

/// Signature for callbacks that report that a value has been set.
///
/// This is the same signature as [ValueChanged], but is used when the
/// callback is invoked even if the underlying value has not changed.
/// For example, service extensions use this callback because they
/// invoke the callback whenever the extension is invoked with a
/// value, regardless of whether the given value is new or not.
typedef void ValueSetter<T>(T value);

/// Signature for callbacks that are to report a value on demand.
///
/// See also [ValueSetter].
typedef T ValueGetter<T>();

/// A BitField over an enum (or other class whose values implement "index").
/// Only the first 63 values of the enum can be used as indices.
class BitField<T extends dynamic> {
  static const int _kSMIBits = 63; // see https://www.dartlang.org/articles/numeric-computation/#smis-and-mints
  static const int _kAllZeros = 0;
  static const int _kAllOnes = 0x7FFFFFFFFFFFFFFF; // 2^(_kSMIBits+1)-1
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
