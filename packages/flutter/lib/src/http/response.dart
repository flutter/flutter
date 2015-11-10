// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/// An HTTP response where the entire response body is known in advance.
class Response {
  const Response({ this.body, this.bodyBytes, this.statusCode });
  final String body;
  final Uint8List bodyBytes;
  final int statusCode;
}
