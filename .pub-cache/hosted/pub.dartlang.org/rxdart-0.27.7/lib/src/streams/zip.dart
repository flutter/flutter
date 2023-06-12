import 'dart:async';

import 'package:rxdart/src/utils/collection_extensions.dart';
import 'package:rxdart/src/utils/subscription.dart';

/// Merges the specified streams into one stream sequence using the given
/// zipper Function whenever all of the stream sequences have produced
/// an element at a corresponding index.
///
/// It applies this function in strict sequence, so the first item emitted by
/// the new Stream will be the result of the function applied to the first
/// item emitted by Stream #1 and the first item emitted by Stream #2;
/// the second item emitted by the new ZipStream will be the result of
/// the function applied to the second item emitted by Stream #1 and the
/// second item emitted by Stream #2; and so forth. It will only emit as
/// many items as the number of items emitted by the source Stream that
/// emits the fewest items.
///
/// If the provided streams is empty, the resulting sequence completes immediately
/// without emitting any items and without any calls to the zipper function.
///
/// [Interactive marble diagram](http://rxmarbles.com/#zip)
///
/// ### Basic Example
///
///     ZipStream(
///       [
///         Stream.fromIterable(['A']),
///         Stream.fromIterable(['B']),
///         Stream.fromIterable(['C', 'D']),
///       ],
///       (values) => values.join(),
///     ).listen(print); // prints 'ABC'
///
/// ### Example with a specific number of Streams
///
/// If you wish to zip a specific number of Streams together with proper types
/// information for the value of each Stream, use the [zip2] - [zip9] operators.
///
///     ZipStream.zip2(
///       Stream.fromIterable(['A']),
///       Stream.fromIterable(['B', 'C']),
///       (a, b) => a + b,
///     )
///     .listen(print); // prints 'AB'
class ZipStream<T, R> extends StreamView<R> {
  /// Constructs a [Stream] which merges the specified [streams] into a sequence using the given
  /// [zipper] Function, whenever all of the [streams] have produced
  /// an element at a corresponding index.
  ZipStream(
    Iterable<Stream<T>> streams,
    R Function(List<T> values) zipper,
  ) : super(_buildController(streams, zipper).stream);

  /// Constructs a [Stream] which merges the specified [streams] into a [List],
  /// containing values that were produced by the [streams] at a corresponding index.
  static ZipStream<T, List<T>> list<T>(Iterable<Stream<T>> streams) {
    return ZipStream<T, List<T>>(
      streams,
      (List<T> values) => values,
    );
  }

  /// Constructs a [Stream] which merges the specified [Stream]s into a sequence using the given
  /// [zipper] Function, whenever all of the provided [Stream]s have produced
  /// an element at a corresponding index.
  static ZipStream<dynamic, R> zip2<A, B, R>(
    Stream<A> streamOne,
    Stream<B> streamTwo,
    R Function(A a, B b) zipper,
  ) {
    return ZipStream<dynamic, R>(
      [streamOne, streamTwo],
      (List<dynamic> values) => zipper(values[0] as A, values[1] as B),
    );
  }

