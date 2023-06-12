import 'dart:async';

/// Explicitly ignores a future.
///
/// Not all futures need to be awaited.
/// The Dart linter has an optional ["unawaited futures" lint](https://dart-lang.github.io/linter/lints/unawaited_futures.html)
/// which enforces that futures (expressions with a static type of [Future])
/// in asynchronous functions are handled *somehow*.
/// If a particular future value doesn't need to be awaited,
/// you can call `unawaited(...)` with it, which will avoid the lint,
/// simply because the expression no longer has type [Future].
/// Using `unawaited` has no other effect.
/// You should use `unawaited` to convey the *intention* of
/// deliberately not waiting for the future.
///
/// If the future completes with an error,
/// it was likely a mistake to not await it.
/// That error will still occur and will be considered unhandled
/// unless the same future is awaited (or otherwise handled) elsewhere too.
/// Because of that, `unawaited` should only be used for futures that
/// are *expected* to complete with a value.
void unawaited(Future<void> future) {}

void nullableTest<R>(Stream<R> Function(Stream<String?> s) transform) =>
    transform(Stream<String>.fromIterable(['1', '2', '3']));
