// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

class _IdentityConverter<T> extends Converter<T, T> {
  _IdentityConverter();
  @override
  T convert(T input) => input;
}

/// A [Codec] that performs the identity conversion (changing nothing) in both
/// directions.
///
/// The identity codec passes input directly to output in both directions.
/// This class can be used as a base when combining multiple codecs,
/// because fusing the identity codec with any other codec gives the other
/// codec back.
///
/// Note, that when fused with another [Codec] the identity codec disppears.
class IdentityCodec<T> extends Codec<T, T> {
  const IdentityCodec();

  @override
  Converter<T, T> get decoder => _IdentityConverter<T>();
  @override
  Converter<T, T> get encoder => _IdentityConverter<T>();

  /// Fuse with an other codec.
  ///
  /// Fusing with the identify converter is a no-op, so this always return
  /// [other].
  @override
  Codec<T, R> fuse<R>(Codec<T, R> other) => other;
}
