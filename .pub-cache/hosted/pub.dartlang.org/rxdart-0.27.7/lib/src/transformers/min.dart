import 'dart:async';

import 'package:rxdart/src/utils/min_max.dart';

/// Extends the Stream class with the ability to transform into a Future
/// that completes with the smallest item emitted by the Stream.
extension MinExtension<T> on Stream<T> {
  /// Converts a Stream into a Future that completes with the smallest item
  /// emitted by the Stream.
  ///
  /// This is similar to finding the min value in a list, but the values are
  /// asynchronous!
  ///
  /// ### Example
  ///
  ///     final min = await Stream.fromIterable([1, 2, 3]).min();
  ///
  ///     print(min); // prints 1
  ///
  /// ### Example with custom [Comparator]
  ///
  ///     final stream = Stream.fromIterable(['short', 'looooooong']);
  ///     final min = await stream.min((a, b) => a.length - b.length);
  ///
  ///     print(min); // prints 'short'
  Future<T> min([Comparator<T>? comparator]) => minMax(this, true, comparator);
}
