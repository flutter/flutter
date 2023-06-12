import 'dart:async';
import 'dart:collection';

import 'package:rxdart/src/rx.dart';
import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';
import 'package:rxdart/src/utils/subscription.dart';

class _DelayStreamSink<S> extends ForwardingSink<S, S> {
  final Duration _duration;
  var _inputClosed = false;
  final _subscriptions = Queue<StreamSubscription<void>>();

  _DelayStreamSink(this._duration);

  @override
  void onData(S data) {
    final subscription = Rx.timer<void>(null, _duration).listen((_) {
      _subscriptions.removeFirst();

      sink.add(data);

      if (_inputClosed && _subscriptions.isEmpty) {
        sink.close();
      }
    });

    _subscriptions.addLast(subscription);
  }

  @override
  void onError(Object error, StackTrace st) => sink.addError(error, st);

  @override
  void onDone() {
    _inputClosed = true;

    if (_subscriptions.isEmpty) {
      sink.close();
    }
  }

  @override
  Future<void>? onCancel() => _subscriptions.cancelAll();

  @override
  void onListen() {}

  @override
  void onPause() => _subscriptions.pauseAll();

  @override
  void onResume() => _subscriptions.resumeAll();
}

/// The Delay operator modifies its source Stream by pausing for
/// a particular increment of time (that you specify) before emitting
/// each of the source Stream’s items.
/// This has the effect of shifting the entire sequence of items emitted
/// by the Stream forward in time by that specified increment.
///
/// [Interactive marble diagram](http://rxmarbles.com/#delay)
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3, 4])
///       .delay(Duration(seconds: 1))
///       .listen(print); // [after one second delay] prints 1, 2, 3, 4 immediately
class DelayStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The delay used to pause initial emission of events by
  final Duration duration;

  /// Constructs a [StreamTransformer] which will first pause for [duration] of time,
  /// before submitting events from the source [Stream].
  DelayStreamTransformer(this.duration);

  @override
  Stream<S> bind(Stream<S> stream) =>
      forwardStream(stream, () => _DelayStreamSink<S>(duration));
}

/// Extends the Stream class with the ability to delay events being emitted
extension DelayExtension<T> on Stream<T> {
  /// The Delay operator modifies its source Stream by pausing for a particular
  /// increment of time (that you specify) before emitting each of the source
  /// Stream’s items. This has the effect of shifting the entire sequence of
  /// items emitted by the Stream forward in time by that specified increment.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#delay)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3, 4])
  ///       .delay(Duration(seconds: 1))
  ///       .listen(print); // [after one second delay] prints 1, 2, 3, 4 immediately
  Stream<T> delay(Duration duration) =>
      DelayStreamTransformer<T>(duration).bind(this);
}
