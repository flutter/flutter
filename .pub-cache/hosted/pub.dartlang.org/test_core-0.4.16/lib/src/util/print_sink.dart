// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PrintSink implements StringSink {
  final _buffer = StringBuffer();

  @override
  void write(Object? obj) {
    _buffer.write(obj);
    _flush();
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    _buffer.writeAll(objects, separator);
    _flush();
  }

  @override
  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
    _flush();
  }

  @override
  void writeln([Object? obj = '']) {
    _buffer.writeln(obj ?? '');
    _flush();
  }

  /// [print] if the content available ends with a newline.
  void _flush() {
    if ('$_buffer'.endsWith('\n')) {
      print(_buffer);
      _buffer.clear();
    }
  }
}
