import 'dart:io';

/// Not part of public API
class BufferedFileWriter {
  static const _defaultMaxBufferSize = 64000;

  final RandomAccessFile _file;

  final int _maxBufferSize;

  final _buffer = BytesBuilder(copy: true);

  /// Not part of public API
  BufferedFileWriter(this._file, [this._maxBufferSize = _defaultMaxBufferSize]);

  /// Not part of public API
  Future<void> write(List<int> bytes) {
    _buffer.add(bytes);
    if (_buffer.length >= _maxBufferSize) {
      return flush();
    }
    return Future.value();
  }

  /// Not part of public API
  Future<void> flush() {
    if (_buffer.isNotEmpty) {
      return _file.writeFrom(_buffer.takeBytes());
    } else {
      return Future.value();
    }
  }
}
