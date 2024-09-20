// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
@pragma("vm:entry-point")
abstract class Finalizer<T> {
  @patch
  factory Finalizer(void Function(T) callback) = _FinalizerImpl<T>;
}

@pragma("vm:entry-point")
class _FinalizerImpl<T> extends FinalizerBase implements Finalizer<T> {
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external void Function(T) get _callback;
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external set _callback(void Function(T) value);

  /// Constructs a finalizer.
  ///
  /// This is fine as a non-atomic operation, because the GC only looks at
  /// finalizer instances when it process their entries. By preventing inlining
  /// we ensure the finalizer to have been fully initialized by the time
  /// any [attach] on it is called.
  ///
  /// Alternatively, we could make it a recognized method and add a reachability
  /// fence on the relevant members.
  @pragma('vm:never-inline')
  _FinalizerImpl(void Function(T) callback) {
    allEntries = <FinalizerEntry>{};
    _callback = Zone.current.bindUnaryCallbackGuarded(callback);
    setIsolate();
    isolateRegisterFinalizer();
  }

  void attach(Object value, T token, {Object? detach}) {
    assert(!identical(value, token),
        "The token should not be the value being attached");

    checkValidWeakTarget(value, 'value');
    if (detach != null) {
      checkValidWeakTarget(detach, 'detach');
    }

    final entry = FinalizerEntry.allocate(value, token, detach, this);
    allEntries.add(entry);
    // Ensure value stays reachable until after having initialized the entry.
    // This ensures the token and finalizer are set.
    reachabilityFence(value);

    if (detach != null) {
      (detachments[detach] ??= <FinalizerEntry>{}).add(entry);
    }
  }

  void _runFinalizers() {
    FinalizerEntry? entry = exchangeEntriesCollectedWithNull();
    while (entry != null) {
      final token = entry.token;
      // Check token for identical, detach might have been called.
      if (!identical(token, entry)) {
        _callback(unsafeCast<T>(token));
      }
      allEntries.remove(entry);
      final detach = entry.detach;
      if (detach != null) {
        detachments[detach]?.remove(entry);
      }
      entry = entry.next;
    }
  }

  @pragma("vm:entry-point", "call")
  static _handleFinalizerMessage(_FinalizerImpl finalizer) {
    finalizer._runFinalizers();
  }
}
