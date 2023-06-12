import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';

/// @private
/// Helper method which forwards the events from an incoming [Stream]
/// to a new [StreamController].
/// It captures events such as onListen, onPause, onResume and onCancel,
/// which can be used in pair with a [ForwardingSink]
Stream<R> forwardStream<T, R>(
  Stream<T> stream,
  ForwardingSink<T, R> Function() sinkFactory, [
  bool listenOnlyOnce = false,
]) {
  return stream.isBroadcast
      ? listenOnlyOnce
          ? _forward(stream, sinkFactory)
          : _forwardMulti(stream, sinkFactory)
      : _forward(stream, sinkFactory);
}

Stream<R> _forwardMulti<T, R>(
    Stream<T> stream, ForwardingSink<T, R> Function() sinkFactory) {
  return Stream<R>.multi((controller) {
    final sink = sinkFactory();
    sink.setSink(_MultiControllerSink(controller));

    StreamSubscription<T>? subscription;
    var cancelled = false;

    void listenToUpstream([void _]) {
      if (cancelled) {
        return;
      }
      subscription = stream.listen(
        sink.onData,
        onError: sink.onError,
        onDone: sink.onDone,
      );
    }

    final futureOrVoid = sink.onListen();
    if (futureOrVoid is Future<void>) {
      futureOrVoid.then(listenToUpstream).onError<Object>((e, s) {
        if (!cancelled && !controller.isClosed) {
          controller.addError(e, s);
          controller.close();
        }
      });
    } else {
      listenToUpstream();
    }

    controller.onCancel = () {
      cancelled = true;

      final future = subscription?.cancel();
      subscription = null;
      return _waitFutures(future, sink.onCancel());
    };
  }, isBroadcast: true);
}

Stream<R> _forward<T, R>(
  Stream<T> stream,
  ForwardingSink<T, R> Function() sinkFactory,
) {
  final controller = stream.isBroadcast
      ? StreamController<R>.broadcast(sync: true)
      : StreamController<R>(sync: true);

  StreamSubscription<T>? subscription;
  var cancelled = false;
  late final sink = sinkFactory();

  controller.onListen = () {
    void listenToUpstream([void _]) {
      if (cancelled) {
        return;
      }
      subscription = stream.listen(
        sink.onData,
        onError: sink.onError,
        onDone: sink.onDone,
      );

      if (!stream.isBroadcast) {
        controller.onPause = () {
          subscription!.pause();
          sink.onPause();
        };
        controller.onResume = () {
          subscription!.resume();
          sink.onResume();
        };
      }
    }

    sink.setSink(controller);
    final futureOrVoid = sink.onListen();
    if (futureOrVoid is Future<void>) {
      futureOrVoid.then(listenToUpstream).onError<Object>((e, s) {
        if (!cancelled && !controller.isClosed) {
          controller.addError(e, s);
          controller.close();
        }
      });
    } else {
      listenToUpstream();
    }
  };
  controller.onCancel = () {
    cancelled = true;

    final future = subscription?.cancel();
    subscription = null;

    return _waitFutures(future, sink.onCancel());
  };
  return controller.stream;
}

FutureOr<void> _waitFutures(Future<void>? f1, FutureOr<void> f2) => f1 == null
    ? f2
    : f2 is Future<void>
        ? Future.wait([f1, f2])
        : f1;

class _MultiControllerSink<T> implements EventSink<T> {
  final MultiStreamController<T> controller;

  _MultiControllerSink(this.controller);

  @override
  void add(T event) => controller.addSync(event);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      controller.addErrorSync(error, stackTrace);

  @override
  void close() => controller.closeSync();
}
