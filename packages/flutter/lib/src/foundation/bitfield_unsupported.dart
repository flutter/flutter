// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Unsupported.
const int kMaxUnsignedSMI = 0;

/// Unsupported.
class BitField<T extends dynamic> {
  /// Unsupported.
  // Ignored so that both bitfield implementations have the same API.
  // ignore: avoid_unused_constructor_parameters
  BitField(int length);

  /// Unsupported.
  // Ignored so that both bitfield implementations have the same API.
  // ignore: avoid_unused_constructor_parameters
  BitField.filled(int length, bool value);

  /// Unsupported.
  bool operator [](T index) {
    throw UnsupportedError('Not supported when compiling to JavaScript');
  }

  /// Unsupported.
  void operator []=(T index, bool value) {
    throw UnsupportedError('Not supported when compiling to JavaScript');
  }

  /// Unsupported.
  void reset([ bool value = false ]) {
    throw UnsupportedError('Not supported when compiling to JavaScript');
  }
}
