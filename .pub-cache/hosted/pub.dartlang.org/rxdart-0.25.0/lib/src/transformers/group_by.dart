import 'dart:async';

class _GroupByStreamSink<S, T> implements EventSink<S> {
  final T Function(S event) _grouper;
  final EventSink<GroupByStream<S, T>> _outputSink;
  final _mapper = <T, StreamController<S>>{};

  _GroupByStreamSink(this._outputSink, this._grouper);

  @override
  void add(S data) {
    final key = _grouper(data);

    final groupedController =
        _mapper.putIfAbsent(key, () => _controllerBuilder(key));

    groupedController.add(data);
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() {
    _mapper.values.forEach((c) => c.close());
    _mapper.clear();

    _outputSink.close();
  }

  StreamController<S> _controllerBuilder(T forKey) {
    final groupedController = StreamController<S>();

    _outputSink.add(GroupByStream<S, T>(forKey, groupedController.stream));

    return groupedController;
  }
}

/// The GroupBy operator divides a [Stream] that emits items into
/// a [Stream] that emits [GroupByStream],
/// each one of which emits some subset of the items
/// from the original source [Stream].
///
/// [GroupByStream] acts like a regular [Stream], yet
/// adding a 'key' property, which receives its [Type] and value from
/// the [_grouper] Function.
///
/// All items with the same key are emitted by the same [GroupByStream].
class GroupByStreamTransformer<S, T>
    extends StreamTransformerBase<S, GroupByStream<S, T>> {
  /// Method which converts incoming events into a new [GroupByStream]
  final T Function(S event) grouper;

  /// Constructs a [StreamTransformer] which groups events from the source
  /// [Stream] and emits them as [GroupByStream].
  GroupByStreamTransformer(this.grouper);

  @override
  Stream<GroupByStream<S, T>> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _GroupByStreamSink<S, T>(sink, grouper));
}

/// The [Stream] used by [GroupByStreamTransformer], it contains events
/// that are grouped by a key value.
class GroupByStream<T, S> extends StreamView<T> {
  /// The key is the category to which all events in this group belong to.
  final S key;

  /// Constructs a [Stream] which only emits events that can be
  /// categorized under [key].
  GroupByStream(this.key, Stream<T> stream) : super(stream);
}

/// Extends the Stream class with the ability to convert events into Streams
/// of events that are united by a key.
extension GroupByExtension<T> on Stream<T> {
  /// The GroupBy operator divides a [Stream] that emits items into a [Stream]
  /// that emits [GroupByStream], each one of which emits some subset of the
  /// items from the original source [Stream].
  ///
  /// [GroupByStream] acts like a regular [Stream], yet adding a 'key' property,
  /// which receives its [Type] and value from the [grouper] Function.
  ///
  /// All items with the same key are emitted by the same [GroupByStream].
  Stream<GroupByStream<T, S>> groupBy<S>(S Function(T value) grouper) =>
      transform(GroupByStreamTransformer<T, S>(grouper));
}
