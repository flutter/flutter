// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';

import '../middleware.dart';

/// Middleware that adds [chunked transfer coding][] to responses if none of the
/// following conditions are true:
///
/// [chunked transfer coding]: https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.6.1
///
/// * A Content-Length header is provided.
/// * The Content-Type header indicates the MIME type `multipart/byteranges`.
/// * The Transfer-Encoding header already includes the `chunked` coding.
///
/// This is intended for use by [Shelf adapters][] rather than end-users.
///
/// [Shelf adapters]: https://github.com/dart-lang/shelf#adapters
final addChunkedEncoding = createMiddleware(responseHandler: (response) {
  if (response.contentLength != null) return response;
  if (response.statusCode < 200) return response;
  if (response.statusCode == 204) return response;
  if (response.statusCode == 304) return response;
  if (response.mimeType == 'multipart/byteranges') return response;

  // We only check the last coding here because HTTP requires that the chunked
  // encoding be listed last.
  var coding = response.headers['transfer-encoding'];
  if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
    return response;
  }

  return response.change(
      headers: {'transfer-encoding': 'chunked'},
      body: chunkedCoding.encoder.bind(response.read()));
});
