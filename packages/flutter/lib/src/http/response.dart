// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

/// An HTTP response where the entire response body is known in advance.
class Response {
  /// Creates a [Response] object with the given fields.
  ///
  /// If [bodyBytes] is non-null, it is used to populate [body].
  Response.bytes(this.bodyBytes, this.statusCode, {
    this.headers: const <String, String>{},
    this.error
  });

  /// The result of decoding [bodyBytes] using the character encoding declared
  /// in the headers.
  ///
  /// Defaults to [LATIN1] (ISO 8859-1).
  ///
  /// If [bodyBytes] is null, this will also be null.
  String get body => bodyBytes == null ? null : _encodingForHeaders(headers).decode(bodyBytes);

  /// The raw byte stream.
  final Uint8List bodyBytes;

  /// The HTTP result code.
  ///
  /// The code 500 is used when no status code could be obtained from the host.
  final int statusCode;

  /// Error information, if any. This may be populated if the [statusCode] is
  /// 4xx or 5xx. This may be a string (e.g. the status line from the server) or
  /// an [Exception], but in either case the object should have a useful
  /// [toString] implementation that returns a human-readable value.
  final dynamic error;

  /// The headers for this response.
  final Map<String, String> headers;
}

bool _isSpace(String c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f';
}

int _skipSpaces(String string, int index) {
  while (index < string.length && _isSpace(string[index]))
    index += 1;
  return index;
}

// https://html.spec.whatwg.org/#algorithm-for-extracting-a-character-encoding-from-a-meta-element
String _getCharset(String contentType) {
  int index = 0;
  while (index < contentType.length) {
    index = contentType.indexOf(new RegExp(r'charset', caseSensitive: false), index);
    if (index == -1)
      return null;
    index += 7;
    index = _skipSpaces(contentType, index);
    if (index >= contentType.length)
      return null;
    if (contentType[index] != '=')
      continue;
    index += 1;
    index = _skipSpaces(contentType, index);
    if (index >= contentType.length)
      return null;
    String delimiter = contentType[index];
    if (delimiter == '"' || delimiter == '\'') {
      index += 1;
      if (index >= contentType.length)
        return null;
      int start = index;
      int end = contentType.indexOf(delimiter, start);
      if (end == -1)
        return null;
      return contentType.substring(start, end);
    }
    int start = index;
    while (index < contentType.length) {
      String c = contentType[index];
      if (c == ' ' || c == ';')
        break;
      index += 1;
    }
    return contentType.substring(start, index);
  }
  return null;
}

Encoding _encodingForHeaders(Map<String, String> headers) {
  if (headers == null)
    return LATIN1;
  String contentType = headers['content-type'];
  if (contentType == null)
    return LATIN1;
  String charset = _getCharset(contentType);
  if (charset == null)
    return LATIN1;
  return Encoding.getByName(charset) ?? LATIN1;
}
