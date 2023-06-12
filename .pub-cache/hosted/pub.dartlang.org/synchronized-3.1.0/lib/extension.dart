import 'dart:async';

import 'package:synchronized/src/extension_impl.dart' as impl;

/// Add lock ability to any object.
///
/// Then you can simple call on any object.
///
/// ```dart
/// myObject.synchronized(() async {
///   // ...uninterrupted action
/// });
///
/// class MyClass {
///   /// Perform a long action that won't be called more than once at a time.
///   Future<void> performAction() {
///     // Lock at the instance level
///     return synchronized(() async {
///       // ...uninterrupted action
///     });
///   }
/// }
/// ```
/// Or you can synchronize at the class level
///
/// ```dart
/// class MyClass {
///   /// Perform a long action that won't be called more than once at a time.
///   Future<void> performClassAction() {
///     // Lock at the class level
///     return runtimeType.synchronized(() async {
///       // ...uninterrupted action
///     });
///   }
/// }
/// ```
///
/// The lock mechanism is based on identity so beware of potential conflicts (for
/// example using String object).
///
extension SynchronizedLock on Object {
  /// Executes [computation] when lock is available.
  ///
  /// Only one asynchronous block can run while the lock is retained.
  Future<T> synchronized<T>(FutureOr<T> Function() computation,
      {Duration? timeout}) {
    return impl.objectSynchronized<T>(this, computation, timeout: timeout);
  }
}
