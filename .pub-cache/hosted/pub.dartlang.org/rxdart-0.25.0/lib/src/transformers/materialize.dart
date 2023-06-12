import 'dart:async';

import 'package:rxdart/src/utils/notification.dart';

class _MaterializeStreamSink<S> implements EventSink<S> {
  final EventSink<Notification<S>> _outputSink;

  _MaterializeStreamSink(this._outputSink);

  @override
  void add(S data) {
    _outputSink.add(Notification.onData(data));
  }

  @override
  void addError(e, [st]) => _outputSink.add(Notification.onError(e, st));

  @override
  void close() {
    _outputSink.add(Notification.onDone());
    _outputSink.close();
  }
}

/// Converts the onData, on Done, and onError events into [Notification]
/// objects that are passed into the downstream onData listener.
///
/// The [Notification] object contains the [Kind] of event (OnData, onDone, or
/// OnError), and the item or error that was emitted. In the case of onDone,
/// no data is emitted as part of the [Notification].
///
/// ### Example
///
///     Stream<int>.fromIterable([1])
///         .transform(MaterializeStreamTransformer())
///         .listen((i) => print(i)); // Prints onData & onDone Notification
class MaterializeStreamTransformer<S>
    extends StreamTransformerBase<S, Notification<S>> {
  /// Constructs a [StreamTransformer] which transforms the onData, on Done,
  /// and onError events into [Notification] objects.
  MaterializeStreamTransformer();

  @override
  Stream<Notification<S>> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _MaterializeStreamSink<S>(sink));
}

/// Extends the Stream class with the ability to convert the onData, on Done,
/// and onError events into [Notification]s that are passed into the
/// downstream onData listener.
extension MaterializeExtension<T> on Stream<T> {
  /// Converts the onData, on Done, and onError events into [Notification]
  /// objects that are passed into the downstream onData listener.
  ///
  /// The [Notification] object contains the [Kind] of event (OnData, onDone, or
  /// OnError), and the item or error that was emitted. In the case of onDone,
  /// no data is emitted as part of the [Notification].
  ///
  /// Example:
  ///     Stream<int>.fromIterable([1])
  ///         .materialize()
  ///         .listen((i) => print(i)); // Prints onData & onDone Notification
  ///
  ///     Stream<int>.error(Exception())
  ///         .materialize()
  ///         .listen((i) => print(i)); // Prints onError Notification
  Stream<Notification<T>> materialize() =>
      transform(MaterializeStreamTransformer<T>());
}
