// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of ui;

class _StoredMessage {
  _StoredMessage(this._data, this._callback);
  final ByteData? _data;
  ByteData? get data => _data;
  final PlatformMessageResponseCallback _callback;
  PlatformMessageResponseCallback get callback => _callback;
}

class _RingBuffer<T> {
  final collection.ListQueue<T> _queue;

  _RingBuffer(this._capacity) : _queue = collection.ListQueue<T>(_capacity);
  int get length => _queue.length;
  int _capacity;
  int get capacity => _capacity;
  bool get isEmpty => _queue.isEmpty;
  Function(T)? _dropItemCallback;
  set dropItemCallback(Function(T) callback) {
    _dropItemCallback = callback;
  }

  bool push(T val) {
    if (_capacity <= 0) {
      return true;
    } else {
      final int overflowCount = _dropOverflowItems(_capacity - 1);
      _queue.addLast(val);
      return overflowCount > 0;
    }
  }

  T? pop() {
    return _queue.isEmpty ? null : _queue.removeFirst();
  }

  int _dropOverflowItems(int lengthLimit) {
    int result = 0;
    while (_queue.length > lengthLimit) {
      final T item = _queue.removeFirst();
      _dropItemCallback?.call(item);
      result += 1;
    }
    return result;
  }

  int resize(int newSize) {
    _capacity = newSize;
    return _dropOverflowItems(newSize);
  }
}

typedef DrainChannelCallback = Future<void> Function(ByteData?, PlatformMessageResponseCallback);

class ChannelBuffers {
  static const int kDefaultBufferSize = 1;

  static const String kControlChannelName = 'dev.flutter/channel-buffers';
  final Map<String, _RingBuffer<_StoredMessage>?> _messages =
      <String, _RingBuffer<_StoredMessage>?>{};

  _RingBuffer<_StoredMessage> _makeRingBuffer(int size) {
    final _RingBuffer<_StoredMessage> result = _RingBuffer<_StoredMessage>(size);
    result.dropItemCallback = _onDropItem;
    return result;
  }

  void _onDropItem(_StoredMessage message) {
    message.callback(null);
  }

  bool push(String channel, ByteData? data, PlatformMessageResponseCallback callback) {
    _RingBuffer<_StoredMessage>? queue = _messages[channel];
    if (queue == null) {
      queue = _makeRingBuffer(kDefaultBufferSize);
      _messages[channel] = queue;
    }
    final bool didOverflow = queue.push(_StoredMessage(data, callback));
    if (didOverflow) {
      // TODO(aaclarke): Update this message to include instructions on how to resize
      // the buffer once that is available to users and print in all engine builds
      // after we verify that dropping messages isn't part of normal execution.
      _debugPrintWarning('Overflow on channel: $channel.  '
                  'Messages on this channel are being discarded in FIFO fashion.  '
                  'The engine may not be running or you need to adjust '
                  'the buffer size if of the channel.');
    }
    return didOverflow;
  }

  _StoredMessage? _pop(String channel) {
    final _RingBuffer<_StoredMessage>? queue = _messages[channel];
    final _StoredMessage? result = queue?.pop();
    return result;
  }

  bool _isEmpty(String channel) {
    final _RingBuffer<_StoredMessage>? queue = _messages[channel];
    return (queue == null) ? true : queue.isEmpty;
  }

  void _resize(String channel, int newSize) {
    _RingBuffer<_StoredMessage>? queue = _messages[channel];
    if (queue == null) {
      queue = _makeRingBuffer(newSize);
      _messages[channel] = queue;
    } else {
      final int numberOfDroppedMessages = queue.resize(newSize);
      if (numberOfDroppedMessages > 0) {
        _debugPrintWarning('Dropping messages on channel "$channel" as a result of shrinking the buffer size.');
      }
    }
  }

  Future<void> drain(String channel, DrainChannelCallback callback) async {
    while (!_isEmpty(channel)) {
      final _StoredMessage message = _pop(channel)!;
      await callback(message.data, message.callback);
    }
  }

  String _getString(ByteData data) {
    final ByteBuffer buffer = data.buffer;
    final Uint8List list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return utf8.decode(list);
  }

  void handleMessage(ByteData data) {
    final List<String> command = _getString(data).split('\r');
    if (command.length == /*arity=*/2 + 1 && command[0] == 'resize') {
      _resize(command[1], int.parse(command[2]));
    } else {
      throw Exception('Unrecognized command $command sent to $kControlChannelName.');
    }
  }
}

final ChannelBuffers channelBuffers = ChannelBuffers();
