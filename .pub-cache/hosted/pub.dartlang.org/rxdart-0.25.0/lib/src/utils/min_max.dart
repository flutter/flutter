import 'dart:async';

/// @private
/// Helper method which find max value or min value in a stream
///
/// When the stream is done, the returned future is completed with
/// the largest value or smallest value at that time.
///
/// If the stream is empty, the returned future is completed with
/// an error.
/// If the stream emits an error, or the call to [comparator] throws,
/// the returned future is completed with that error,
/// and processing is stopped.
Future<T> minMax<T>(Stream<T> stream, bool findMin, Comparator<T> comparator) {
  var completer = Completer<T>();
  var seenFirst = false;
  StreamSubscription<T> subscription;
  T accumulator;

  final cancelAndCompleteError = (dynamic e, StackTrace st) async {
    final cancelFuture = subscription.cancel();
    if (cancelFuture != null) {
      await cancelFuture;
    }
    completer.completeError(e, st);
  };

  final onData = (T element) async {
    if (seenFirst) {
      try {
        accumulator = findMin
            ? (comparator(element, accumulator) < 0 ? element : accumulator)
            : (comparator(element, accumulator) > 0 ? element : accumulator);
      } catch (e, st) {
        await cancelAndCompleteError(e, st);
      }
      return;
    }

    accumulator = element;
    seenFirst = true;
    try {
      comparator ??= () {
        if (element is Comparable) {
          return Comparable.compare as Comparator<T>;
        } else {
          throw StateError(
              'Please provide a comparator for type $T, because it is not comparable');
        }
      }();
    } catch (e, st) {
      await cancelAndCompleteError(e, st);
    }
  };
  final onDone = () {
    if (seenFirst) {
      completer.complete(accumulator);
    } else {
      completer.completeError(StateError('No element'));
    }
  };

  subscription = stream.listen(
    onData,
    onError: completer.completeError,
    onDone: onDone,
    cancelOnError: true,
  );
  return completer.future;
}
