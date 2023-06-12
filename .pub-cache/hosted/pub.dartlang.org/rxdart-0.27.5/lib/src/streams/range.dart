import 'dart:async';

/// Returns a Stream that emits a sequence of Integers within a specified
/// range.
///
/// ### Examples
///
///     RangeStream(1, 3).listen((i) => print(i)); // Prints 1, 2, 3
///
///     RangeStream(3, 1).listen((i) => print(i)); // Prints 3, 2, 1
class RangeStream extends Stream<int> {
  final Stream<int> _stream;

  /// Constructs a [Stream] which emits all integer values that exist
  /// within the range between [startInclusive] and [endInclusive].
  RangeStream(int startInclusive, int endInclusive)
      : _stream = _buildStream(startInclusive, endInclusive);

  @override
  StreamSubscription<int> listen(void Function(int event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  static Stream<int> _buildStream(int startInclusive, int endInclusive) {
    final length = (endInclusive - startInclusive).abs() + 1;
    int nextValue(int index) => startInclusive > endInclusive
        ? startInclusive - index
        : startInclusive + index;

    return Stream.fromIterable(Iterable.generate(length, nextValue));
  }
}
