// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

/// Underflow errors happen when the socket feeding a buffer is finished while
/// there are still blocked readers. Each reader will complete with this error.
class UnderflowError extends Error {
  /// The [message] describes the underflow.
  UnderflowError([this.message]);

  final String? message;

  @override
  String toString() {
    if (message != null) {
      return 'StreamBuffer Underflow: $message';
    }
    return 'StreamBuffer Underflow';
  }
}

/// Allow orderly reading of elements from a datastream, such as Socket, which
/// might not receive `List<int>` bytes regular chunks.
///
/// Example usage:
///
///     StreamBuffer<int> buffer = StreamBuffer();
///     Socket.connect('127.0.0.1', 5555).then((sock) => sock.pipe(buffer));
///     buffer.read(100).then((bytes) {
///       // do something with 100 bytes;
///     });
///
/// Throws [UnderflowError] if [throwOnError] is true. Useful for unexpected
/// [Socket] disconnects.
class StreamBuffer<T> implements StreamConsumer<List<T>> {
  /// Create a stream buffer with optional, soft [limit] to the amount of data
  /// the buffer will hold before pausing the underlying stream. A limit of 0
  /// means no buffer limits.
  StreamBuffer({bool throwOnError = false, int limit = 0})
      : _throwOnError = throwOnError,
        _limit = limit;

  int _offset = 0;
  int _counter = 0; // sum(_chunks[*].length) - _offset
  final List<T> _chunks = [];
  final List<_ReaderInWaiting<List<T>>> _readers = [];
  StreamSubscription<List<T>>? _sub;

  final bool _throwOnError;

  Stream<List<T>>? _currentStream;

  int _limit = 0;

  set limit(int limit) {
    _limit = limit;
    if (_sub != null) {
      if (!limited || _counter < limit) {
        _sub!.resume();
      } else {
        _sub!.pause();
      }
    }
  }

  int get limit => _limit;

  bool get limited => _limit > 0;

  /// The amount of unread data buffered.
  int get buffered => _counter;

  List<T> _consume(int size) {
    var follower = 0;
    var ret = List<T?>.filled(size, null);
    var leftToRead = size;
    while (leftToRead > 0) {
      var chunk = _chunks.first;
      var listCap = (chunk is List) ? chunk.length - _offset : 1;
      var subsize = leftToRead > listCap ? listCap : leftToRead;
      if (chunk is List) {
        ret.setRange(follower, follower + subsize,
            chunk.getRange(_offset, _offset + subsize).cast<T>());
      } else {
        ret[follower] = chunk;
      }
      follower += subsize;
      _offset += subsize;
      _counter -= subsize;
      leftToRead -= subsize;
      if (!(chunk is List && _offset < chunk.length)) {
        _offset = 0;
        _chunks.removeAt(0);
      }
    }
    if (limited && _sub!.isPaused && _counter < limit) {
      _sub!.resume();
    }
    return ret.cast<T>();
  }

  /// Read fully [size] bytes from the stream and return in the future.
  ///
  /// Throws [ArgumentError] if size is larger than optional buffer [limit].
  Future<List<T>> read(int size) {
    if (limited && size > limit) {
      throw ArgumentError('Cannot read $size with limit $limit');
    }

    // If we have enough data to consume and there are no other readers, then
    // we can return immediately.
    if (size <= buffered && _readers.isEmpty) {
      return Future<List<T>>.value(_consume(size));
    }
    final completer = Completer<List<T>>();
    _readers.add(_ReaderInWaiting<List<T>>(size, completer));
    return completer.future;
  }

  @override
  Future addStream(Stream<List<T>> stream) {
    var lastStream = _currentStream ?? stream;
    _sub?.cancel();
    _currentStream = stream;

    final streamDone = Completer<Null>();
    _sub = stream.listen((items) {
      _chunks.addAll(items);
      _counter += items.length;
      if (limited && _counter >= limit) {
        _sub!.pause();
      }

      while (_readers.isNotEmpty && _readers.first.size <= _counter) {
        var waiting = _readers.removeAt(0);
        waiting.completer.complete(_consume(waiting.size));
      }
    }, onDone: () {
      // User is piping in a new stream
      if (stream == lastStream && _throwOnError) {
        _closed(UnderflowError());
      }
      streamDone.complete();
    }, onError: (e, stack) {
      _closed(e, stack);
    });
    return streamDone.future;
  }

  void _closed(e, [StackTrace? stack]) {
    for (final reader in _readers) {
      if (!reader.completer.isCompleted) {
        reader.completer.completeError(e, stack);
      }
    }
    _readers.clear();
  }

  @override
  Future close() {
    final Future? ret = _sub?.cancel();
    _sub = null;
    return ret ?? Future.value(null);
  }
}

class _ReaderInWaiting<T> {
  _ReaderInWaiting(this.size, this.completer);

  int size;
  Completer<T> completer;
}
