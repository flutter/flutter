// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MimeMultipartException implements Exception {
  final String message;

  const MimeMultipartException([this.message = '']);

  @override
  String toString() => 'MimeMultipartException: $message';
}

/// A Mime Multipart class representing each part parsed by
/// [MimeMultipartTransformer]. The data is streamed in as it become available.
abstract class MimeMultipart extends Stream<List<int>> {
  Map<String, String> get headers;
}
