import 'handler.dart';
import 'middleware.dart';

/// Extensions on [Middleware] to aid in composing [Middleware] and [Handler]s.
///
/// These members can be used in place of [Pipeline].
extension MiddlewareExtensions on Middleware {
  /// Merges `this` and [other] into a new [Middleware].
  Middleware addMiddleware(Middleware other) =>
      (Handler handler) => this(other(handler));

  /// Merges `this` and [handler] into a new [Handler].
  Handler addHandler(Handler handler) => this(handler);
}
