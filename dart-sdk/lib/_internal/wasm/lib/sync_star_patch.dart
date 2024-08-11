// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';

// Signature of the inner function of a `sync*` function. It takes the state
// object and a pending exception to be thrown (only for `yield*`).
// The function returns `true` if it is suspended by a `yield` or `yield*`, or
// `false` if it reaches the end of the function or a `return` statement.
typedef _ResumeFun
    = WasmFunction<bool Function(_SuspendState, Object?, StackTrace?)>;

// The CFG target index of the entry point to the `sync*` body.
const int _initialTargetIndex = 0;

// The execution state of a `sync*` function body.
@pragma("wasm:entry-point")
class _SuspendState {
  // The inner function.
  final _ResumeFun _resume;

  // Parent state to transition to when this body completes. This will be
  // present when the `sync*` iterable was consumed by a `yield*`.
  final _SuspendState? _parent;

  // The iterator that this state belongs to. All states in the parent chain
  // belong to the same iterator.
  @pragma("wasm:entry-point")
  _SyncStarIterator? _iterator;

  // Context containing the local variables of the function.
  @pragma("wasm:entry-point")
  WasmStructRef? _context;

  // CFG target index for the next resumption.
  @pragma("wasm:entry-point")
  WasmI32 _targetIndex = WasmI32.fromInt(_initialTargetIndex);

  // When a called function throws this stores the thrown exception. Used when
  // performing type tests in catch blocks.
  @pragma("wasm:entry-point")
  Object? _currentException = null;

  // When a called function throws this stores the stack trace.
  @pragma("wasm:entry-point")
  StackTrace? _currentExceptionStackTrace = null;

  _SuspendState(_SyncStarIterable iterable, _SuspendState? parent)
      : _resume = iterable._resume,
        _parent = parent,
        _context = iterable._context;
}

/// An [Iterable] returned from a `sync*` function.
@pragma("wasm:entry-point")
class _SyncStarIterable<T> extends Iterable<T> {
  // Context capturing the arguments to the `sync*` function and/or further
  // context when the `sync*` function is a lambda.
  @pragma("wasm:entry-point")
  WasmStructRef? _context;

  // The inner function.
  @pragma("wasm:entry-point")
  _ResumeFun _resume;

  external _SyncStarIterable();

  @pragma("wasm:entry-point")
  Iterator<T> get iterator {
    return _SyncStarIterator<T>(this);
  }
}

/// An [Iterator] for a `sync*` function.
@pragma("wasm:entry-point")
class _SyncStarIterator<T> implements Iterator<T> {
  // The resume function sets either [_current] (for `yield`) or
  // [_yieldStarIterable] (for `yield*`).
  @pragma("wasm:entry-point")
  T? _current;

  @pragma("wasm:entry-point")
  Iterable<T>? _yieldStarIterable;

  // Current iterator for a `yield*` if the iterable given to the `yield*` is
  // not a `_YieldStarIterable`.
  Iterator<T>? _yieldStarIterator;

  // Current state.
  _SuspendState _state;

  @override
  T get current => _current as T;

  _SyncStarIterator(_SyncStarIterable iterable)
      : _state = _SuspendState(iterable, null) {
    _state._iterator = this;
  }

  @pragma('wasm:prefer-inline')
  bool _handleSyncStarMethodCompletion() {
    if (_state._parent != null) {
      _state = _state._parent!;
      return true;
    }
    _current = null;
    return false;
  }

  @override
  bool moveNext() {
    Object? pendingException;
    StackTrace? pendingStackTrace;
    while (true) {
      // First delegate to an active nested iterator (if any).
      final iterator = _yieldStarIterator;
      if (iterator != null) {
        try {
          if (iterator.moveNext()) {
            _current = iterator.current;
            return true;
          }
        } catch (exception, stackTrace) {
          pendingException = exception;
          pendingStackTrace = stackTrace;
        }
        _yieldStarIterator = null;
      }

      try {
        // Resume current sync* method in order to move to the next value.
        final bool hasMore =
            _state._resume.call(_state, pendingException, pendingStackTrace);
        pendingException = null;
        pendingStackTrace = null;
        if (!hasMore) {
          if (_handleSyncStarMethodCompletion()) {
            continue;
          }
          return false;
        }
      } catch (exception, stackTrace) {
        pendingException = exception;
        pendingStackTrace = stackTrace;
        if (_handleSyncStarMethodCompletion()) {
          continue;
        }
        rethrow;
      }

      // Case: yield* some_iterator.
      final iterable = _yieldStarIterable;
      if (iterable != null) {
        _yieldStarIterable = null;
        _current = null;
        if (iterable is _SyncStarIterable<T>) {
          // We got a recursive yield* of sync* function. Instead of creating
          // a new iterator we replace our current _state (remembering the
          // current _state for later resumption).
          _state = _SuspendState(iterable, _state).._iterator = this;
        } else {
          try {
            _yieldStarIterator = iterable.iterator;
          } catch (exception, stackTrace) {
            pendingException = exception;
            pendingStackTrace = stackTrace;
          }
        }
        // Fetch the next item or continue with exception.
        continue;
      }

      // Inner function has set [_current].
      return true;
    }
  }
}
