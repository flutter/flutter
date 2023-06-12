import 'dart:async';

import 'package:rxdart/src/transformers/backpressure/backpressure.dart';

/// Creates a [Stream] where each item is a [Stream] containing the items
/// from the source sequence.
///
/// This [List] is emitted every time the window [Stream]
/// emits an event.
///
/// ### Example
///
///     Stream.periodic(const Duration(milliseconds: 100), (i) => i)
///       .window(Stream.periodic(const Duration(milliseconds: 160), (i) => i))
///       .asyncMap((stream) => stream.toList())
///       .listen(print); // prints [0, 1] [2, 3] [4, 5] ...
class WindowStreamTransformer<T>
    extends BackpressureStreamTransformer<T, Stream<T>> {
  /// Constructs a [StreamTransformer] which buffers events into a [Stream] and
  /// emits this [Stream] whenever [window] fires an event.
  ///
  /// The [Stream] is recreated and starts empty upon every [window] event.
  WindowStreamTransformer(Stream Function(T event) window)
      : super(WindowStrategy.firstEventOnly, window,
            onWindowEnd: (List<T> queue) => Stream.fromIterable(queue),
            ignoreEmptyWindows: false) {
    if (window == null) throw ArgumentError.notNull('window');
  }
}

/// Buffers a number of values from the source Stream by count then emits the
/// buffer as a [Stream] and clears it, and starts a new buffer each
/// startBufferEvery values. If startBufferEvery is not provided, then new
/// buffers are started immediately at the start of the source and when each
/// buffer closes and is emitted.
///
/// ### Example
/// count is the maximum size of the buffer emitted
///
///     Rx.range(1, 4)
///       .windowCount(2)
///       .asyncMap((stream) => stream.toList())
///       .listen(print); // prints [1, 2], [3, 4] done!
///
/// ### Example
/// if startBufferEvery is 2, then a new buffer will be started
/// on every other value from the source. A new buffer is started at the
/// beginning of the source by default.
///
///     Rx.range(1, 5)
///       .bufferCount(3, 2)
///       .listen(print); // prints [1, 2, 3], [3, 4, 5], [5] done!
class WindowCountStreamTransformer<T>
    extends BackpressureStreamTransformer<T, Stream<T>> {
  /// Constructs a [StreamTransformer] which buffers events into a [Stream] and
  /// emits this [Stream] whenever its length is equal to [count].
  ///
  /// A new buffer is created for every n-th event emitted
  /// by the [Stream] that is being transformed, as specified by
  /// the [startBufferEvery] parameter.
  ///
  /// If [startBufferEvery] is omitted or equals 0, then a new buffer is started whenever
  /// the previous one reaches a length of [count].
  WindowCountStreamTransformer(int count, [int startBufferEvery = 0])
      : super(WindowStrategy.onHandler, null,
            onWindowEnd: (List<T> queue) => Stream.fromIterable(queue),
            startBufferEvery: startBufferEvery,
            closeWindowWhen: (Iterable<T> queue) => queue.length == count) {
    if (count == null) throw ArgumentError.notNull('count');
    if (startBufferEvery == null) {
      throw ArgumentError.notNull('startBufferEvery');
    }
    if (count < 1) throw ArgumentError.value(count, 'count');
    if (startBufferEvery < 0) {
      throw ArgumentError.value(startBufferEvery, 'startBufferEvery');
    }
  }
}

/// Creates a [Stream] where each item is a [Stream] containing the items
/// from the source sequence, batched whenever test passes.
///
/// ### Example
///
///     Stream.periodic(const Duration(milliseconds: 100), (int i) => i)
///       .windowTest((i) => i % 2 == 0)
///       .asyncMap((stream) => stream.toList())
///       .listen(print); // prints [0], [1, 2] [3, 4] [5, 6] ...
class WindowTestStreamTransformer<T>
    extends BackpressureStreamTransformer<T, Stream<T>> {
  /// Constructs a [StreamTransformer] which buffers events into a [Stream] and
  /// emits this [Stream] whenever the [test] Function yields true.
  WindowTestStreamTransformer(bool Function(T value) test)
      : super(WindowStrategy.onHandler, null,
            onWindowEnd: (List<T> queue) => Stream.fromIterable(queue),
            closeWindowWhen: (Iterable<T> queue) => test(queue.last)) {
    if (test == null) throw ArgumentError.notNull('test');
  }
}

/// Extends the Stream class with the ability to window
extension WindowExtensions<T> on Stream<T> {
  /// Creates a Stream where each item is a [Stream] containing the items from
  /// the source sequence.
  ///
  /// This [List] is emitted every time [window] emits an event.
  ///
  /// ### Example
  ///
  ///     Stream.periodic(Duration(milliseconds: 100), (i) => i)
  ///       .window(Stream.periodic(Duration(milliseconds: 160), (i) => i))
  ///       .asyncMap((stream) => stream.toList())
  ///       .listen(print); // prints [0, 1] [2, 3] [4, 5] ...
  Stream<Stream<T>> window(Stream window) =>
      transform(WindowStreamTransformer((_) => window));

  /// Buffers a number of values from the source Stream by [count] then emits
  /// the buffer as a [Stream] and clears it, and starts a new buffer each
  /// [startBufferEvery] values. If [startBufferEvery] is not provided, then new
  /// buffers are started immediately at the start of the source and when each
  /// buffer closes and is emitted.
  ///
  /// ### Example
  /// [count] is the maximum size of the buffer emitted
  ///
  ///     RangeStream(1, 4)
  ///       .windowCount(2)
  ///       .asyncMap((stream) => stream.toList())
  ///       .listen(print); // prints [1, 2], [3, 4] done!
  ///
  /// ### Example
  /// if [startBufferEvery] is 2, then a new buffer will be started
  /// on every other value from the source. A new buffer is started at the
  /// beginning of the source by default.
  ///
  ///     RangeStream(1, 5)
  ///       .bufferCount(3, 2)
  ///       .listen(print); // prints [1, 2, 3], [3, 4, 5], [5] done!
  Stream<Stream<T>> windowCount(int count, [int startBufferEvery = 0]) =>
      transform(WindowCountStreamTransformer(count, startBufferEvery));

  /// Creates a Stream where each item is a [Stream] containing the items from
  /// the source sequence, batched whenever test passes.
  ///
  /// ### Example
  ///
  ///     Stream.periodic(Duration(milliseconds: 100), (int i) => i)
  ///       .windowTest((i) => i % 2 == 0)
  ///       .asyncMap((stream) => stream.toList())
  ///       .listen(print); // prints [0], [1, 2] [3, 4] [5, 6] ...
  Stream<Stream<T>> windowTest(bool Function(T event) onTestHandler) =>
      transform(WindowTestStreamTransformer(onTestHandler));

  /// Creates a Stream where each item is a [Stream] containing the items from
  /// the source sequence, sampled on a time frame with [duration].
  ///
  /// ### Example
  ///
  ///     Stream.periodic(Duration(milliseconds: 100), (int i) => i)
  ///       .windowTime(Duration(milliseconds: 220))
  ///       .doOnData((_) => print('next window'))
  ///       .flatMap((s) => s)
  ///       .listen(print); // prints next window 0, 1, next window 2, 3, ...
  Stream<Stream<T>> windowTime(Duration duration) {
    if (duration == null) throw ArgumentError.notNull('duration');

    return window(Stream<void>.periodic(duration));
  }
}
