import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _WithLatestFromStreamSink<S, T, R> implements ForwardingSink<S, R> {
  final Iterable<Stream<T>> _latestFromStreams;
  final R Function(S t, List<T> values) _combiner;
  final List<bool> _hasValues;
  final List<T> _latestValues;
  List<StreamSubscription<T>> _subscriptions;

  _WithLatestFromStreamSink(this._latestFromStreams, this._combiner)
      : _hasValues = List.filled(_latestFromStreams.length, false),
        _latestValues = List<T>(_latestFromStreams.length);

  @override
  void add(EventSink<R> sink, S data) {
    if (_hasValues.every((value) => value)) {
      sink.add(_combiner(data, List.unmodifiable(_latestValues)));
    }
  }

  @override
  void addError(EventSink<R> sink, dynamic e, [st]) => sink.addError(e, st);

  @override
  void close(EventSink<R> sink) {
    _subscriptions?.forEach((it) => it.cancel());
    _subscriptions = null;
    sink.close();
  }

  @override
  FutureOr onCancel(EventSink<R> sink) {
    Iterable<Future> futures = <Future>[];

    if (_subscriptions != null && _subscriptions.isNotEmpty) {
      futures = _subscriptions.map((it) => it.cancel()).whereType<Future>();
    }

    return futures.isNotEmpty ? Future.wait<dynamic>(futures) : null;
  }

  @override
  void onListen(EventSink<R> sink) {
    var index = 0;

    final mapper = (Stream<T> stream) {
      var i = index++;
      return stream.listen(
        (it) {
          _hasValues[i] = true;
          _latestValues[i] = it;
        },
        onError: sink.addError,
      );
    };

    _subscriptions = _latestFromStreams.map(mapper).toList(growable: false);
  }

  @override
  void onPause(EventSink<R> sink) =>
      _subscriptions?.forEach((it) => it.pause());

  @override
  void onResume(EventSink<R> sink) =>
      _subscriptions?.forEach((it) => it.resume());
}

