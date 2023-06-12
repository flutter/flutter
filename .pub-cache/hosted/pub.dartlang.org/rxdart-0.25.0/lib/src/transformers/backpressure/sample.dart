import 'dart:async';

import 'package:rxdart/src/transformers/backpressure/backpressure.dart';

/// A [StreamTransformer] that, when the specified window [Stream] emits
/// an item or completes, emits the most recently emitted item (if any)
/// emitted by the source [Stream] since the previous emission from
/// the sample [Stream].
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3])
///       .transform(SampleStreamTransformer(TimerStream(1, const Duration(seconds: 1)))
///       .listen(print); // prints 3
class SampleStreamTransformer<T> extends BackpressureStreamTransformer<T, T> {
  /// Constructs a [StreamTransformer] that, when the specified [window] emits
  /// an item or completes, emits the most recently emitted item (if any)
  /// emitted by the source [Stream] since the previous emission from
  /// the sample [Stream].
  SampleStreamTransformer(Stream Function(T event) window)
      : super(WindowStrategy.firstEventOnly, window,
            onWindowEnd: (Iterable<T> queue) => queue.last) {
    assert(window != null, 'window stream factory cannot be null');
  }
}

/// Extends the Stream class with the ability to sample events from the Stream
extension SampleExtensions<T> on Stream<T> {
  /// Emits the most recently emitted item (if any)
  /// emitted by the source [Stream] since the previous emission from
  /// the [sampleStream].
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3])
  ///       .sample(TimerStream(1, Duration(seconds: 1)))
  ///       .listen(print); // prints 3
  Stream<T> sample(Stream<dynamic> sampleStream) =>
      transform(SampleStreamTransformer<T>((_) => sampleStream));

  /// Emits the most recently emitted item (if any) emitted by the source
  /// [Stream] since the previous emission within the recurring time span,
  /// defined by [duration]
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3])
  ///       .sampleTime(Duration(seconds: 1))
  ///       .listen(print); // prints 3
  Stream<T> sampleTime(Duration duration) =>
      sample(Stream<void>.periodic(duration));
}
