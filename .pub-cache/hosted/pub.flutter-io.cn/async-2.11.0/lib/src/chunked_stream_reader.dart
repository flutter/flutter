// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'byte_collector.dart' show collectBytes;

/// Utility class for reading elements from a _chunked stream_.
///
/// A _chunked stream_ is a stream where each event is a chunk of elements.
/// Byte-streams with the type `Stream<List<int>>` is common of example of this.
/// As illustrated in the example below, this utility class makes it easy to
/// read a _chunked stream_ using custom chunk sizes and sub-stream sizes,
/// without managing partially read chunks.
///
/// ```dart
/// final r = ChunkedStreamReader(File('myfile.txt').openRead());
/// try {
///   // Read the first 4 bytes
///   final firstBytes = await r.readChunk(4);
///   if (firstBytes.length < 4) {
///     throw Exception('myfile.txt has less than 4 bytes');
///   }
///
///   // Read next 8 kilobytes as a substream
///   Stream<List<int>> substream = r.readStream(8 * 1024);
///
///   ...
/// } finally {
///   // We always cancel the ChunkedStreamReader, this ensures the underlying
///   // stream is cancelled.
///   r.cancel();
/// }
/// ```
///
/// The read-operations [readChunk] and [readStream] must not be invoked until
/// the future from a previous call has completed.
class ChunkedStreamReader<T> {
  /// Iterator over underlying stream.
  ///
  /// The reader requests data from this input whenever requests on the
  /// reader cannot be fulfilled with the already fetched data.
  final StreamIterator<List<T>> _input;

  /// Sentinel value used for [_buffer] when we have no value.
  final List<T> _emptyList = const [];

  /// Last partially consumed chunk received from [_input].
  ///
  /// Elements up to [_offset] have already been consumed and should not be
  /// consumed again.
  List<T> _buffer = <T>[];

  /// Offset into [_buffer] after data which have already been emitted.
  ///
  /// The offset is between `0` and `_buffer.length`, both inclusive.
  /// The data in [_buffer] from [_offset] and forward have not yet been
  /// emitted by the chunked stream reader, the data before [_offset] has.
  int _offset = 0;

  /// Whether a read request is currently being processed.
  ///
  /// Is `true` while a request is in progress.
  /// While a read request, like [readChunk] or [readStream], is being
  /// processed, no new requests can be made.
  /// New read attempts will throw instead.
  bool _reading = false;

  factory ChunkedStreamReader(Stream<List<T>> stream) =>
      ChunkedStreamReader._(StreamIterator(stream));

  ChunkedStreamReader._(this._input);

  /// Read next [size] elements from _chunked stream_, buffering to create a
  /// chunk with [size] elements.
  ///
  /// This will read _chunks_ from the underlying _chunked stream_ until [size]
  /// elements have been buffered, or end-of-stream, then it returns the first
  /// [size] buffered elements.
  ///
  /// If end-of-stream is encountered before [size] elements is read, this
  /// returns a list with fewer than [size] elements (indicating end-of-stream).
  ///
  /// If the underlying stream throws, the stream is cancelled, the exception is
  /// propogated and further read operations will fail.
  ///
  /// Throws, if another read operation is on-going.
  Future<List<T>> readChunk(int size) async {
    final result = <T>[];
    await for (final chunk in readStream(size)) {
      result.addAll(chunk);
    }
    return result;
  }

  /// Read next [size] elements from _chunked stream_ as a sub-stream.
  ///
  /// This will pass-through _chunks_ from the underlying _chunked stream_ until
  /// [size] elements have been returned, or end-of-stream has been encountered.
  ///
  /// If end-of-stream is encountered before [size] elements is read, this
  /// returns a list with fewer than [size] elements (indicating end-of-stream).
  ///
  /// If the underlying stream throws, the stream is cancelled, the exception is
  /// propogated and further read operations will fail.
  ///
  /// If the sub-stream returned from [readStream] is cancelled the remaining
  /// unread elements up-to [size] are drained, allowing subsequent
  /// read-operations to proceed after cancellation.
  ///
  /// Throws, if another read-operation is on-going.
  Stream<List<T>> readStream(int size) {
    RangeError.checkNotNegative(size, 'size');
    if (_reading) {
      throw StateError('Concurrent read operations are not allowed!');
    }
    _reading = true;

    Stream<List<T>> substream() async* {
      // While we have data to read
      while (size > 0) {
        // Read something into the buffer, if buffer has been consumed.
        assert(_offset <= _buffer.length);
        if (_offset == _buffer.length) {
          if (!(await _input.moveNext())) {
            // Don't attempt to read more data, as there is no more data.
            size = 0;
            _reading = false;
            break;
          }
          _buffer = _input.current;
          _offset = 0;
        }

        final remainingBuffer = _buffer.length - _offset;
        if (remainingBuffer > 0) {
          if (remainingBuffer >= size) {
            List<T> output;
            if (_buffer is Uint8List) {
              output = Uint8List.sublistView(
                  _buffer as Uint8List, _offset, _offset + size) as List<T>;
            } else {
              output = _buffer.sublist(_offset, _offset + size);
            }
            _offset += size;
            size = 0;
            yield output;
            _reading = false;
            break;
          }

          final output = _offset == 0 ? _buffer : _buffer.sublist(_offset);
          size -= remainingBuffer;
          _buffer = _emptyList;
          _offset = 0;
          yield output;
        }
      }
    }

    final c = StreamController<List<T>>();
    c.onListen = () => c.addStream(substream()).whenComplete(c.close);
    c.onCancel = () async {
      while (size > 0) {
        assert(_offset <= _buffer.length);
        if (_buffer.length == _offset) {
          if (!await _input.moveNext()) {
            size = 0; // no more data
            break;
          }
          _buffer = _input.current;
          _offset = 0;
        }

        final remainingBuffer = _buffer.length - _offset;
        if (remainingBuffer >= size) {
          _offset += size;
          size = 0;
          break;
        }

        size -= remainingBuffer;
        _buffer = _emptyList;
        _offset = 0;
      }
      _reading = false;
    };

    return c.stream;
  }

  /// Cancel the underlying _chunked stream_.
  ///
  /// If a future from [readChunk] or [readStream] is still pending then
  /// [cancel] behaves as if the underlying stream ended early. That is a future
  /// from [readChunk] may return a partial chunk smaller than the request size.
  ///
  /// It is always safe to call [cancel], even if the underlying stream was read
  /// to completion.
  ///
  /// It can be a good idea to call [cancel] in a `finally`-block when done
  /// using the [ChunkedStreamReader], this mitigates risk of leaking resources.
  Future<void> cancel() async => await _input.cancel();
}

/// Extensions for using [ChunkedStreamReader] with byte-streams.
extension ChunkedStreamReaderByteStreamExt on ChunkedStreamReader<int> {
  /// Read bytes into a [Uint8List].
  ///
  /// This does the same as [readChunk], except it uses [collectBytes] to create
  /// a [Uint8List], which offers better performance.
  Future<Uint8List> readBytes(int size) async =>
      await collectBytes(readStream(size));
}
