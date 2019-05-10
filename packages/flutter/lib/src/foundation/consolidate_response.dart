// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Signature for getting notified when chunks of bytes are received while
/// consolidating the bytes of an [HttpClientResponse] into a [Uint8List].
///
/// The `cumulative` parameter will contain the total number of bytes received
/// thus far.
///
/// The `total` parameter will contain the _expected_ total number of bytes to
/// be received (extracted from the value of the `Content-Length` HTTP response
/// header), or -1 if the size of the response body is not known in advance.
/// Even if the parameter reports a non-negative value, it is not 100%
/// trustworthy (e.g. when GZIP is involved or other cases where an
/// intermediate transformer has been applied to the stream).
///
/// This is used in [consolidateHttpClientResponseBytes].
typedef BytesReceivedCallback = void Function(int cumulative, int total);

/// Efficiently converts the response body of an [HttpClientResponse] into a
/// [Uint8List].
///
/// The future returned will forward all errors emitted by [response].
///
/// The [onBytesReceived] callback, if specified, will be invoked for every
/// chunk of bytes that are received while consolidating the response bytes.
/// For more information on how to interpret the parameters to the callback,
/// see the documentation on [BytesReceivedCallback].
Future<Uint8List> consolidateHttpClientResponseBytes(
  HttpClientResponse response, {
  BytesReceivedCallback onBytesReceived,
}) {
  // response.contentLength is not trustworthy when GZIP is involved
  // or other cases where an intermediate transformer has been applied
  // to the stream, so we manually count the bytes as they cross the wire.
  final Completer<Uint8List> completer = Completer<Uint8List>.sync();
  final List<List<int>> chunks = <List<int>>[];
  final int expectedContentLength = response.contentLength;
  int contentLength = 0;
  response.listen((List<int> chunk) {
    chunks.add(chunk);
    contentLength += chunk.length;
    if (onBytesReceived != null) {
      onBytesReceived(contentLength, expectedContentLength);
    }
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
