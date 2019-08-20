// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'consolidate_response.dart' as consolidate_response;

/// The dart:io implementation of [consolidate_response.consolidateHttpClientResponseBytes].
Future<Uint8List> consolidateHttpClientResponseBytes(
  HttpClientResponse response, {
  bool autoUncompress = true,
  consolidate_response.BytesReceivedCallback onBytesReceived,
}) {
  assert(autoUncompress != null);
  final Completer<Uint8List> completer = Completer<Uint8List>.sync();

  final _OutputBuffer output = _OutputBuffer();
  ByteConversionSink sink = output;
  int expectedContentLength = response.contentLength;
  if (expectedContentLength == -1)
    expectedContentLength = null;
  switch (response.compressionState) {
    case HttpClientResponseCompressionState.compressed:
      if (autoUncompress) {
        // We need to un-compress the bytes as they come in.
        sink = gzip.decoder.startChunkedConversion(output);
      }
      break;
    case HttpClientResponseCompressionState.decompressed:
      // response.contentLength will not match our bytes stream, so we declare
      // that we don't know the expected content length.
      expectedContentLength = null;
      break;
    case HttpClientResponseCompressionState.notCompressed:
      // Fall-through.
      break;
  }

  int bytesReceived = 0;
  StreamSubscription<List<int>> subscription;
  subscription = response.listen((List<int> chunk) {
    sink.add(chunk);
    if (onBytesReceived != null) {
      bytesReceived += chunk.length;
      try {
        onBytesReceived(bytesReceived, expectedContentLength);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
        subscription.cancel();
        return;
      }
    }
  }, onDone: () {
    sink.close();
    completer.complete(output.bytes);
  }, onError: completer.completeError, cancelOnError: true);

  return completer.future;
}

class _OutputBuffer extends ByteConversionSinkBase {
  List<List<int>> _chunks = <List<int>>[];
  int _contentLength = 0;
  Uint8List _bytes;

  @override
  void add(List<int> chunk) {
    assert(_bytes == null);
    _chunks.add(chunk);
    _contentLength += chunk.length;
  }

  @override
  void close() {
    if (_bytes != null) {
      // We've already been closed; this is a no-op
      return;
    }
    _bytes = Uint8List(_contentLength);
    int offset = 0;
    for (List<int> chunk in _chunks) {
      _bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _chunks = null;
  }

  Uint8List get bytes {
    assert(_bytes != null);
    return _bytes;
  }
}
