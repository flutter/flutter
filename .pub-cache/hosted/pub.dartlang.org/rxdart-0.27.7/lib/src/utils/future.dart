import 'dart:async';

/// @internal
/// An optimized version of [Future.wait].
FutureOr<void> waitTwoFutures(Future<void>? f1, FutureOr<void> f2) => f1 == null
    ? f2
    : f2 is Future<void>
        ? Future.wait([f1, f2]).then(_ignore)
        : f1;

/// @internal
/// An optimized version of [Future.wait].
Future<void>? waitFuturesList(List<Future<void>> futures) {
  switch (futures.length) {
    case 0:
      return null;
    case 1:
      return futures[0];
    default:
      return Future.wait(futures).then(_ignore);
  }
}

/// Helper function to ignore future callback
void _ignore(Object? _) {}
