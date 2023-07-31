// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import 'async_memoizer.dart';

/// An abstract class that implements [EventSink] in terms of [onAdd],
/// [onError], and [onClose] methods.
///
/// This takes care of ensuring that events can't be added after [close] is
/// called.
@Deprecated('Will be removed in the next major release')
abstract class EventSinkBase<T> implements EventSink<T> {
  /// Whether [close] has been called and no more events may be written.
  bool get _closed => _closeMemo.hasRun;

  @override
  void add(T data) {
    _checkCanAddEvent();
    onAdd(data);
  }

  /// A method that handles data events that are passed to the sink.
  @visibleForOverriding
  void onAdd(T data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _checkCanAddEvent();
    onError(error, stackTrace);
  }

  /// A method that handles error events that are passed to the sink.
  @visibleForOverriding
  void onError(Object error, [StackTrace? stackTrace]);

  @override
  Future<void> close() => _closeMemo.runOnce(onClose);
  final _closeMemo = AsyncMemoizer<void>();

  /// A method that handles the sink being closed.
  ///
  /// This may return a future that completes once the stream sink has shut
  /// down. If cleaning up can fail, the error may be reported in the returned
  /// future.
  @visibleForOverriding
  FutureOr<void> onClose();

  /// Asserts that the sink is in a state where adding an event is valid.
  void _checkCanAddEvent() {
    if (_closed) throw StateError('Cannot add event after closing');
  }
}

/// An abstract class that implements [StreamSink] in terms of [onAdd],
/// [onError], and [onClose] methods.
///
/// This takes care of ensuring that events can't be added after [close] is
/// called or during a call to [addStream].
@Deprecated('Will be removed in the next major release')
abstract class StreamSinkBase<T> extends EventSinkBase<T>
    implements StreamSink<T> {
  /// Whether a call to [addStream] is ongoing.
  bool _addingStream = false;

  @override
  Future<void> get done => _closeMemo.future;

  @override
  Future<void> addStream(Stream<T> stream) {
    _checkCanAddEvent();

    _addingStream = true;
    var completer = Completer<void>.sync();
    stream.listen(onAdd, onError: onError, onDone: () {
      _addingStream = false;
      completer.complete();
    });
    return completer.future;
  }

  @override
  Future<void> close() {
    if (_addingStream) throw StateError('StreamSink is bound to a stream');
    return super.close();
  }

  @override
  void _checkCanAddEvent() {
    super._checkCanAddEvent();
    if (_addingStream) throw StateError('StreamSink is bound to a stream');
  }
}

/// An abstract class that implements `dart:io`'s `IOSink`'s API in terms of
/// [onAdd], [onError], [onClose], and [onFlush] methods.
///
/// Because `IOSink` is defined in `dart:io`, this can't officially implement
/// it. However, it's designed to match its API exactly so that subclasses can
/// implement `IOSink` without any additional modifications.
///
/// This takes care of ensuring that events can't be added after [close] is
/// called or during a call to [addStream].
@Deprecated('Will be removed in the next major release')
abstract class IOSinkBase extends StreamSinkBase<List<int>> {
  /// See `IOSink.encoding` from `dart:io`.
  Encoding encoding;

  IOSinkBase([this.encoding = utf8]);

  /// See `IOSink.flush` from `dart:io`.
  ///
  /// Because this base class doesn't do any buffering of its own, [flush]
  /// always completes immediately.
  ///
  /// Subclasses that do buffer events should override [flush] to complete once
  /// all events are delivered. They should also call `super.flush()` at the
  /// beginning of the method to throw a [StateError] if the sink is currently
  /// adding a stream.
  Future<void> flush() {
    if (_addingStream) throw StateError('StreamSink is bound to a stream');
    if (_closed) return Future.value();

    _addingStream = true;
    return onFlush().whenComplete(() {
      _addingStream = false;
    });
  }

  /// Flushes any buffered data to the underlying consumer, and returns a future
  /// that completes once the consumer has accepted all data.
  @visibleForOverriding
  Future<void> onFlush();

  /// See [StringSink.write].
  void write(Object? object) {
    var string = object.toString();
    if (string.isEmpty) return;
    add(encoding.encode(string));
  }

  /// See [StringSink.writeAll].
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    var first = true;
    for (var object in objects) {
      if (first) {
        first = false;
      } else {
        write(separator);
      }

      write(object);
    }
  }

  /// See [StringSink.writeln].
  void writeln([Object? object = '']) {
    write(object);
    write('\n');
  }

  /// See [StringSink.writeCharCode].
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }
}
