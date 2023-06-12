import 'dart:io';

import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Not part of public API
class BufferedFileReader {
  /// Not part of public API
  @visibleForTesting
  static const defaultChunkSize = 1000 * 64;

  /// Not part of public API
  ///
  /// Nullable because of testing. [loadBytes] can throw if the count is not in
  /// the buffer.
  @visibleForTesting
  final RandomAccessFile? file;

  /// Not part of public API
  @visibleForTesting
  Uint8List buffer;

  int _bufferSize = 0;
  int _bufferOffset = 0;
  int _fileOffset = 0;

  /// Not part of public API
  int get remainingInBuffer => _bufferSize - _bufferOffset;

  /// Not part of public API
  int get offset => _fileOffset - remainingInBuffer;

  /// Not part of public API
  BufferedFileReader(this.file, [int bufferSize = defaultChunkSize])
      : buffer = Uint8List(bufferSize);

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void skip(int bytes) {
    assert(bytes >= 0 && remainingInBuffer >= bytes);
    _bufferOffset += bytes;
  }

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List viewBytes(int bytes) {
    assert(bytes >= 0 && remainingInBuffer >= bytes);
    var view = Uint8List.view(buffer.buffer, _bufferOffset, bytes);
    _bufferOffset += bytes;
    return view;
  }

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List peekBytes(int bytes) {
    assert(bytes >= 0 && remainingInBuffer >= bytes);
    return Uint8List.view(buffer.buffer, _bufferOffset, bytes);
  }

  /// Not part of public API
  Future<int> loadBytes(int bytes) async {
    assert(bytes > 0);
    var remaining = remainingInBuffer;
    if (remaining >= bytes) {
      return remaining;
    } else {
      var oldBuffer = buffer;
      if (buffer.length < bytes) {
        buffer = Uint8List(bytes);
      }

      for (var i = 0; i < remaining; i++) {
        buffer[i] = oldBuffer[_bufferOffset + i];
      }

      _bufferOffset = 0;
      var readBytes = await file!.readInto(buffer, remaining);
      _bufferSize = remaining + readBytes;
      _fileOffset += readBytes;

      return _bufferSize;
    }
  }
}
