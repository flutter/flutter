// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Unsupported.
int get kMaxUnsignedSMI => throw UnsupportedError('Not supported in environments without 64 bit ints');

/// A BitField over an enum (or other class whose values implement "index").
/// Only the first 62 values of the enum can be used as indices.
class BitField<T extends dynamic> {
  /// Creates a bit field of all zeros.
  ///
  /// The given length must be at most 62.
  BitField(int _length)
    : assert(_length <= 62);

  /// Creates a bit field filled with a particular value.
  ///
  /// If the value argument is true, the bits are filled with ones. Otherwise,
  /// the bits are filled with zeros.
  ///
  /// The given length must be at most 62.
  BitField.filled(int length, bool _) // ignore: avoid_unused_constructor_parameters
    : assert(length <= 62);

  /// Returns whether the bit with the given index is set to one.
  bool operator [](T index) {
    throw UnsupportedError('Not supported in environments without 64 bit ints');
  }

  /// Sets the bit with the given index to the given value.
  ///
  /// If value is true, the bit with the given index is set to one. Otherwise,
  /// the bit is set to zero.
  void operator []=(T index, bool value) {
    throw UnsupportedError('Not supported in environments without 64 bit ints');
  }

  /// Sets all the bits to the given value.
  ///
  /// If the value is true, the bits are all set to one. Otherwise, the bits are
  /// all set to zero. Defaults to setting all the bits to zero.
  void reset([ bool value = false ]) {
    throw UnsupportedError('Not supported in environments without 64 bit ints');
  }
}
