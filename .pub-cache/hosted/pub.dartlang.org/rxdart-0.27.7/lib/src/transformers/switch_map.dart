import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _SwitchMapStreamSink<S, T> extends ForwardingSink<S, T> {
  final Stream<T> Function(S value) _mapper;
  StreamSubscription<T>? _mapperSubscription;
  bool _inputClosed = false;

  _SwitchMapStreamSink(this._mapper);

  @override
  void onData(S data) {
    final Stream<T> mappedStream;
    try {
      mappedStream = _mapper(data);
    } catch (e, s) {
      sink.addError(e, s);
      return;
    }

    _mapperSubscription?.cancel();

    _mapperSubscription = mappedStream.listen(
      sink.add,
      onError: sink.addError,
      onDone: () {
        _mapperSubscription = null;

        if (_inputClosed) {
          sink.close();
        }
      },
    );
  }

  @override
  void onError(Object e, StackTrace st) => sink.addError(e, st);

  @override
  void onDone() {
    _inputClosed = true;

    _mapperSubscription ?? sink.close();
  }

  @override
  FutureOr<void> onCancel() => _mapperSubscription?.cancel();

  @override
  void onListen() {}

  @override
  void onPause() => _mapperSubscription?.pause();

  @override
  void onResume() => _mapperSubscription?.resume();
}

/// Converts each emitted item into a new Stream using the given mapper
/// function. The newly created Stream will be be listened to and begin
/// emitting items, and any previously created Stream will stop emitting.
///
/// The switchMap operator is similar to the flatMap and concatMap
/// methods, but it only emits items from the most recently created Stream.
///
/// This can be useful when you only want the very latest state from
/// asynchronous APIs, for example.
///
/// ### Example
///
///     Stream.fromIterable([4, 3, 2, 1])
///       .transform(SwitchMapStreamTransformer((i) =>
///         Stream.fromFuture(
///           Future.delayed(Duration(minutes: i), () => i))
///       .listen(print); // prints 1
class SwitchMapStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  /// Method which converts incoming events into a new [Stream]
  final Stream<T> Function(S value) mapper;

  /// Constructs a [StreamTransformer] which maps each event from the source [Stream]
  /// using [mapper].
  ///
  /// The mapped [Stream] will be be listened to and begin
  /// emitting items, and any previously created mapper [Stream]s will stop emitting.
  SwitchMapStreamTransformer(this.mapper);

  @override
  Stream<T> bind(Stream<S> stream) =>
      forwardStream(stream, () => _SwitchMapStreamSink(mapper));
}

/// Extends the Stream with the ability to convert one stream into a new Stream
/// whenever the source emits an item. Every time a new Stream is created, the
/// previous Stream is discarded.
extension SwitchMapExtension<T> on Stream<T> {
  /// Converts each emitted item into a Stream using the given mapper function.
  /// The newly created Stream will be be listened to and begin emitting items,
  /// and any previously created Stream will stop emitting.
  ///
  /// The switchMap operator is similar to the flatMap and concatMap methods,
  /// but it only emits items from the most recently created Stream.
  ///
  /// This can be useful when you only want the very latest state from
  /// asynchronous APIs, for example.
  ///
  /// ### Example
  ///
  ///     RangeStream(4, 1)
  ///       .switchMap((i) =>
  ///         TimerStream(i, Duration(minutes: i)))
  ///       .listen(print); // prints 1
  Stream<S> switchMap<S>(Stream<S> Function(T value) mapper) =>
      SwitchMapStreamTransformer<T, S>(mapper).bind(this);
}