  /// Constructs a [Stream] which merges the specified [Stream]s into a sequence using the given
  /// [zipper] Function, whenever all of the provided [Stream]s have produced
  /// an element at a corresponding index.
  static ZipStream<dynamic, R> zip3<A, B, C, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    R Function(A a, B b, C c) zipper,
  ) {
    return ZipStream<dynamic, R>(
      [streamA, streamB, streamC],
      (List<dynamic> values) {
        return zipper(
          values[0] as A,
          values[1] as B,
          values[2] as C,
        );
      },
    );
  }

  /// Constructs a [Stream] which merges the specified [Stream]s into a sequence using the given
  /// [zipper] Function, whenever all of the provided [Stream]s have produced
  /// an element at a corresponding index.
  static ZipStream<dynamic, R> zip4<A, B, C, D, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    R Function(A a, B b, C c, D d) zipper,
  ) {
    return ZipStream<dynamic, R>(
      [streamA, streamB, streamC, streamD],
      (List<dynamic> values) {
        return zipper(
          values[0] as A,
          values[1] as B,
          values[2] as C,
          values[3] as D,
        );
      },
    );
  }

  /// Constructs a [Stream] which merges the specified [Stream]s into a sequence using the given
  /// [zipper] Function, whenever all of the provided [Stream]s have produced
  /// an element at a corresponding index.
  static ZipStream<dynamic, R> zip5<A, B, C, D, E, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    R Function(A a, B b, C c, D d, E e) zipper,
  ) {
    return ZipStream<dynamic, R>(
      [streamA, streamB, streamC, streamD, streamE],
      (List<dynamic> values) {
        return zipper(
          values[0] as A,
          values[1] as B,
          values[2] as C,
          values[3] as D,
          values[4] as E,
        );
      },
    );
  }

  /// Constructs a [Stream] which merges the specified [Stream]s into a sequence using the given
  /// [zipper] Function, whenever all of the provided [Stream]s have produced
  /// an element at a corresponding index.
  static ZipStream<dynamic, R> zip6<A, B, C, D, E, F, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    Stream<F> streamF,
    R Function(A a, B b, C c, D d, E e, F f) zipper,
  ) {
    return ZipStream<dynamic, R>(
      [streamA, streamB, streamC, streamD, streamE, streamF],
      (List<dynamic> values) {
        return zipper(
          values[0] as A,
          values[1] as B,
          values[2] as C,
          values[3] as D,
          values[4] as E,
          values[5] as F,
        );
      },
    );
  }

  /// Constructs a [Stream] which merges the specified [Stream]s into a sequence using the given
  /// [zipper] Function, whenever all of the provided [Stream]s have produced
  /// an element at a corresponding index.
  static ZipStream<dynamic, R> zip7<A, B, C, D, E, F, G, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    Stream<F> streamF,
    Stream<G> streamG,
    R Function(A a, B b, C c, D d, E e, F f, G g) zipper,
  ) {
    return ZipStream<dynamic, R>(
      [streamA, streamB, streamC, streamD, streamE, streamF, streamG],
      (List<dynamic> values) {
        return zipper(
          values[0] as A,
          values[1] as B,
          values[2] as C,
          values[3] as D,
          values[4] as E,
          values[5] as F,
          values[6] as G,
        );
      },
    );
  }

  /// Constructs a [Stream] which merges the specified [Stream]s into a sequence using the given
  /// [zipper] Function, whenever all of the provided [Stream]s have produced
  /// an element at a corresponding index.
  static ZipStream<dynamic, R> zip8<A, B, C, D, E, F, G, H, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    Stream<F> streamF,
    Stream<G> streamG,
    Stream<H> streamH,
    R Function(A a, B b, C c, D d, E e, F f, G g, H h) zipper,
  ) {
    return ZipStream<dynamic, R>(
      [streamA, streamB, streamC, streamD, streamE, streamF, streamG, streamH],
      (List<dynamic> values) {
        return zipper(
          values[0] as A,
          values[1] as B,
          values[2] as C,
          values[3] as D,
          values[4] as E,
          values[5] as F,
          values[6] as G,
          values[7] as H,
        );
      },
    );
  }

  /// Constructs a [Stream] which merges the specified [Stream]s into a sequence using the given
  /// [zipper] Function, whenever all of the provided [Stream]s have produced
  /// an element at a corresponding index.
  static ZipStream<dynamic, R> zip9<A, B, C, D, E, F, G, H, I, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    Stream<F> streamF,
    Stream<G> streamG,
    Stream<H> streamH,
    Stream<I> streamI,
    R Function(A a, B b, C c, D d, E e, F f, G g, H h, I i) zipper,
  ) {
    return ZipStream<dynamic, R>(
      [
        streamA,
        streamB,
        streamC,
        streamD,
        streamE,
        streamF,
        streamG,
        streamH,
        streamI
      ],
      (List<dynamic> values) {
        return zipper(
          values[0] as A,
          values[1] as B,
          values[2] as C,
          values[3] as D,
          values[4] as E,
          values[5] as F,
          values[6] as G,
          values[7] as H,
          values[8] as I,
        );
      },
    );
  }

  static StreamController<R> _buildController<T, R>(
    Iterable<Stream<T>> streams,
    R Function(List<T> values) zipper,
  ) {
    final controller = StreamController<R>(sync: true);
    late List<StreamSubscription<T>> subscriptions;
    var pendingSubscriptions = <StreamSubscription<T>>[];

    controller.onListen = () {
      Completer<void>? completeCurrent;
      late final _Window<T> window;

      // resets variables for the next zip window
      void next() {
        completeCurrent?.complete(null);
        completeCurrent = Completer<void>();

        pendingSubscriptions = subscriptions.toList();
      }

      void Function(T value) doUpdate(int index) {
        return (T value) {
          window.onValue(index, value);

          if (window.isComplete) {
            // all streams emitted for the current zip index
            // dispatch event and reset for next
            final R combined;
            try {
              combined = zipper(window.flush());
            } catch (e, s) {
              controller.addError(e, s);
              return;
            }
            controller.add(combined);

            // reset for next zip event
            next();
          } else {
            // other streams are still pending to get to the next
            // zip event index.
            // pause this subscription while we await the others
            final subscription = subscriptions[index]
              ..pause(completeCurrent!.future);

            pendingSubscriptions.remove(subscription);
          }
        };
      }

      subscriptions = streams
          .mapIndexed((index, stream) => stream.listen(doUpdate(index),
              onError: controller.addError, onDone: controller.close))
          .toList(growable: false);
      if (subscriptions.isEmpty) {
        controller.close();
      } else {
        window = _Window<T>(subscriptions.length);
        next();
      }
    };
    controller.onPause = () => pendingSubscriptions.pauseAll();
    controller.onResume = () => pendingSubscriptions.resumeAll();
    controller.onCancel = () => pendingSubscriptions.cancelAll();

    return controller;
  }
}

/// A window keeps track of the values emitted by the different
/// zipped Streams.
class _Window<T> {
  final int size;
  final List<T?> _values;

  int _valuesReceived = 0;

  bool get isComplete => _valuesReceived == size;

  _Window(this.size) : _values = List<T?>.filled(size, null);

  void onValue(int index, T value) {
    _values[index] = value;

    _valuesReceived++;
  }

  List<T> flush() {
    _valuesReceived = 0;

    return List<T>.unmodifiable(_values);
  }
}

/// Extends the Stream class with the ability to zip one Stream with another.
extension ZipWithExtension<T> on Stream<T> {
  /// Returns a Stream that combines the current stream together with another
  /// stream using a given zipper function.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1])
  ///         .zipWith(Stream.fromIterable([2]), (one, two) => one + two)
  ///         .listen(print); // prints 3
  Stream<R> zipWith<S, R>(Stream<S> other, R Function(T t, S s) zipper) {
    final stream = ZipStream.zip2(this, other, zipper);

    return isBroadcast
        ? stream.asBroadcastStream(onCancel: (s) => s.cancel())
        : stream;
  }
}
