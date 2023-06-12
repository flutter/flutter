// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

/// Collects messages from an input stream of bytes.
///
/// Each message should start with a 32 bit big endian uint indicating its size,
/// followed by that many bytes.
class MessageGrouper {
  /// The input bytes stream subscription.
  late final StreamSubscription _inputStreamSubscription;

  /// The buffer to store the length bytes in.
  final _FixedBuffer _lengthBuffer = new _FixedBuffer(4);

  /// If reading raw data, buffer for the data.
  _FixedBuffer? _messageBuffer;

  late final StreamController<Uint8List> _messageStreamController =
      new StreamController<Uint8List>(onCancel: () {
    _inputStreamSubscription.cancel();
  });

  Stream<Uint8List> get messageStream => _messageStreamController.stream;

  MessageGrouper(Stream<List<int>> inputStream) {
    _inputStreamSubscription = inputStream.listen(_handleBytes, onDone: cancel);
  }

  /// Stop listening to the input stream for further updates, and close the
  /// output stream.
  void cancel() {
    _inputStreamSubscription.cancel();
    _messageStreamController.close();
  }

  void _handleBytes(List<int> bytes, [int offset = 0]) {
    final _FixedBuffer? messageBuffer = _messageBuffer;
    if (messageBuffer == null) {
      while (offset < bytes.length && !_lengthBuffer.isReady) {
        _lengthBuffer.addByte(bytes[offset++]);
      }
      if (_lengthBuffer.isReady) {
        int length = _lengthBuffer[0] << 24 |
            _lengthBuffer[1] << 16 |
            _lengthBuffer[2] << 8 |
            _lengthBuffer[3];
        // Reset the length reading state.
        _lengthBuffer.reset();
        // Switch to the message payload reading state.
        _messageBuffer = new _FixedBuffer(length);
        _handleBytes(bytes, offset);
      } else {
        // Continue reading the length.
        return;
      }
    } else {
      // Read the data from `bytes`.
      offset += messageBuffer.addBytes(bytes, offset);

      // If we completed a message, add it to the output stream.
      if (messageBuffer.isReady) {
        _messageStreamController.add(messageBuffer.bytes);
        // Switch to the length reading state.
        _messageBuffer = null;
        _handleBytes(bytes, offset);
      }
    }
  }
}

/// A buffer of fixed length.
class _FixedBuffer {
  final Uint8List bytes;

  /// The offset in [bytes].
  int _offset = 0;

  _FixedBuffer(int length) : bytes = new Uint8List(length);

  /// Return `true` when the required number of bytes added.
  bool get isReady => _offset == bytes.length;

  int operator [](int index) => bytes[index];

  void addByte(int byte) {
    bytes[_offset++] = byte;
  }

  /// Consume at most as many bytes from [source] as required by fill [bytes].
  /// Return the number of consumed bytes.
  int addBytes(List<int> source, int offset) {
    int toConsume = math.min(source.length - offset, bytes.length - _offset);
    bytes.setRange(_offset, _offset + toConsume, source, offset);
    _offset += toConsume;
    return toConsume;
  }

  /// Reset the number of added bytes to zero.
  void reset() {
    _offset = 0;
  }
}
