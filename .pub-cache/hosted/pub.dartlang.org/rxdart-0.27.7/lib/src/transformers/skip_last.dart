import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _SkipLastStreamSink<T> extends ForwardingSink<T, T> {
  _SkipLastStreamSink(this.count);

  final int count;
  final List<T> queue = <T>[];

  @override
  void onData(T data) {
    queue.add(data);
  }

  @override
  void onError(Object e, StackTrace st) => sink.addError(e, st);

  @override
  void onDone() {
    final limit = queue.length - count;
    if (limit > 0) {
      queue.sublist(0, limit).forEach(sink.add);
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

/// Skip the last [count] items emitted by the source [Stream]
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3, 4, 5])
///       .transform(SkipLastStreamTransformer(3))
///       .listen(print); // prints 1, 2
class SkipLastStreamTransformer<T> extends StreamTransformerBase<T, T> {
  /// Constructs a [StreamTransformer] which skip the last [count] items
  /// emitted by the source [Stream]
  SkipLastStreamTransformer(this.count) {
    if (count < 0) throw ArgumentError.value(count, 'count');
  }

  /// The [count] of final items to skip.
  final int count;

  @override
  Stream<T> bind(Stream<T> stream) =>
      forwardStream(stream, () => _SkipLastStreamSink(count));
}

/// Extends the Stream class with the ability to skip the last [count] items
/// emitted by the source [Stream]
extension SkipLastExtension<T> on Stream<T> {
  /// Starts emitting every items except last [count] items.
  /// This causes items to be delayed.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3, 4, 5])
  ///       .skipLast(3)
  ///       .listen(print); // prints 1, 2
  Stream<T> skipLast(int count) =>
      SkipLastStreamTransformer<T>(count).bind(this);
}
