// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

/// The body of a request or response.
///
/// This tracks whether the body has been read. It's separate from [Message]
/// because the message may be changed with [Message.change], but each instance
/// should share a notion of whether the body was read.
class Body {
  /// The contents of the message body.
  ///
  /// This will be `null` after [read] is called.
  Stream<List<int>>? _stream;

  /// The encoding used to encode the stream returned by [read], or `null` if no
  /// encoding was used.
  final Encoding? encoding;

  /// The length of the stream returned by [read], or `null` if that can't be
  /// determined efficiently.
  final int? contentLength;

  Body._(this._stream, this.encoding, this.contentLength);

  /// Converts [body] to a byte stream and wraps it in a [Body].
  ///
  /// [body] may be either a [Body], a [String], a [List<int>], a
  /// [Stream<List<int>>], or `null`. If it's a [String], [encoding] will be
  /// used to convert it to a [Stream<List<int>>].
  factory Body(Object? body, [Encoding? encoding]) {
    if (body is Body) return body;

    Stream<List<int>> stream;
    int? contentLength;
    if (body == null) {
      contentLength = 0;
      stream = Stream.fromIterable([]);
    } else if (body is String) {
      if (encoding == null) {
        var encoded = utf8.encode(body);
        // If the text is plain ASCII, don't modify the encoding. This means
        // that an encoding of "text/plain" will stay put.
        if (!_isPlainAscii(encoded, body.length)) encoding = utf8;
        contentLength = encoded.length;
        stream = Stream.fromIterable([encoded]);
      } else {
        var encoded = encoding.encode(body);
        contentLength = encoded.length;
        stream = Stream.fromIterable([encoded]);
      }
    } else if (body is List<int>) {
      // Avoid performance overhead from an unnecessary cast.
      contentLength = body.length;
      stream = Stream.value(body);
    } else if (body is List) {
      contentLength = body.length;
      stream = Stream.value(body.cast());
    } else if (body is Stream<List<int>>) {
      // Avoid performance overhead from an unnecessary cast.
      stream = body;
    } else if (body is Stream) {
      stream = body.cast();
    } else {
      throw ArgumentError('Response body "$body" must be a String or a '
          'Stream.');
    }

    return Body._(stream, encoding, contentLength);
  }

  /// Returns whether [bytes] is plain ASCII.
  ///
  /// [codeUnits] is the number of code units in the original string.
  static bool _isPlainAscii(List<int> bytes, int codeUnits) {
    // Most non-ASCII code units will produce multiple bytes and make the text
    // longer.
    if (bytes.length != codeUnits) return false;

    // Non-ASCII code units between U+0080 and U+009F produce 8-bit characters
    // with the high bit set.
    return bytes.every((byte) => byte & 0x80 == 0);
  }

  /// Returns a [Stream] representing the body.
  ///
  /// Can only be called once.
  Stream<List<int>> read() {
    if (_stream == null) {
      throw StateError("The 'read' method can only be called once on a "
          'shelf.Request/shelf.Response object.');
    }
    var stream = _stream!;
    _stream = null;
    return stream;
  }
}
