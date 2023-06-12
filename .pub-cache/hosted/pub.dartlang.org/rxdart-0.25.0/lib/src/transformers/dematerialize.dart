import 'dart:async';

import 'package:rxdart/src/utils/notification.dart';

class _DematerializeStreamSink<S> implements EventSink<Notification<S>> {
  final EventSink<S> _outputSink;

  _DematerializeStreamSink(this._outputSink);

  @override
  void add(Notification<S> data) {
    if (data.isOnData) {
      _outputSink.add(data.value);
    } else if (data.isOnDone) {
      _outputSink.close();
    } else if (data.isOnError) {
      _outputSink.addError(
        data.errorAndStackTrace.error,
        data.errorAndStackTrace.stackTrace,
      );
    }
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();
}

/// Converts the onData, onDone, and onError [Notification] objects from a
/// materialized stream into normal onData, onDone, and onError events.
///
/// When a stream has been materialized, it emits onData, onDone, and onError
/// events as [Notification] objects. Dematerialize simply reverses this by
/// transforming [Notification] objects back to a normal stream of events.
///
/// ### Example
///
///     Stream<Notification<int>>
///         .fromIterable([Notification.onData(1), Notification.onDone()])
///         .transform(DematerializeStreamTransformer())
///         .listen((i) => print(i)); // Prints 1
///
/// ### Error example
///
///     Stream<Notification<int>>
///         .fromIterable([Notification.onError(Exception(), null)])
///         .transform(DematerializeStreamTransformer())
///         .listen(null, onError: (e, s) { print(e) }); // Prints Exception
class DematerializeStreamTransformer<S>
    extends StreamTransformerBase<Notification<S>, S> {
  /// Constructs a [StreamTransformer] which converts the onData, onDone, and
  /// onError [Notification] objects from a materialized stream into normal
  /// onData, onDone, and onError events.
  DematerializeStreamTransformer();

  @override
  Stream<S> bind(Stream<Notification<S>> stream) =>
      Stream.eventTransformed(stream, (sink) => _DematerializeStreamSink(sink));
}

/// Converts the onData, onDone, and onError [Notification]s from a
/// materialized stream into normal onData, onDone, and onError events.
extension DematerializeExtension<T> on Stream<Notification<T>> {
  /// Converts the onData, onDone, and onError [Notification] objects from a
  /// materialized stream into normal onData, onDone, and onError events.
  ///
  /// When a stream has been materialized, it emits onData, onDone, and onError
  /// events as [Notification] objects. Dematerialize simply reverses this by
  /// transforming [Notification] objects back to a normal stream of events.
  ///
  /// ### Example
  ///
  ///     Stream<Notification<int>>
  ///         .fromIterable([Notification.onData(1), Notification.onDone()])
  ///         .dematerialize()
  ///         .listen((i) => print(i)); // Prints 1
  ///
  /// ### Error example
  ///
  ///     Stream<Notification<int>>
  ///         .fromIterable([Notification.onError(Exception(), null)])
  ///         .dematerialize()
  ///         .listen(null, onError: (e, s) { print(e) }); // Prints Exception
  Stream<T> dematerialize() {
    return transform(DematerializeStreamTransformer<T>());
  }
}
