// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'chunked_coding/decoder.dart';
import 'chunked_coding/encoder.dart';

export 'chunked_coding/decoder.dart' hide chunkedCodingDecoder;
export 'chunked_coding/encoder.dart' hide chunkedCodingEncoder;

/// The canonical instance of [ChunkedCodingCodec].
const chunkedCoding = ChunkedCodingCodec._();

/// A codec that encodes and decodes the [chunked transfer coding][].
///
/// [chunked transfer coding]: https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.6.1
///
/// The [encoder] creates a *single* chunked message for each call to
/// [ChunkedCodingEncoder.convert] or
/// [ChunkedCodingEncoder.startChunkedConversion]. This means that it will
/// always add an end-of-message footer once conversion has finished. It doesn't
/// support generating chunk extensions or trailing headers.
///
/// Similarly, the [decoder] decodes a *single* chunked message into a stream of
/// byte arrays that must be concatenated to get the full list (like most Dart
/// byte streams). It doesn't support decoding a stream that contains multiple
/// chunked messages, nor does it support a stream that contains chunked data
/// mixed with other types of data.
///
/// Currently, [decoder] will fail to parse chunk extensions and trailing
/// headers. It may be updated to silently ignore them in the future.
class ChunkedCodingCodec extends Codec<List<int>, List<int>> {
  @override
  ChunkedCodingEncoder get encoder => chunkedCodingEncoder;

  @override
  ChunkedCodingDecoder get decoder => chunkedCodingDecoder;

  const ChunkedCodingCodec._();
}
