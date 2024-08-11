// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/// A sink for converters to efficiently transmit String data.
///
/// Instead of limiting the interface to one non-chunked [String] it accepts
/// partial strings or can be transformed into a byte sink that
/// accepts UTF-8 code units.
///
/// The [StringConversionSink] class provides a default implementation of
/// [add], [asUtf8Sink] and [asStringSink].
abstract mixin class StringConversionSink
    implements ChunkedConversionSink<String> {
  const StringConversionSink();

  factory StringConversionSink.withCallback(void callback(String accumulated)) =
      _StringCallbackSink;
  factory StringConversionSink.from(Sink<String> sink) = _StringAdapterSink;

  /// Creates a new instance wrapping the given [sink].
  ///
  /// Every string that is added to the returned instance is forwarded to
  /// the [sink]. The instance is allowed to buffer and is not required to
  /// forward immediately.
  factory StringConversionSink.fromStringSink(StringSink sink) =
      _StringSinkConversionSink<StringSink>;

  /// Adds the next [chunk] to `this`.
  ///
  /// Adds the substring defined by [start] and [end]-exclusive to `this`.
  ///
  /// If [isLast] is `true` closes `this`.
  void addSlice(String chunk, int start, int end, bool isLast);

  void add(String str) {
    addSlice(str, 0, str.length, false);
  }

  /// Returns `this` as a sink that accepts UTF-8 input.
  ///
  /// If used, this method must be the first and only call to `this`. It
  /// invalidates `this`. All further operations must be performed on the result.
  ByteConversionSink asUtf8Sink(bool allowMalformed) {
    return _Utf8ConversionSink(this, allowMalformed);
  }

  /// Returns `this` as a [ClosableStringSink].
  ///
  /// If used, this method must be the first and only call to `this`. It
  /// invalidates `this`. All further operations must be performed on the result.
  ClosableStringSink asStringSink() {
    return _StringConversionSinkAsStringSinkAdapter(this);
  }
}

/// A [ClosableStringSink] extends the [StringSink] interface by adding a
/// `close` method.
abstract interface class ClosableStringSink implements StringSink {
  /// Creates a new instance combining a [StringSink] [sink] and a callback
  /// [onClose] which is invoked when the returned instance is closed.
  factory ClosableStringSink.fromStringSink(StringSink sink, void onClose()) =
      _ClosableStringSink;

  /// Closes `this` and flushes any outstanding data.
  void close();
}

/// This class wraps an existing [StringSink] and invokes a
/// closure when [close] is invoked.
class _ClosableStringSink implements ClosableStringSink {
  final void Function() _callback;
  final StringSink _sink;

  _ClosableStringSink(this._sink, this._callback);

  void close() {
    _callback();
  }

  void writeCharCode(int charCode) {
    _sink.writeCharCode(charCode);
  }

  void write(Object? o) {
    _sink.write(o);
  }

  void writeln([Object? o = ""]) {
    _sink.writeln(o);
  }

  void writeAll(Iterable objects, [String separator = ""]) {
    _sink.writeAll(objects, separator);
  }
}

/// This class wraps an existing [StringConversionSink] and exposes a
/// [ClosableStringSink] interface. The wrapped sink only needs to implement
/// `add` and `close`.
// TODO(floitsch): make this class public?
class _StringConversionSinkAsStringSinkAdapter implements ClosableStringSink {
  static const _MIN_STRING_SIZE = 16;

  final StringBuffer _buffer;
  final StringConversionSink _chunkedSink;

  _StringConversionSinkAsStringSinkAdapter(this._chunkedSink)
      : _buffer = StringBuffer();

  void close() {
    if (_buffer.isNotEmpty) _flush();
    _chunkedSink.close();
  }

  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
    if (_buffer.length > _MIN_STRING_SIZE) _flush();
  }

  void write(Object? o) {
    if (_buffer.isNotEmpty) _flush();
    _chunkedSink.add(o.toString());
  }

  void writeln([Object? o = ""]) {
    _buffer.writeln(o);
    if (_buffer.length > _MIN_STRING_SIZE) _flush();
  }

  void writeAll(Iterable objects, [String separator = ""]) {
    if (_buffer.isNotEmpty) _flush();
    var iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        _chunkedSink.add(iterator.current.toString());
      } while (iterator.moveNext());
    } else {
      _chunkedSink.add(iterator.current.toString());
      while (iterator.moveNext()) {
        write(separator);
        _chunkedSink.add(iterator.current.toString());
      }
    }
  }

  void _flush() {
    var accumulated = _buffer.toString();
    _buffer.clear();
    _chunkedSink.add(accumulated);
  }
}

/// This class provides a base-class for converters that need to accept String
/// inputs.
typedef StringConversionSinkBase = StringConversionSink;

