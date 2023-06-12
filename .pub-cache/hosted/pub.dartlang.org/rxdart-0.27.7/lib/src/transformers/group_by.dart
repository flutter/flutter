import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';
import 'package:rxdart/src/utils/future.dart';
import 'package:rxdart/src/utils/subscription.dart';

class _GroupByStreamSink<T, K> extends ForwardingSink<T, GroupedStream<T, K>> {
  final K Function(T event) grouper;
  final Stream<void> Function(GroupedStream<T, K>)? duration;

  final groups = <K, StreamController<T>>{};
  Map<K, StreamSubscription<void>>? subscriptions;

  _GroupByStreamSink(this.grouper, this.duration);

  void _closeAll() {
    for (var c in groups.values) {
      c.close();
    }
    groups.clear();
  }

  StreamController<T> _controllerBuilder(K key) {
    final groupedController = StreamController<T>.broadcast(sync: true);
    final groupByStream = GroupedStream<T, K>(key, groupedController.stream);

    if (duration != null) {
      subscriptions?.remove(key)?.cancel();
      (subscriptions ??= {})[key] = duration!(groupByStream).take(1).listen(
        null,
        onDone: () {
          subscriptions!.remove(key);
          groups.remove(key)?.close();
        },
        onError: onError,
      );
    }

    sink.add(groupByStream);
    return groupedController;
  }

  @override
  void onData(T data) {
    final K key;
    try {
      key = grouper(data);
    } catch (e, s) {
      sink.addError(e, s);
      return;
    }

    groups.putIfAbsent(key, () => _controllerBuilder(key)).add(data);
  }

  @override
  void onError(e, st) => sink.addError(e, st);

  @override
  void onDone() {
    _closeAll();
    sink.close();
  }

  @override
  Future<void>? onCancel() {
    scheduleMicrotask(_closeAll);

    if (subscriptions?.isNotEmpty == true) {
      final future = waitFuturesList([
        for (final s in subscriptions!.values) s.cancel(),
      ]);
      subscriptions?.clear();
      subscriptions = null;
      return future;
    }
    return null;
  }

  @override
  FutureOr<void> onListen() {}

  @override
  void onPause() => subscriptions?.values.pauseAll();

  @override
  void onResume() => subscriptions?.values.resumeAll();
}

/// The GroupBy operator divides a [Stream] that emits items into
/// a [Stream] that emits [GroupedStream],
/// each one of which emits some subset of the items
/// from the original source [Stream].
///
/// [GroupedStream] acts like a regular [Stream], yet
/// adding a 'key' property, which receives its [Type] and value from
/// the [_grouper] Function.
///
/// All items with the same key are emitted by the same [GroupedStream].
class GroupByStreamTransformer<T, K>
    extends StreamTransformerBase<T, GroupedStream<T, K>> {
  /// Method which converts incoming events into a new [GroupedStream]
  final K Function(T event) grouper;

  /// A function that returns an [Stream] to determine how long each group should exist.
  /// When the returned [Stream] emits its first data or done event,
  /// the group will be closed and removed.
  final Stream<void> Function(GroupedStream<T, K> grouped)? durationSelector;

  /// Constructs a [StreamTransformer] which groups events from the source
  /// [Stream] and emits them as [GroupedStream].
  GroupByStreamTransformer(this.grouper, {this.durationSelector});

  @override
  Stream<GroupedStream<T, K>> bind(Stream<T> stream) => forwardStream(
      stream, () => _GroupByStreamSink<T, K>(grouper, durationSelector));
}

/// The [Stream] used by [GroupByStreamTransformer], it contains events
/// that are grouped by a key value.
class GroupedStream<T, K> extends StreamView<T> {
  /// The key is the category to which all events in this group belong to.
  final K key;

  /// Constructs a [Stream] which only emits events that can be
  /// categorized under [key].
  GroupedStream(this.key, Stream<T> stream) : super(stream);

  @override
  String toString() => 'GroupedStream{key: $key}';
}

/// Extends the Stream class with the ability to convert events into Streams
/// of events that are united by a key.
extension GroupByExtension<T> on Stream<T> {
  /// The GroupBy operator divides a [Stream] that emits items into a [Stream]
  /// that emits [GroupedStream], each one of which emits some subset of the
  /// items from the original source [Stream].
  ///
  /// [GroupedStream] acts like a regular [Stream], yet adding a 'key' property,
  /// which receives its [Type] and value from the [grouper] Function.
  ///
  /// All items with the same key are emitted by the same [GroupedStream].
  ///
  /// Optionally, `groupBy` takes a second argument [durationSelector].
  /// [durationSelector] is a function that returns an [Stream] to determine how long
  /// each group should exist. When the returned [Stream] emits its first data or done event,
  /// the group will be closed and removed.
  Stream<GroupedStream<T, K>> groupBy<K>(
    K Function(T value) grouper, {
    Stream<void> Function(GroupedStream<T, K> grouped)? durationSelector,
  }) =>
      GroupByStreamTransformer<T, K>(grouper,
              durationSelector: durationSelector)
          .bind(this);
}
