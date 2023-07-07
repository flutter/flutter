// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Class to represent a content-type header value.
class ContentType {
  /// Creates a [ContentType] instance by parsing a "content-type" response [header].
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type
  /// See: https://httpwg.org/specs/rfc9110.html#media.type
  ContentType.parse(String header) {
    final Iterable<String> chunks =
        header.split(';').map((String e) => e.trim().toLowerCase());

    for (final String chunk in chunks) {
      if (!chunk.contains('=')) {
        _mimeType = chunk;
      } else {
        final List<String> bits =
            chunk.split('=').map((String e) => e.trim()).toList();
        assert(bits.length == 2);
        switch (bits[0]) {
          case 'charset':
            _charset = bits[1];
            break;
          case 'boundary':
            _boundary = bits[1];
            break;
          default:
            throw StateError('Unable to parse "$chunk" in content-type.');
        }
      }
    }
  }

  String? _mimeType;
  String? _charset;
  String? _boundary;

  /// The MIME-type of the resource or the data.
  String? get mimeType => _mimeType;

  /// The character encoding standard.
  String? get charset => _charset;

  /// The separation boundary for multipart entities.
  String? get boundary => _boundary;
}
