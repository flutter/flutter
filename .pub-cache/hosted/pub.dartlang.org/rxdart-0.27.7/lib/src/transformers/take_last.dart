import 'dart:async';
import 'dart:collection';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _TakeLastStreamSink<T> extends ForwardingSink<T, T> {
  _TakeLastStreamSink(this.count);

  final int count;
  final Queue<T> queue = DoubleLinkedQueue<T>();

  @override
  void onData(T data) {
    if (count > 0) {
      queue.addLast(data);
      if (queue.length > count) {
        queue.removeFirst();
      }
    }
  }

  @override
  void onError(Object e, StackTrace st) => sink.addError(e, st);

  @override
  void onDone() {
    if (queue.isNotEmpty) {
      queue.toList(growable: false).forEach(sink.add);
    }
    sink.close();
  }

  @override
  FutureOr<void> onCancel() {
    queue.clear();
  }

  @override
  void onListen() {}

  @override
  void onPause() {}

  @override
  void onResume() {}
}

/// Emits only the final [count] values emitted by the source [Stream].
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3, 4, 5])
///       .transform(TakeLastStreamTransformer(3))
///       .listen(print); // prints 3, 4, 5
class TakeLastStreamTransformer<T> extends StreamTransformerBase<T, T> {
  /// Constructs a [StreamTransformer] which emits only the final [count]
  /// events from the source [Stream].
  TakeLastStreamTransformer(this.count) {
    if (count < 0) throw ArgumentError.value(count, 'count');
  }

  /// The [count] of final items emitted when the stream completes.
  final int count;

  @override
  Stream<T> bind(Stream<T> stream) =>
      forwardStream(stream, () => _TakeLastStreamSink<T>(count));
}

/// Extends the [Stream] class with the ability receive only the final [count]
/// events from the source [Stream].
extension TakeLastExtension<T> on Stream<T> {
  /// Emits only the final [count] values emitted by the source [Stream].
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3, 4, 5])
  ///       .takeLast(3)
  ///       .listen(print); // prints 3, 4, 5
  Stream<T> takeLast(int count) =>
      TakeLastStreamTransformer<T>(count).bind(this);
}
