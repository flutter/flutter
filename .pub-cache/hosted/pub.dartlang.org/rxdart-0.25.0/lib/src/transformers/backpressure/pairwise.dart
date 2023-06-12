import 'package:rxdart/src/streams/never.dart';
import 'package:rxdart/src/transformers/backpressure/backpressure.dart';

/// Emits the n-th and n-1th events as a pair.
/// The first event won't be emitted until the second one arrives.
///
/// ### Example
///
///     Rx.range(1, 4)
///       .pairwise()
///       .listen(print); // prints [1, 2], [2, 3], [3, 4]
class PairwiseStreamTransformer<T>
    extends BackpressureStreamTransformer<T, Iterable<T>> {
  /// Constructs a [StreamTransformer] which buffers events into pairs as a [List].
  PairwiseStreamTransformer()
      : super(WindowStrategy.firstEventOnly, (_) => NeverStream<void>(),
            onWindowEnd: (Iterable<T> queue) => queue,
            startBufferEvery: 1,
            closeWindowWhen: (Iterable<T> queue) => queue.length == 2,
            dispatchOnClose: false);
}

/// Extends the Stream class with the ability to emit the nth and n-1th events
/// as a pair
extension PairwiseExtension<T> on Stream<T> {
  /// Emits the n-th and n-1th events as a pair.
  /// The first event won't be emitted until the second one arrives.
  ///
  /// ### Example
  ///
  ///     RangeStream(1, 4)
  ///       .pairwise()
  ///       .listen(print); // prints [1, 2], [2, 3], [3, 4]
  Stream<Iterable<T>> pairwise() => transform(PairwiseStreamTransformer());
}
