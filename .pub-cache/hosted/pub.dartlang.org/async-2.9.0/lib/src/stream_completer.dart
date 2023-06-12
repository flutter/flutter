// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A single-subscription [stream] where the contents are provided later.
///
/// It is generally recommended that you never create a `Future<Stream>`
/// because you can just directly create a stream that doesn't do anything
/// until it's ready to do so.
/// This class can be used to create such a stream.
///
/// The [stream] is a normal stream that you can listen to immediately,
/// but until either [setSourceStream] or [setEmpty] is called,
/// the stream won't produce any events.
///
/// The same effect can be achieved by using a [StreamController]
/// and adding the stream using `addStream` when both
/// the controller's stream is listened to and the source stream is ready.
/// This class attempts to shortcut some of the overhead when possible.
/// For example, if the [stream] is only listened to
/// after the source stream has been set,
/// the listen is performed directly on the source stream.
class StreamCompleter<T> {
  /// The stream doing the actual work, is returned by [stream].
  final _stream = _CompleterStream<T>();

  /// Convert a `Future<Stream>` to a `Stream`.
  ///
  /// This creates a stream using a stream completer,
  /// and sets the source stream to the result of the future when the
  /// future completes.
  ///
  /// If the future completes with an error, the returned stream will
  /// instead contain just that error.
  static Stream<T> fromFuture<T>(Future<Stream<T>> streamFuture) {
    var completer = StreamCompleter<T>();
    streamFuture.then(completer.setSourceStream, onError: completer.setError);
    return completer.stream;
  }

  /// The stream of this completer.
  ///
  /// This stream is always a single-subscription stream.
  ///
  /// When a source stream is provided, its events will be forwarded to
  /// listeners on this stream.
  ///
  /// The stream can be listened either before or after a source stream
  /// is set.
  Stream<T> get stream => _stream;

  /// Set a stream as the source of events for the [StreamCompleter]'s
  /// [stream].
  ///
  /// The completer's `stream` will act exactly as [sourceStream].
  ///
  /// If the source stream is set before [stream] is listened to,
  /// the listen call on [stream] is forwarded directly to [sourceStream].
  ///
  /// If [stream] is listened to before setting the source stream,
  /// an intermediate subscription is created. It looks like a completely
  /// normal subscription, and can be paused or canceled, but it won't
  /// produce any events until a source stream is provided.
  ///
  /// If the `stream` subscription is canceled before a source stream is set,
  /// the source stream will be listened to and immediately canceled again.
  ///
  /// Otherwise, when the source stream is then set,
  /// it is immediately listened to, and its events are forwarded to the
  /// existing subscription.
  ///
  /// Any one of [setSourceStream], [setEmpty], and [setError] may be called at
  /// most once. Trying to call any of them again will fail.
  void setSourceStream(Stream<T> sourceStream) {
    if (_stream._isSourceStreamSet) {
      throw StateError('Source stream already set');
    }
    _stream._setSourceStream(sourceStream);
  }

  /// Equivalent to setting an empty stream using [setSourceStream].
  ///
  /// Any one of [setSourceStream], [setEmpty], and [setError] may be called at
  /// most once. Trying to call any of them again will fail.
  void setEmpty() {
    if (_stream._isSourceStreamSet) {
      throw StateError('Source stream already set');
    }
    _stream._setEmpty();
  }

  /// Completes this to a stream that emits [error] and then closes.
  ///
  /// This is useful when the process of creating the data for the stream fails.
  ///
  /// Any one of [setSourceStream], [setEmpty], and [setError] may be called at
  /// most once. Trying to call any of them again will fail.
  void setError(Object error, [StackTrace? stackTrace]) {
    setSourceStream(Stream.fromFuture(Future.error(error, stackTrace)));
  }
}

/// Stream completed by [StreamCompleter].
class _CompleterStream<T> extends Stream<T> {
  /// Controller for an intermediate stream.
  ///
  /// Created if the user listens on this stream before the source stream
  /// is set, or if using [_setEmpty] so there is no source stream.
  StreamController<T>? _controller;

  /// Source stream for the events provided by this stream.
  ///
  /// Set when the completer sets the source stream using [_setSourceStream]
  /// or [_setEmpty].
  Stream<T>? _sourceStream;

  @override
  StreamSubscription<T> listen(void Function(T)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    if (_controller == null) {
      var sourceStream = _sourceStream;
      if (sourceStream != null && !sourceStream.isBroadcast) {
        // If the source stream is itself single subscription,
        // just listen to it directly instead of creating a controller.
        return sourceStream.listen(onData,
            onError: onError, onDone: onDone, cancelOnError: cancelOnError);
      }
      _ensureController();
      if (_sourceStream != null) {
        _linkStreamToController();
      }
    }
    return _controller!.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// Whether a source stream has been set.
  ///
  /// Used to throw an error if trying to set a source stream twice.
  bool get _isSourceStreamSet => _sourceStream != null;

  /// Sets the source stream providing the events for this stream.
  ///
  /// If set before the user listens, listen calls will be directed directly
  /// to the source stream. If the user listenes earlier, and intermediate
  /// stream is created using a stream controller, and the source stream is
  /// linked into that stream later.
  void _setSourceStream(Stream<T> sourceStream) {
    assert(_sourceStream == null);
    _sourceStream = sourceStream;
    if (_controller != null) {
      // User has already listened, so provide the data through controller.
      _linkStreamToController();
    }
  }

  /// Links source stream to controller when both are available.
  void _linkStreamToController() {
    var controller = _controller!;
    controller
        .addStream(_sourceStream!, cancelOnError: false)
        .whenComplete(controller.close);
  }

  /// Sets an empty source stream.
  ///
  /// Uses [_controller] for the stream, then closes the controller
  /// immediately.
  void _setEmpty() {
    assert(_sourceStream == null);
    var controller = _ensureController();
    _sourceStream = controller.stream; // Mark stream as set.
    controller.close();
  }

  // Creates the [_controller].
  StreamController<T> _ensureController() {
    return _controller ??= StreamController<T>(sync: true);
  }
}
