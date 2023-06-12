import 'dart:async';
import 'dart:collection';

class _DistinctUniqueStreamSink<S> implements EventSink<S> {
  final EventSink<S> _outputSink;
  final HashSet<S> _collection;

  _DistinctUniqueStreamSink(this._outputSink,
      {bool Function(S e1, S e2) equals, int Function(S e) hashCodeMethod})
      : _collection = HashSet<S>(equals: equals, hashCode: hashCodeMethod);

  @override
  void add(S data) {
    if (_collection.add(data)) {
      _outputSink.add(data);
    }
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() {
    _collection.clear();
    _outputSink.close();
  }
}

/// Create a [Stream] which implements a [HashSet] under the hood, using
/// the provided `equals` as equality.
///
/// The [Stream] will only emit an event, if that event is not yet found
/// within the underlying [HashSet].
///
/// ###  Example
///
///     Stream.fromIterable([1, 2, 1, 2, 1, 2, 3, 2, 1])
///         .listen((event) => print(event));
///
/// will emit:
///     1, 2, 3
///
/// The provided `equals` must define a stable equivalence relation, and
/// `hashCode` must be consistent with `equals`.
///
/// If `equals` or `hashCode` are omitted, the set uses the elements' intrinsic
/// `Object.==` and `Object.hashCode`. If you supply one of `equals` and
/// `hashCode`, you should generally also to supply the other.
class DistinctUniqueStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// Optional method which determines equality between two events
  final bool Function(S e1, S e2) equals;

  /// Optional method which is used to create a hash from an event
  final int Function(S e) hashCodeMethod;

  /// Constructs a [StreamTransformer] which emits events from the source
  /// [Stream] as if they were processed through a [HashSet].
  ///
  /// See [HashSet] for a more detailed explanation.
  DistinctUniqueStreamTransformer({this.equals, this.hashCodeMethod});

  @override
  Stream<S> bind(Stream<S> stream) => Stream.eventTransformed(
      stream,
      (sink) => _DistinctUniqueStreamSink<S>(sink,
          equals: equals, hashCodeMethod: hashCodeMethod));
}

/// Extends the Stream class with the ability to skip items that have previously
/// been emitted.
extension DistinctUniqueExtension<T> on Stream<T> {
  /// WARNING: More commonly known as distinct in other Rx implementations.
  /// Creates a Stream where data events are skipped if they have already
  /// been emitted before.
  ///
  /// Equality is determined by the provided equals and hashCode methods.
  /// If these are omitted, the '==' operator and hashCode on the last provided
  /// data element are used.
  ///
  /// The returned stream is a broadcast stream if this stream is. If a
  /// broadcast stream is listened to more than once, each subscription will
  /// individually perform the equals and hashCode tests.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#distinct)
  Stream<T> distinctUnique({
    bool Function(T e1, T e2) equals,
    int Function(T e) hashCode,
  }) =>
      transform(DistinctUniqueStreamTransformer<T>(
          equals: equals, hashCodeMethod: hashCode));
}