/// A StreamTransformer that emits when the source stream emits, combining
/// the latest values from the two streams using the provided function.
///
/// If the latestFromStream has not emitted any values, this stream will not
/// emit either.
///
/// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
///
/// ### Example
///
///     Stream.fromIterable([1, 2]).transform(
///       WithLatestFromStreamTransformer(
///         Stream.fromIterable([2, 3]), (a, b) => a + b)
///       .listen(print); // prints 4 (due to the async nature of streams)
class WithLatestFromStreamTransformer<S, T, R>
    extends StreamTransformerBase<S, R> {
  /// A collection of [Stream]s of which the latest values will be combined.
  final Iterable<Stream<T>> latestFromStreams;

  /// The combiner Function
  final R Function(S t, List<T> values) combiner;

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from [latestFromStreams] using the provided function [fn].
  WithLatestFromStreamTransformer(this.latestFromStreams, this.combiner) {
    if (latestFromStreams == null) {
      throw ArgumentError('latestFromStreams cannot be null');
    }
    if (latestFromStreams.any((s) => s == null)) {
      throw ArgumentError('All streams must be not null');
    }
    if (combiner == null) {
      throw ArgumentError('combiner cannot be null');
    }
  }

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from [latestFromStreams] using a [List].
  static WithLatestFromStreamTransformer<T, T, List<T>> withList<T>(
    Iterable<Stream<T>> latestFromStreams,
  ) {
    return WithLatestFromStreamTransformer<T, T, List<T>>(
      latestFromStreams,
      (s, values) => [s, ...values],
    );
  }

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from [latestFromStream] using the provided function [fn].
  static WithLatestFromStreamTransformer<T, S, R> with1<T, S, R>(
    Stream<S> latestFromStream,
    R Function(T t, S s) fn,
  ) {
    if (fn == null) {
      throw ArgumentError('Combiner cannot be null');
    }
    return WithLatestFromStreamTransformer<T, S, R>(
      [latestFromStream],
      (s, values) => fn(s, values[0]),
    );
  }

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from all [latestFromStream]s using the provided function [fn].
  static WithLatestFromStreamTransformer<T, dynamic, R> with2<T, A, B, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    R Function(T t, A a, B b) fn,
  ) {
    if (fn == null) {
      throw ArgumentError('Combiner cannot be null');
    }
    return WithLatestFromStreamTransformer<T, dynamic, R>(
      [latestFromStream1, latestFromStream2],
      (s, values) => fn(s, values[0] as A, values[1] as B),
    );
  }

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from all [latestFromStream]s using the provided function [fn].
  static WithLatestFromStreamTransformer<T, dynamic, R> with3<T, A, B, C, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    R Function(T t, A a, B b, C c) fn,
  ) {
    if (fn == null) {
      throw ArgumentError('Combiner cannot be null');
    }
    return WithLatestFromStreamTransformer<T, dynamic, R>(
      [
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
      ],
      (s, values) {
        return fn(
          s,
          values[0] as A,
          values[1] as B,
          values[2] as C,
        );
      },
    );
  }

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from all [latestFromStream]s using the provided function [fn].
  static WithLatestFromStreamTransformer<T, dynamic, R> with4<T, A, B, C, D, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    R Function(T t, A a, B b, C c, D d) fn,
  ) {
    if (fn == null) {
      throw ArgumentError('Combiner cannot be null');
    }
    return WithLatestFromStreamTransformer<T, dynamic, R>(
      [
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
      ],
      (s, values) {
        return fn(
          s,
          values[0] as A,
          values[1] as B,
          values[2] as C,
          values[3] as D,
        );
      },
    );
  }

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from all [latestFromStream]s using the provided function [fn].
  static WithLatestFromStreamTransformer<T, dynamic, R>
      with5<T, A, B, C, D, E, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    R Function(T t, A a, B b, C c, D d, E e) fn,
  ) {
    if (fn == null) {
      throw ArgumentError('Combiner cannot be null');
    }
    return WithLatestFromStreamTransformer<T, dynamic, R>(
      [
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
      ],
      (s, values) {
        return fn(
          s,
          values[0] as A,
          values[1] as B,
          values[2] as C,
          values[3] as D,
          values[4] as E,
        );
      },
    );
  }

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from all [latestFromStream]s using the provided function [fn].
  static WithLatestFromStreamTransformer<T, dynamic, R>
      with6<T, A, B, C, D, E, F, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    Stream<F> latestFromStream6,
    R Function(T t, A a, B b, C c, D d, E e, F f) fn,
  ) {
    if (fn == null) {
      throw ArgumentError('Combiner cannot be null');
    }
    return WithLatestFromStreamTransformer<T, dynamic, R>(
      [
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
        latestFromStream6,
      ],
      (s, values) {
        return fn(
          s,
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

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from all [latestFromStream]s using the provided function [fn].
  static WithLatestFromStreamTransformer<T, dynamic, R>
      with7<T, A, B, C, D, E, F, G, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    Stream<F> latestFromStream6,
    Stream<G> latestFromStream7,
    R Function(T t, A a, B b, C c, D d, E e, F f, G g) fn,
  ) {
    if (fn == null) {
      throw ArgumentError('Combiner cannot be null');
    }
    return WithLatestFromStreamTransformer<T, dynamic, R>(
      [
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
        latestFromStream6,
        latestFromStream7,
      ],
      (s, values) {
        return fn(
          s,
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

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from all [latestFromStream]s using the provided function [fn].
  static WithLatestFromStreamTransformer<T, dynamic, R>
      with8<T, A, B, C, D, E, F, G, H, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    Stream<F> latestFromStream6,
    Stream<G> latestFromStream7,
    Stream<H> latestFromStream8,
    R Function(T t, A a, B b, C c, D d, E e, F f, G g, H h) fn,
  ) {
    if (fn == null) {
      throw ArgumentError('Combiner cannot be null');
    }
    return WithLatestFromStreamTransformer<T, dynamic, R>(
      [
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
        latestFromStream6,
        latestFromStream7,
        latestFromStream8,
      ],
      (s, values) {
        return fn(
          s,
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

  /// Constructs a [StreamTransformer] that emits when the source [Stream] emits, combining
  /// the latest values from all [latestFromStream]s using the provided function [fn].
  static WithLatestFromStreamTransformer<T, dynamic, R>
      with9<T, A, B, C, D, E, F, G, H, I, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    Stream<F> latestFromStream6,
    Stream<G> latestFromStream7,
    Stream<H> latestFromStream8,
    Stream<I> latestFromStream9,
    R Function(T t, A a, B b, C c, D d, E e, F f, G g, H h, I i) fn,
  ) {
    if (fn == null) {
      throw ArgumentError('Combiner cannot be null');
    }
    return WithLatestFromStreamTransformer<T, dynamic, R>(
      [
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
        latestFromStream6,
        latestFromStream7,
        latestFromStream8,
        latestFromStream9,
      ],
      (s, values) {
        return fn(
          s,
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

  @override
  Stream<R> bind(Stream<S> stream) => forwardStream(
        stream,
        _WithLatestFromStreamSink<S, T, R>(latestFromStreams, combiner),
      );
}

/// Extends the Stream class with the ability to merge the source Stream with
/// the last emitted item from another Stream.
extension WithLatestFromExtensions<T> on Stream<T> {
  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the two streams using the provided function.
  ///
  /// If the latestFromStream has not emitted any values, this stream will not
  /// emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2]).withLatestFrom(
  ///       Stream.fromIterable([2, 3]), (a, b) => a + b)
  ///       .listen(print); // prints 4 (due to the async nature of streams)
  Stream<R> withLatestFrom<S, R>(
          Stream<S> latestFromStream, R Function(T t, S s) fn) =>
      transform(WithLatestFromStreamTransformer.with1(latestFromStream, fn));

  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the streams into a list. This is helpful when you need
  /// to combine a dynamic number of Streams.
  ///
  /// If any of latestFromStreams has not emitted any values, this stream will
  /// not emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///     Stream.fromIterable([1, 2]).withLatestFromList(
  ///         [
  ///           Stream.fromIterable([2, 3]),
  ///           Stream.fromIterable([3, 4]),
  ///           Stream.fromIterable([4, 5]),
  ///           Stream.fromIterable([5, 6]),
  ///           Stream.fromIterable([6, 7]),
  ///         ],
  ///       ).listen(print); // print [2, 2, 3, 4, 5, 6] (due to the async nature of streams)
  ///
  Stream<List<T>> withLatestFromList(Iterable<Stream<T>> latestFromStreams) =>
      transform(WithLatestFromStreamTransformer.withList(latestFromStreams));

  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the three streams using the provided function.
  ///
  /// If any of latestFromStreams has not emitted any values, this stream will
  /// not emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2])
  ///       .withLatestFrom2(
  ///         Stream.fromIterable([2, 3]),
  ///         Stream.fromIterable([3, 4]),
  ///         (int a, int b, int c) => a + b + c,
  ///       )
  ///       .listen(print); // prints 7 (due to the async nature of streams)
  Stream<R> withLatestFrom2<A, B, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    R Function(T t, A a, B b) fn,
  ) =>
      transform(WithLatestFromStreamTransformer.with2(
        latestFromStream1,
        latestFromStream2,
        fn,
      ));

  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the four streams using the provided function.
  ///
  /// If any of latestFromStreams has not emitted any values, this stream will
  /// not emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2])
  ///       .withLatestFrom3(
  ///         Stream.fromIterable([2, 3]),
  ///         Stream.fromIterable([3, 4]),
  ///         Stream.fromIterable([4, 5]),
  ///         (int a, int b, int c, int d) => a + b + c + d,
  ///       )
  ///       .listen(print); // prints 11 (due to the async nature of streams)
  Stream<R> withLatestFrom3<A, B, C, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    R Function(T t, A a, B b, C c) fn,
  ) =>
      transform(WithLatestFromStreamTransformer.with3(
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        fn,
      ));

  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the five streams using the provided function.
  ///
  /// If any of latestFromStreams has not emitted any values, this stream will
  /// not emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2])
  ///       .withLatestFrom4(
  ///         Stream.fromIterable([2, 3]),
  ///         Stream.fromIterable([3, 4]),
  ///         Stream.fromIterable([4, 5]),
  ///         Stream.fromIterable([5, 6]),
  ///         (int a, int b, int c, int d, int e) => a + b + c + d + e,
  ///       )
  ///       .listen(print); // prints 16 (due to the async nature of streams)
  Stream<R> withLatestFrom4<A, B, C, D, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    R Function(T t, A a, B b, C c, D d) fn,
  ) =>
      transform(WithLatestFromStreamTransformer.with4(
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        fn,
      ));

  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the six streams using the provided function.
  ///
  /// If any of latestFromStreams has not emitted any values, this stream will
  /// not emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2])
  ///       .withLatestFrom5(
  ///         Stream.fromIterable([2, 3]),
  ///         Stream.fromIterable([3, 4]),
  ///         Stream.fromIterable([4, 5]),
  ///         Stream.fromIterable([5, 6]),
  ///         Stream.fromIterable([6, 7]),
  ///         (int a, int b, int c, int d, int e, int f) => a + b + c + d + e + f,
  ///       )
  ///       .listen(print); // prints 22 (due to the async nature of streams)
  Stream<R> withLatestFrom5<A, B, C, D, E, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    R Function(T t, A a, B b, C c, D d, E e) fn,
  ) =>
      transform(WithLatestFromStreamTransformer.with5(
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
        fn,
      ));

  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the seven streams using the provided function.
  ///
  /// If any of latestFromStreams has not emitted any values, this stream will
  /// not emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2])
  ///       .withLatestFrom6(
  ///         Stream.fromIterable([2, 3]),
  ///         Stream.fromIterable([3, 4]),
  ///         Stream.fromIterable([4, 5]),
  ///         Stream.fromIterable([5, 6]),
  ///         Stream.fromIterable([6, 7]),
  ///         Stream.fromIterable([7, 8]),
  ///         (int a, int b, int c, int d, int e, int f, int g) =>
  ///             a + b + c + d + e + f + g,
  ///       )
  ///       .listen(print); // prints 29 (due to the async nature of streams)
  Stream<R> withLatestFrom6<A, B, C, D, E, F, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    Stream<F> latestFromStream6,
    R Function(T t, A a, B b, C c, D d, E e, F f) fn,
  ) =>
      transform(WithLatestFromStreamTransformer.with6(
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
        latestFromStream6,
        fn,
      ));

  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the eight streams using the provided function.
  ///
  /// If any of latestFromStreams has not emitted any values, this stream will
  /// not emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2])
  ///       .withLatestFrom7(
  ///         Stream.fromIterable([2, 3]),
  ///         Stream.fromIterable([3, 4]),
  ///         Stream.fromIterable([4, 5]),
  ///         Stream.fromIterable([5, 6]),
  ///         Stream.fromIterable([6, 7]),
  ///         Stream.fromIterable([7, 8]),
  ///         Stream.fromIterable([8, 9]),
  ///         (int a, int b, int c, int d, int e, int f, int g, int h) =>
  ///             a + b + c + d + e + f + g + h,
  ///       )
  ///       .listen(print); // prints 37 (due to the async nature of streams)
  Stream<R> withLatestFrom7<A, B, C, D, E, F, G, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    Stream<F> latestFromStream6,
    Stream<G> latestFromStream7,
    R Function(T t, A a, B b, C c, D d, E e, F f, G g) fn,
  ) =>
      transform(WithLatestFromStreamTransformer.with7(
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
        latestFromStream6,
        latestFromStream7,
        fn,
      ));

  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the nine streams using the provided function.
  ///
  /// If any of latestFromStreams has not emitted any values, this stream will
  /// not emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2])
  ///       .withLatestFrom8(
  ///         Stream.fromIterable([2, 3]),
  ///         Stream.fromIterable([3, 4]),
  ///         Stream.fromIterable([4, 5]),
  ///         Stream.fromIterable([5, 6]),
  ///         Stream.fromIterable([6, 7]),
  ///         Stream.fromIterable([7, 8]),
  ///         Stream.fromIterable([8, 9]),
  ///         Stream.fromIterable([9, 10]),
  ///         (int a, int b, int c, int d, int e, int f, int g, int h, int i) =>
  ///             a + b + c + d + e + f + g + h + i,
  ///       )
  ///       .listen(print); // prints 46 (due to the async nature of streams)
  Stream<R> withLatestFrom8<A, B, C, D, E, F, G, H, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    Stream<F> latestFromStream6,
    Stream<G> latestFromStream7,
    Stream<H> latestFromStream8,
    R Function(T t, A a, B b, C c, D d, E e, F f, G g, H h) fn,
  ) =>
      transform(WithLatestFromStreamTransformer.with8(
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
        latestFromStream6,
        latestFromStream7,
        latestFromStream8,
        fn,
      ));

  /// Creates a Stream that emits when the source stream emits, combining the
  /// latest values from the ten streams using the provided function.
  ///
  /// If any of latestFromStreams has not emitted any values, this stream will
  /// not emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2])
  ///       .withLatestFrom9(
  ///         Stream.fromIterable([2, 3]),
  ///         Stream.fromIterable([3, 4]),
  ///         Stream.fromIterable([4, 5]),
  ///         Stream.fromIterable([5, 6]),
  ///         Stream.fromIterable([6, 7]),
  ///         Stream.fromIterable([7, 8]),
  ///         Stream.fromIterable([8, 9]),
  ///         Stream.fromIterable([9, 10]),
  ///         Stream.fromIterable([10, 11]),
  ///         (int a, int b, int c, int d, int e, int f, int g, int h, int i, int j) =>
  ///             a + b + c + d + e + f + g + h + i + j,
  ///       )
  ///       .listen(print); // prints 46 (due to the async nature of streams)
  Stream<R> withLatestFrom9<A, B, C, D, E, F, G, H, I, R>(
    Stream<A> latestFromStream1,
    Stream<B> latestFromStream2,
    Stream<C> latestFromStream3,
    Stream<D> latestFromStream4,
    Stream<E> latestFromStream5,
    Stream<F> latestFromStream6,
    Stream<G> latestFromStream7,
    Stream<H> latestFromStream8,
    Stream<I> latestFromStream9,
    R Function(T t, A a, B b, C c, D d, E e, F f, G g, H h, I i) fn,
  ) =>
      transform(WithLatestFromStreamTransformer.with9(
        latestFromStream1,
        latestFromStream2,
        latestFromStream3,
        latestFromStream4,
        latestFromStream5,
        latestFromStream6,
        latestFromStream7,
        latestFromStream8,
        latestFromStream9,
        fn,
      ));
}
