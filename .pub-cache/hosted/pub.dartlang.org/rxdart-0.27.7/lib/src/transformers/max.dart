import 'package:rxdart/src/utils/min_max.dart';

/// Extends the Stream class with the ability to transform into a Future
/// that completes with the largest item emitted by the Stream.
extension MaxExtension<T> on Stream<T> {
  /// Converts a Stream into a Future that completes with the largest item
  /// emitted by the Stream.
  ///
  /// This is similar to finding the max value in a list, but the values are
  /// asynchronous.
  ///
  /// ### Example
  ///
  ///     final max = await Stream.fromIterable([1, 2, 3]).max();
  ///
  ///     print(max); // prints 3
  ///
  /// ### Example with custom [Comparator]
  ///
  ///     final stream = Stream.fromIterable(['short', 'looooooong']);
  ///     final max = await stream.max((a, b) => a.length - b.length);
  ///
  ///     print(max); // prints 'looooooong'
  Future<T> max([Comparator<T>? comparator]) => minMax(this, false, comparator);
}
