// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'bitfield.dart' as bitfield;

/// The dart:html implementation of [bitfield.kMaxUnsignedSMI].
///
/// This value is used as an optimization to coerce some numbers to be within
/// the SMI range and avoid heap allocations. Because number encoding is
/// VM-specific, there's no guarantee that this optimization will be effective
/// on all JavaScript engines. The value picked here should be correct, but it
/// does not have to guarantee efficiency.
const int kMaxUnsignedSMI = -1;

/// The dart:html implementation of [bitfield.Bitfield].
class BitField<T extends dynamic> implements bitfield.BitField<T> {
  /// The dart:html implementation of [bitfield.Bitfield].
  // Can remove when we have metaclasses.
  // ignore: avoid_unused_constructor_parameters
  BitField(final int length);

  /// The dart:html implementation of [bitfield.Bitfield.filled].
  // Can remove when we have metaclasses.
  // ignore: avoid_unused_constructor_parameters
  BitField.filled(final int length, final bool value);

  @override
  bool operator [](final T index) {
    throw UnsupportedError('Not supported when compiling to JavaScript');
  }

  @override
  void operator []=(final T index, final bool value) {
    throw UnsupportedError('Not supported when compiling to JavaScript');
  }

  @override
  void reset([ final bool value = false ]) {
    throw UnsupportedError('Not supported when compiling to JavaScript');
  }
}
