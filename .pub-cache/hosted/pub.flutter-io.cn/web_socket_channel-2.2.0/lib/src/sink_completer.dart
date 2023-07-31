// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'channel.dart';

/// A [WebSocketSink] where the destination is provided later.
///
/// This is like a `StreamSinkCompleter`, except that it properly forwards
/// parameters to [WebSocketSink.close].
class WebSocketSinkCompleter {
  /// The sink for this completer.
  ///
  /// When a destination sink is provided, events that have been passed to the
  /// sink will be forwarded to the destination.
  ///
  /// Events can be added to the sink either before or after a destination sink
  /// is set.
  final WebSocketSink sink = _CompleterSink();

  /// Returns [sink] typed as a [_CompleterSink].
  _CompleterSink get _sink => sink as _CompleterSink;

  /// Sets a sink as the destination for events from the
  /// [WebSocketSinkCompleter]'s [sink].
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
  void setDestinationSink(WebSocketSink destinationSink) {
    if (_sink._destinationSink != null) {
      throw StateError('Destination sink already set');
    }
    _sink._setDestinationSink(destinationSink);
  }
}

/// [WebSocketSink] completed by [WebSocketSinkCompleter].
class _CompleterSink implements WebSocketSink {
  /// Controller for an intermediate sink.
  ///
  /// Created if the user adds events to this sink before the destination sink
  /// is set.
  StreamController? _controller;

  /// Completer for [done].
  ///
  /// Created if the user requests the [done] future before the destination sink
  /// is set.
  Completer? _doneCompleter;

  /// Destination sink for the events added to this sink.
  ///
  /// Set when [WebSocketSinkCompleter.setDestinationSink] is called.
  WebSocketSink? _destinationSink;

  /// The close code passed to [close].
  int? _closeCode;

  /// The close reason passed to [close].
  String? _closeReason;

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
  void add(event) {
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
  Future addStream(Stream stream) {
    if (_canSendDirectly) return _destinationSink!.addStream(stream);

    final controller = _ensureController();
    return controller.addStream(stream, cancelOnError: false);
  }

  @override
  Future close([int? closeCode, String? closeReason]) {
    if (_canSendDirectly) {
      _destinationSink!.close(closeCode, closeReason);
    } else {
      _closeCode = closeCode;
      _closeReason = closeReason;
      _ensureController().close();
    }
    return done;
  }

  /// Create [_controller] if it doesn't yet exist.
  StreamController _ensureController() =>
      _controller ??= StreamController(sync: true);

  /// Sets the destination sink to which events from this sink will be provided.
  ///
  /// If set before the user adds events, events will be added directly to the
  /// destination sink. If the user adds events earlier, an intermediate sink is
  /// created using a stream controller, and the destination sink is linked to
  /// it later.
  void _setDestinationSink(WebSocketSink sink) {
    assert(_destinationSink == null);
    _destinationSink = sink;

    // If the user has already added data, it's buffered in the controller, so
    // we add it to the sink.
    if (_controller != null) {
      // Catch any error that may come from [addStream] or [sink.close]. They'll
      // be reported through [done] anyway.
      sink
          .addStream(_controller!.stream)
          .whenComplete(() => sink.close(_closeCode, _closeReason))
          .catchError((_) {});
    }

    // If the user has already asked when the sink is done, connect the sink's
    // done callback to that completer.
    if (_doneCompleter != null) {
      _doneCompleter!.complete(sink.done);
    }
  }
}
