// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/// An HTTP response where the entire response body is known in advance.
class Response {
  /// Creates a [Response] object with the given fields.
  ///
  /// If [bodyBytes] is non-null, it is used to populate [body].
  Response({
    Uint8List bodyBytes,
    this.statusCode
  }) : body = bodyBytes != null ? new String.fromCharCodes(bodyBytes) : null,
       bodyBytes = bodyBytes;

  /// The result of decoding [bodyBytes] using ISO-8859-1.
  ///
  /// If [bodyBytes] is null, this will also be null.
  final String body;

  /// The raw byte stream.
  final Uint8List bodyBytes;

  /// The HTTP result code.
  ///
  /// The code 500 is used when no status code could be obtained from the host.
  final int statusCode;
}
