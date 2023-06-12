// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sync.http;

// '\n' character
const int _lineTerminator = 10;

typedef _LineDecoderCallback = void Function(
    String line, int bytesRead, _LineDecoder decoder);

class _LineDecoder {
  final BytesBuilder _unprocessedBytes = BytesBuilder();

  int expectedByteCount = -1;

  final _LineDecoderCallback _callback;

  _LineDecoder.withCallback(this._callback);

  void add(List<int> chunk) {
    while (chunk.isNotEmpty) {
      var splitIndex = -1;

      if (expectedByteCount > 0) {
        splitIndex = expectedByteCount - _unprocessedBytes.length;
      } else {
        splitIndex = chunk.indexOf(_lineTerminator) + 1;
      }

      if (splitIndex > 0 && splitIndex <= chunk.length) {
        _unprocessedBytes.add(chunk.sublist(0, splitIndex));
        chunk = chunk.sublist(splitIndex);
        expectedByteCount = -1;
        _process(_unprocessedBytes.takeBytes());
      } else {
        _unprocessedBytes.add(chunk);
        chunk = [];
      }
    }
  }

  void _process(List<int> line) =>
      _callback(utf8.decoder.convert(line), line.length, this);

  int get bufferedBytes => _unprocessedBytes.length;

  void close() => _process(_unprocessedBytes.takeBytes());
}
