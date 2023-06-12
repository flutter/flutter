import 'dart:async';

import 'package:rxdart/src/utils/collection_extensions.dart';
import 'package:rxdart/src/utils/subscription.dart';

/// This operator is best used when you have a group of streams
/// and only care about the final emitted value of each.
/// One common use case for this is if you wish to issue multiple
/// requests on page load (or some other event)
/// and only want to take action when a response has been received for all.
///
/// In this way it is similar to how you might use [Future.wait].
///
/// Be aware that if any of the inner streams supplied to forkJoin error
/// you will lose the value of any other streams that would or have already
/// completed if you do not catch the error correctly on the inner stream.
///
/// If you are only concerned with all inner streams completing
/// successfully you can catch the error on the outside.
/// It's also worth noting that if you have an stream
/// that emits more than one item, and you are concerned with the previous
/// emissions forkJoin is not the correct choice.
///
/// In these cases you may better off with an operator like combineLatest or zip.
///
/// If the provided streams is empty, the resulting sequence completes immediately
/// without emitting any items and without any calls to the combiner function.
///
/// ### Basic Example
///
/// This constructor takes in an `Iterable<Stream<T>>` and outputs a
/// `Stream<Iterable<T>>` whenever any of the values change from the source
/// stream. This is useful with a dynamic number of source streams!
///
///     ForkJoinStream.list<String>([
///       Stream.fromIterable(['a']),
///       Stream.fromIterable(['b']),
///       Stream.fromIterable(['C', 'D'])])
///     .listen(print); //prints ['a', 'b', 'D']
///
/// ### Example with combiner
///
/// If you wish to combine the list of values into a new object before you
///
///     CombineLatestStream(
///       [
///         Stream.fromIterable(['a']),
///         Stream.fromIterable(['b']),
///         Stream.fromIterable(['C', 'D'])
///       ],
///       (values) => values.last
///     )
///     .listen(print); //prints 'D'
///
/// ### Example with a specific number of Streams
///
/// If you wish to combine a specific number of Streams together with proper
/// types information for the value of each Stream, use the
/// [combine2] - [combine9] operators.
///
///     ForkJoinStream.combine2(
///       Stream.fromIterable([1]),
///       Stream.fromIterable([2, 3]),
///       (a, b) => a + b,
///     )
///     .listen(print); // prints 4
class ForkJoinStream<T, R> extends StreamView<R> {
  /// Constructs a [Stream] that awaits the last values of the [Stream]s
  /// in [streams], then calls the [combiner] to emit an event of type [R].
  /// After this event, the [Stream] closes.
  ForkJoinStream(
    Iterable<Stream<T>> streams,
    R Function(List<T> values) combiner,
  ) : super(_buildStream(streams, combiner));

  /// Constructs a [Stream] that awaits the last values of the [Stream]s
  /// in [streams] and then emits these values as a [List].
  /// After this event, the [Stream] closes.
  static ForkJoinStream<T, List<T>> list<T>(
    Iterable<Stream<T>> streams,
  ) =>
      ForkJoinStream<T, List<T>>(
        streams,
        (values) => values,
      );

  /// Constructs a [Stream] that awaits the last values the provided [Stream]s,
  /// then calls the [combiner] to emit an event of type [R].
  /// After this event, the [Stream] closes.
  static ForkJoinStream<dynamic, R> combine2<A, B, R>(
    Stream<A> streamOne,
    Stream<B> streamTwo,
    R Function(A a, B b) combiner,
  ) =>
      ForkJoinStream<dynamic, R>(
        [streamOne, streamTwo],
        (List<dynamic> values) => combiner(values[0] as A, values[1] as B),
      );