/// This class provides a mixin for converters that need to accept String
/// inputs.
typedef StringConversionSinkMixin = StringConversionSink;

/// This class is a [StringConversionSink] that wraps a [StringSink].
class _StringSinkConversionSink<TStringSink extends StringSink>
    extends StringConversionSink {
  final TStringSink _stringSink;
  _StringSinkConversionSink(this._stringSink);

  void close() {}

  void addSlice(String str, int start, int end, bool isLast) {
    if (start != 0 || end != str.length) {
      for (var i = start; i < end; i++) {
        _stringSink.writeCharCode(str.codeUnitAt(i));
      }
    } else {
      _stringSink.write(str);
    }
    if (isLast) close();
  }

  void add(String str) {
    _stringSink.write(str);
  }

  ByteConversionSink asUtf8Sink(bool allowMalformed) {
    return _Utf8StringSinkAdapter(this, _stringSink, allowMalformed);
  }

  ClosableStringSink asStringSink() {
    return ClosableStringSink.fromStringSink(_stringSink, close);
  }
}

/// This class accumulates all chunks into one string
/// and invokes a callback when the sink is closed.
///
/// This class can be used to terminate a chunked conversion.
class _StringCallbackSink extends _StringSinkConversionSink<StringBuffer> {
  final void Function(String) _callback;

  _StringCallbackSink(this._callback) : super(StringBuffer());

  void close() {
    var accumulated = _stringSink.toString();
    _stringSink.clear();
    _callback(accumulated);
  }

  ByteConversionSink asUtf8Sink(bool allowMalformed) {
    return _Utf8StringSinkAdapter(this, _stringSink, allowMalformed);
  }
}

/// This class adapts a simple [ChunkedConversionSink] to a
/// [StringConversionSink].
///
/// All additional methods of the [StringConversionSink] (compared to the
/// ChunkedConversionSink) are redirected to the `add` method.
class _StringAdapterSink extends StringConversionSink {
  final Sink<String> _sink;

  _StringAdapterSink(this._sink);

  void add(String str) {
    _sink.add(str);
  }

  void addSlice(String str, int start, int end, bool isLast) {
    if (start == 0 && end == str.length) {
      add(str);
    } else {
      add(str.substring(start, end));
    }
    if (isLast) close();
  }

  void close() {
    _sink.close();
  }
}

/// Decodes UTF-8 code units and stores them in a [StringSink].
///
/// The `Sink` provided is closed when this sink is closed.
class _Utf8StringSinkAdapter extends ByteConversionSink {
  final _Utf8Decoder _decoder;
  final Sink<Object?> _sink;
  final StringSink _stringSink;

  _Utf8StringSinkAdapter(this._sink, this._stringSink, bool allowMalformed)
      : _decoder = _Utf8Decoder(allowMalformed);

  void close() {
    _decoder.flush(_stringSink);
    _sink.close();
  }

  void add(List<int> chunk) {
    addSlice(chunk, 0, chunk.length, false);
  }

  void addSlice(
      List<int> codeUnits, int startIndex, int endIndex, bool isLast) {
    _stringSink.write(_decoder.convertChunked(codeUnits, startIndex, endIndex));
    if (isLast) close();
  }
}

/// Decodes UTF-8 code units.
///
/// Forwards the decoded strings to the given [StringConversionSink].
// TODO(floitsch): make this class public?
class _Utf8ConversionSink extends ByteConversionSink {
  final _Utf8Decoder _decoder;
  final StringConversionSink _chunkedSink;
  final StringBuffer _buffer;
  _Utf8ConversionSink(StringConversionSink sink, bool allowMalformed)
      : this._(sink, StringBuffer(), allowMalformed);

  _Utf8ConversionSink._(
      this._chunkedSink, StringBuffer stringBuffer, bool allowMalformed)
      : _decoder = _Utf8Decoder(allowMalformed),
        _buffer = stringBuffer;

  void close() {
    _decoder.flush(_buffer);
    if (_buffer.isNotEmpty) {
      var accumulated = _buffer.toString();
      _buffer.clear();
      _chunkedSink.addSlice(accumulated, 0, accumulated.length, true);
    } else {
      _chunkedSink.close();
    }
  }

  void add(List<int> chunk) {
    addSlice(chunk, 0, chunk.length, false);
  }

  void addSlice(List<int> chunk, int startIndex, int endIndex, bool isLast) {
    _buffer.write(_decoder.convertChunked(chunk, startIndex, endIndex));
    if (_buffer.isNotEmpty) {
      var accumulated = _buffer.toString();
      _chunkedSink.addSlice(accumulated, 0, accumulated.length, isLast);
      _buffer.clear();
      return;
    }
    if (isLast) close();
  }
}
