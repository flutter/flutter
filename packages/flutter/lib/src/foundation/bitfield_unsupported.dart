// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Unsupported
const int kMaxUnsignedSMI = -1;

/// Unsupported
class BitField<T extends dynamic> {
  /// Unsupported
  // Ignored to keep API the same as the supported bitfield implementation.
  // ignore: avoid_unused_constructor_parameters
  BitField(int _);

  /// Unsupported
  // Ignored to keep API the same as the supported bitfield implementation.
  // ignore: avoid_unused_constructor_parameters
  BitField.filled(int _, bool __);

  /// Unsupported
  bool operator [](T index) {
    throw UnsupportedError('BitField not supported on the web.');
  }

  /// Unsupported
  void operator []=(T index, bool value) {
    throw UnsupportedError('BitField not supported on the web.');
  }

  /// Unsupported
  void reset([ bool value = false ]) {
    throw UnsupportedError('BitField not supported on the web.');
  }
}
