// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/// A [Codec] encodes and (if supported) decodes data.
///
/// Codecs can be fused. For example fusing [json] and [utf8] produces
/// an encoder that can convert Json objects directly to bytes, or can decode
/// bytes directly to json objects.
///
/// Fused codecs generally attempt to optimize the operations and can be faster
/// than executing each step of an encoding separately.
///
/// The [Codec] class provides a default implementation of
/// [encode], [decode], [fuse] and [inverted].
/// Subclasses can choose to provide more efficient implementations of these.
abstract mixin class Codec<S, T> {
  const Codec();

  /// Encodes [input].
  ///
  /// The input is encoded as if by `encoder.convert`.
  T encode(S input) => encoder.convert(input);

  /// Decodes [encoded] data.
  ///
  /// The input is decoded as if by `decoder.convert`.
  S decode(T encoded) => decoder.convert(encoded);

  /// Returns the encoder from [S] to [T].
  ///
  /// It may be stateful and should not be reused.
  Converter<S, T> get encoder;

  /// Returns the decoder of `this`, converting from [T] to [S].
  ///
  /// It may be stateful and should not be reused.
  Converter<T, S> get decoder;

  /// Fuses `this` with `other`.
  ///
  /// When encoding, the resulting codec encodes with `this` before
  /// encoding with [other].
  ///
  /// When decoding, the resulting codec decodes with [other] before decoding
  /// with `this`.
  ///
  /// In some cases one needs to use the [inverted] codecs to be able to fuse
  /// them correctly. That is, the output type of `this` ([T]) must match the
  /// input type of the second codec [other].
  ///
  /// Examples:
  /// ```dart
  /// final jsonToBytes = json.fuse(utf8);
  /// List<int> bytes = jsonToBytes.encode(["json-object"]);
  /// var decoded = jsonToBytes.decode(bytes);
  /// assert(decoded is List && decoded[0] == "json-object");
  ///
  /// var inverted = json.inverted;
  /// var jsonIdentity = json.fuse(inverted);
  /// var jsonObject = jsonIdentity.encode(["1", 2]);
  /// assert(jsonObject is List && jsonObject[0] == "1" && jsonObject[1] == 2);
  /// ```
  // TODO(floitsch): use better example with line-splitter once that one is
  // in this library.
  Codec<S, R> fuse<R>(Codec<T, R> other) {
    return _FusedCodec<S, T, R>(this, other);
  }

  /// Inverts `this`.
  ///
  /// The [encoder] and [decoder] of the resulting codec are swapped.
  Codec<T, S> get inverted => _InvertedCodec<T, S>(this);
}

/// Fuses the given codecs.
///
/// In the non-chunked conversion simply invokes the non-chunked conversions in
/// sequence.
class _FusedCodec<S, M, T> extends Codec<S, T> {
  final Codec<S, M> _first;
  final Codec<M, T> _second;

  Converter<S, T> get encoder => _first.encoder.fuse<T>(_second.encoder);
  Converter<T, S> get decoder => _second.decoder.fuse<S>(_first.decoder);

  _FusedCodec(this._first, this._second);
}

class _InvertedCodec<T, S> extends Codec<T, S> {
  final Codec<S, T> _codec;

  _InvertedCodec(Codec<S, T> codec) : _codec = codec;

  Converter<T, S> get encoder => _codec.decoder;
  Converter<S, T> get decoder => _codec.encoder;

  Codec<S, T> get inverted => _codec;
}
