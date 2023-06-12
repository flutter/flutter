import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _ExhaustMapStreamSink<S, T> implements ForwardingSink<S, T> {
  final Stream<T> Function(S value) _mapper;
  StreamSubscription<T> _mapperSubscription;
  bool _inputClosed = false;

  _ExhaustMapStreamSink(this._mapper);

  @override
  void add(EventSink<T> sink, S data) {
    if (_mapperSubscription != null) {
      return;
    }

    final mappedStream = _mapper(data);

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
  void addError(EventSink<T> sink, dynamic e, [st]) => sink.addError(e, st);

  @override
  void close(EventSink<T> sink) {
    _inputClosed = true;

    _mapperSubscription ?? sink.close();
  }

  @override
  FutureOr onCancel(EventSink<T> sink) => _mapperSubscription?.cancel();

  @override
  void onListen(EventSink<T> sink) {}

  @override
  void onPause(EventSink<T> sink) => _mapperSubscription?.pause();

  @override
  void onResume(EventSink<T> sink) => _mapperSubscription?.resume();
}

/// Converts events from the source stream into a new Stream using a given
/// mapper. It ignores all items from the source stream until the new stream
/// completes.
///
/// Useful when you have a noisy source Stream and only want to respond once
/// the previous async operation is finished.
///
/// ### Example
///     // Emits 0, 1, 2
///     Stream.periodic(Duration(milliseconds: 200), (i) => i).take(3)
///       .transform(ExhaustMapStreamTransformer(
///         // Emits the value it's given after 200ms
///         (i) => Rx.timer(i, Duration(milliseconds: 200)),
///       ))
///     .listen(print); // prints 0, 2
class ExhaustMapStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  /// Method which converts incoming events into a new [Stream]
  final Stream<T> Function(S value) mapper;

  /// Constructs a [StreamTransformer] which maps each event from the source [Stream]
  /// using [mapper].
  ///
  /// The mapped [Stream] will be be listened to and begin
  /// emitting items, and any previously created mapper [Stream]s will stop emitting.
  ExhaustMapStreamTransformer(this.mapper);

  @override
  Stream<T> bind(Stream<S> stream) =>
      forwardStream(stream, _ExhaustMapStreamSink(mapper));
}

/// Extends the Stream class with the ability to transform the Stream into
/// a new Stream. The new Stream emits items and ignores events from the source
/// Stream until the new Stream completes.
extension ExhaustMapExtension<T> on Stream<T> {
  /// Converts items from the source stream into a Stream using a given
  /// mapper. It ignores all items from the source stream until the new stream
  /// completes.
  ///
  /// Useful when you have a noisy source Stream and only want to respond once
  /// the previous async operation is finished.
  ///
  /// ### Example
  ///
  ///     RangeStream(0, 2).interval(Duration(milliseconds: 50))
  ///       .exhaustMap((i) =>
  ///         TimerStream(i, Duration(milliseconds: 75)))
  ///       .listen(print); // prints 0, 2
  Stream<S> exhaustMap<S>(Stream<S> Function(T value) mapper) =>
      transform(ExhaustMapStreamTransformer<T, S>(mapper));
}
