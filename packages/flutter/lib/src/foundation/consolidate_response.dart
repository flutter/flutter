// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Efficiently converts the response body of an [HttpClientResponse] into a [Uint8List].
///
/// The future returned will forward all errors emitted by [response].
Future<Uint8List> consolidateHttpClientResponseBytes(HttpClientResponse response) {
  // response.contentLength is not trustworthy when GZIP is involved
  // or other cases where an intermediate transformer has been applied
  // to the stream.
  final Completer<Uint8List> completer = Completer<Uint8List>.sync();
  final List<List<int>> chunks = <List<int>>[];
  int contentLength = 0;
  response.listen((List<int> chunk) {
    chunks.add(chunk);
    contentLength += chunk.length;
  }, onDone: () {
    final Uint8List bytes = Uint8List(contentLength);
    int offset = 0;
    for (List<int> chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    completer.complete(bytes);
  }, onError: completer.completeError, cancelOnError: true);

  return completer.future;
}
