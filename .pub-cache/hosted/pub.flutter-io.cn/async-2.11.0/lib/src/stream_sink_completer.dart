// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'null_stream_sink.dart';

/// A [sink] where the destination is provided later.
///
/// The [sink] is a normal sink that you can add events to to immediately, but
/// until [setDestinationSink] is called, the events will be buffered.
///
/// The same effect can be achieved by using a [StreamController] and adding it
/// to the sink using [StreamConsumer.addStream] when the destination sink is
/// ready. This
/// class attempts to shortcut some of the overhead when possible. For example,
/// if the [sink] only has events added after the destination sink has been set,
/// those events are added directly to the sink.
class StreamSinkCompleter<T> {
  /// The sink for this completer.
  ///
  /// When a destination sink is provided, events that have been passed to the
  /// sink will be forwarded to the destination.
  ///
  /// Events can be added to the sink either before or after a destination sink
  /// is set.
  final StreamSink<T> sink = _CompleterSink<T>();

  /// Returns [sink] typed as a [_CompleterSink].
  _CompleterSink<T> get _sink => sink as _CompleterSink<T>;

  /// Convert a `Future<StreamSink>` to a `StreamSink`.
  ///
  /// This creates a sink using a sink completer, and sets the destination sink
  /// to the result of the future when the future completes.
  ///
  /// If the future completes with an error, the returned sink will instead
  /// be closed. Its [StreamSink.done] future will contain the error.
  static StreamSink<T> fromFuture<T>(Future<StreamSink<T>> sinkFuture) {
    var completer = StreamSinkCompleter<T>();
    sinkFuture.then(completer.setDestinationSink, onError: completer.setError);
    return completer.sink;
  }

  /// Sets a sink as the destination for events from the [StreamSinkCompleter]'s
  /// [sink].
  ///
  /// The completer's [sink] will act exactly as [destinationSink].
  ///
  /// If the destination sink is set before events are added to [sink], further
  /// events are forwarded directly to [destinationSink].
  ///
  /// If events are added to [sink] before setting the destination sink, they're
  /// buffered until the destination is available.
  ///
  /// A destination sink may be set at most once.
  ///
  /// Either of [setDestinationSink] or [setError] may be called at most once.
  /// Trying to call either of them again will fail.
  void setDestinationSink(StreamSink<T> destinationSink) {
    if (_sink._destinationSink != null) {
      throw StateError('Destination sink already set');
    }
    _sink._setDestinationSink(destinationSink);
  }

  /// Completes this to a closed sink whose [StreamSink.done] future emits
  /// [error].
  ///
  /// This is useful when the process of loading the sink fails.
  ///
  /// Either of [setDestinationSink] or [setError] may be called at most once.
  /// Trying to call either of them again will fail.
  void setError(Object error, [StackTrace? stackTrace]) {
    setDestinationSink(NullStreamSink.error(error, stackTrace));
  }
}

/// [StreamSink] completed by [StreamSinkCompleter].
class _CompleterSink<T> implements StreamSink<T> {
  /// Controller for an intermediate sink.
  ///
  /// Created if the user adds events to this sink before the destination sink
  /// is set.
  StreamController<T>? _controller;

  /// Completer for [done].
  ///
  /// Created if the user requests the [done] future before the destination sink
  /// is set.
  Completer? _doneCompleter;

  /// Destination sink for the events added to this sink.
  ///
  /// Set when [StreamSinkCompleter.setDestinationSink] is called.
  StreamSink<T>? _destinationSink;

  /// Whether events should be sent directly to [_destinationSink], as opposed
  /// to going through [_controller].
  bool get _canSendDirectly => _controller == null && _destinationSink != null;

  @override
  Future get done {
    if (_doneCompleter != null) return _doneCompleter!.future;
    if (_destinationSink == null) {
      _doneCompleter = Completer.sync();
      return _doneCompleter!.future;
    }
    return _destinationSink!.done;
  }

  @override
  void add(T event) {
    if (_canSendDirectly) {
      _destinationSink!.add(event);
    } else {
      _ensureController().add(event);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_canSendDirectly) {
      _destinationSink!.addError(error, stackTrace);
    } else {
      _ensureController().addError(error, stackTrace);
    }
  }

  @override
  Future addStream(Stream<T> stream) {
    if (_canSendDirectly) return _destinationSink!.addStream(stream);

    return _ensureController().addStream(stream, cancelOnError: false);
  }

  @override
  Future close() {
    if (_canSendDirectly) {
      _destinationSink!.close();
    } else {
      _ensureController().close();
    }
    return done;
  }

  /// Create [_controller] if it doesn't yet exist.
  StreamController<T> _ensureController() {
    return _controller ??= StreamController(sync: true);
  }

  /// Sets the destination sink to which events from this sink will be provided.
  ///
  /// If set before the user adds events, events will be added directly to the
  /// destination sink. If the user adds events earlier, an intermediate sink is
  /// created using a stream controller, and the destination sink is linked to
  /// it later.
  void _setDestinationSink(StreamSink<T> sink) {
    assert(_destinationSink == null);
    _destinationSink = sink;

    // If the user has already added data, it's buffered in the controller, so
    // we add it to the sink.
    if (_controller != null) {
      // Catch any error that may come from [addStream] or [sink.close]. They'll
      // be reported through [done] anyway.
      sink
          .addStream(_controller!.stream)
          .whenComplete(sink.close)
          .catchError((_) {});
    }

    // If the user has already asked when the sink is done, connect the sink's
    // done callback to that completer.
    if (_doneCompleter != null) {
      _doneCompleter!.complete(sink.done);
    }
  }
}