  /// Constructs a [Stream] that awaits the last values the provided [Stream]s,
  /// then calls the [combiner] to emit an event of type [R].
  /// After this event, the [Stream] closes.
  static ForkJoinStream<dynamic, R> combine3<A, B, C, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    R Function(A a, B b, C c) combiner,
  ) =>
      ForkJoinStream<dynamic, R>(
        [streamA, streamB, streamC],
        (List<dynamic> values) {
          return combiner(
            values[0] as A,
            values[1] as B,
            values[2] as C,
          );
        },
      );

  /// Constructs a [Stream] that awaits the last values the provided [Stream]s,
  /// then calls the [combiner] to emit an event of type [R].
  /// After this event, the [Stream] closes.
  static ForkJoinStream<dynamic, R> combine4<A, B, C, D, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    R Function(A a, B b, C c, D d) combiner,
  ) =>
      ForkJoinStream<dynamic, R>(
        [streamA, streamB, streamC, streamD],
        (List<dynamic> values) {
          return combiner(
            values[0] as A,
            values[1] as B,
            values[2] as C,
            values[3] as D,
          );
        },
      );

  /// Constructs a [Stream] that awaits the last values the provided [Stream]s,
  /// then calls the [combiner] to emit an event of type [R].
  /// After this event, the [Stream] closes.
  static ForkJoinStream<dynamic, R> combine5<A, B, C, D, E, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    R Function(A a, B b, C c, D d, E e) combiner,
  ) =>
      ForkJoinStream<dynamic, R>(
        [streamA, streamB, streamC, streamD, streamE],
        (List<dynamic> values) {
          return combiner(
            values[0] as A,
            values[1] as B,
            values[2] as C,
            values[3] as D,
            values[4] as E,
          );
        },
      );

  /// Constructs a [Stream] that awaits the last values the provided [Stream]s,
  /// then calls the [combiner] to emit an event of type [R].
  /// After this event, the [Stream] closes.
  static ForkJoinStream<dynamic, R> combine6<A, B, C, D, E, F, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    Stream<F> streamF,
    R Function(A a, B b, C c, D d, E e, F f) combiner,
  ) =>
      ForkJoinStream<dynamic, R>(
        [streamA, streamB, streamC, streamD, streamE, streamF],
        (List<dynamic> values) {
          return combiner(
            values[0] as A,
            values[1] as B,
            values[2] as C,
            values[3] as D,
            values[4] as E,
            values[5] as F,
          );
        },
      );

  /// Constructs a [Stream] that awaits the last values the provided [Stream]s,
  /// then calls the [combiner] to emit an event of type [R].
  /// After this event, the [Stream] closes.
  static ForkJoinStream<dynamic, R> combine7<A, B, C, D, E, F, G, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    Stream<F> streamF,
    Stream<G> streamG,
    R Function(A a, B b, C c, D d, E e, F f, G g) combiner,
  ) =>
      ForkJoinStream<dynamic, R>(
        [streamA, streamB, streamC, streamD, streamE, streamF, streamG],
        (List<dynamic> values) {
          return combiner(
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

  /// Constructs a [Stream] that awaits the last values the provided [Stream]s,
  /// then calls the [combiner] to emit an event of type [R].
  /// After this event, the [Stream] closes.
  static ForkJoinStream<dynamic, R> combine8<A, B, C, D, E, F, G, H, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    Stream<F> streamF,
    Stream<G> streamG,
    Stream<H> streamH,
    R Function(A a, B b, C c, D d, E e, F f, G g, H h) combiner,
  ) =>
      ForkJoinStream<dynamic, R>(
        [
          streamA,
          streamB,
          streamC,
          streamD,
          streamE,
          streamF,
          streamG,
          streamH
        ],
        (List<dynamic> values) {
          return combiner(
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

  /// Constructs a [Stream] that awaits the last values the provided [Stream]s,
  /// then calls the [combiner] to emit an event of type [R].
  /// After this event, the [Stream] closes.
  static ForkJoinStream<dynamic, R> combine9<A, B, C, D, E, F, G, H, I, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    Stream<E> streamE,
    Stream<F> streamF,
    Stream<G> streamG,
    Stream<H> streamH,
    Stream<I> streamI,
    R Function(A a, B b, C c, D d, E e, F f, G g, H h, I i) combiner,
  ) =>
      ForkJoinStream<dynamic, R>(
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
          return combiner(
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

  static Stream<R> _buildStream<T, R>(
    Iterable<Stream<T>> streams,
    R Function(List<T> values) combiner,
  ) {
    final controller = StreamController<R>(sync: true);
    late List<StreamSubscription<T>> subscriptions;
    List<T?>? values;

    controller.onListen = () {
      var completed = 0;

      StreamSubscription<T> listen(int i, Stream<T> stream) {
        var hasValue = false;

        return stream.listen(
          (value) {
            hasValue = true;
            values?[i] = value;
          },
          onError: controller.addError,
          onDone: () {
            if (!hasValue) {
              controller.addError(StateError('No element'));
              controller.close();
              return;
            }

            if (values == null) {
              return;
            }
            if (++completed == subscriptions.length) {
              final R combined;
              try {
                combined = combiner(List<T>.unmodifiable(values!));
              } catch (e, s) {
                controller.addError(e, s);
                controller.close();
                return;
              }

              controller.add(combined);
              controller.close();
            }
          },
        );
      }

      subscriptions = streams.mapIndexed(listen).toList(growable: false);
      if (subscriptions.isEmpty) {
        controller.close();
      } else {
        values = List<T?>.filled(subscriptions.length, null);
      }
    };
    controller.onPause = () => subscriptions.pauseAll();
    controller.onResume = () => subscriptions.resumeAll();
    controller.onCancel = () {
      values = null;
      return subscriptions.cancelAll();
    };

    return controller.stream;
  }
}
