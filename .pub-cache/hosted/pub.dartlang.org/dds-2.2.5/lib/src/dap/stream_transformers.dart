// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

/// Transforms a stream of bytes into strings whenever a newline is encountered.
///
/// This is used to consume output of processes like the package:test JSON
/// reporter where the stream data may be buffered and we need to process
/// specific JSON packets that are sent on their own lines.
class ByteToLineTransformer extends StreamTransformerBase<List<int>, String> {
  @override
  Stream<String> bind(Stream<List<int>> stream) {
    late StreamSubscription<int> input;
    late StreamController<String> _output;
    final buffer = <int>[];
    _output = StreamController<String>(
      onListen: () {
        input = stream.expand((b) => b).listen(
          (codeUnit) {
            buffer.add(codeUnit);
            if (_endsWithLf(buffer)) {
              _output.add(utf8.decode(buffer));
              buffer.clear();
            }
          },
          onError: _output.addError,
          onDone: _output.close,
        );
      },
      onPause: () => input.pause(),
      onResume: () => input.resume(),
      onCancel: () => input.cancel(),
    );
    return _output.stream;
  }

  /// Whether [buffer] ends in '\n'.
  static bool _endsWithLf(List<int> buffer) {
    return buffer.isNotEmpty && buffer.last == 10;
  }
}
