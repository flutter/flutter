// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'digest.dart';
import 'digest_sink.dart';
import 'hash.dart';

/// An implementation of [keyed-hash method authentication codes][rfc].
///
/// [rfc]: https://tools.ietf.org/html/rfc2104
///
/// HMAC allows messages to be cryptographically authenticated using any
/// iterated cryptographic hash function.
class Hmac extends Converter<List<int>, Digest> {
  /// The hash function used to compute the authentication digest.
  final Hash _hash;

  /// The secret key shared by the sender and the receiver.
  final Uint8List _key;

  /// Create an [Hmac] object from a [Hash] and a binary key.
  ///
  /// The key should be a secret shared between the sender and receiver of the
  /// message.
  Hmac(Hash hash, List<int> key)
      : _hash = hash,
        _key = Uint8List(hash.blockSize) {
    // Hash the key if it's longer than the block size of the hash.
    if (key.length > _hash.blockSize) key = _hash.convert(key).bytes;

    // If [key] is shorter than the block size, the rest of [_key] will be
    // 0-padded.
    _key.setRange(0, key.length, key);
  }

  @override
  Digest convert(List<int> input) {
    var innerSink = DigestSink();
    var outerSink = startChunkedConversion(innerSink);
    outerSink.add(input);
    outerSink.close();
    return innerSink.value;
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      _HmacSink(sink, _hash, _key);
}

/// The concrete implementation of the HMAC algorithm.
class _HmacSink extends ByteConversionSink {
  /// The sink for the outer hash computation.
  final ByteConversionSink _outerSink;

  /// The sink that [_innerSink]'s result will be added to when it's available.
  final _innerResultSink = DigestSink();

  /// The sink for the inner hash computation.
  late final ByteConversionSink _innerSink;

  /// Whether [close] has been called.
  bool _isClosed = false;

  _HmacSink(Sink<Digest> sink, Hash hash, List<int> key)
      : _outerSink = hash.startChunkedConversion(sink) {
    _innerSink = hash.startChunkedConversion(_innerResultSink);

    // Compute outer padding.
    var padding = Uint8List(key.length);
    for (var i = 0; i < padding.length; i++) {
      padding[i] = 0x5c ^ key[i];
    }
    _outerSink.add(padding);

    // Compute inner padding.
    for (var i = 0; i < padding.length; i++) {
      padding[i] = 0x36 ^ key[i];
    }
    _innerSink.add(padding);
  }

  @override
  void add(List<int> data) {
    if (_isClosed) throw StateError('HMAC is closed');
    _innerSink.add(data);
  }

  @override
  void addSlice(List<int> data, int start, int end, bool isLast) {
    if (_isClosed) throw StateError('HMAC is closed');
    _innerSink.addSlice(data, start, end, isLast);
  }

  @override
  void close() {
    if (_isClosed) return;
    _isClosed = true;

    _innerSink.close();
    _outerSink.add(_innerResultSink.value.bytes);
    _outerSink.close();
  }
}
