// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef void _AsyncCallback();

class _AsyncCallbackEntry {
  final _AsyncCallback callback;
  _AsyncCallbackEntry? next;
  _AsyncCallbackEntry(this.callback);
}

/// Head of single linked list of pending callbacks.
_AsyncCallbackEntry? _nextCallback;

/// Tail of single linked list of pending callbacks.
_AsyncCallbackEntry? _lastCallback;

/// Tail of priority callbacks added by the currently executing callback.
///
/// Priority callbacks are put at the beginning of the
/// callback queue, so that if one callback schedules more than one
/// priority callback, they are still enqueued in scheduling order.
_AsyncCallbackEntry? _lastPriorityCallback;

/// Whether we are currently inside the callback loop.
///
/// If we are inside the loop, we never need to schedule the loop,
/// even if adding a first element.
bool _isInCallbackLoop = false;

void _microtaskLoop() {
  for (var entry = _nextCallback; entry != null; entry = _nextCallback) {
    _lastPriorityCallback = null;
    var next = entry.next;
    _nextCallback = next;
    if (next == null) _lastCallback = null;
    (entry.callback)();
  }
}

void _startMicrotaskLoop() {
  _isInCallbackLoop = true;
  try {
    // Moved to separate function because try-finally prevents
    // good optimization.
    _microtaskLoop();
  } finally {
    _lastPriorityCallback = null;
    _isInCallbackLoop = false;
    if (_nextCallback != null) {
      _AsyncRun._scheduleImmediate(_startMicrotaskLoop);
    }
  }
}

/// Schedules a callback to be called as a microtask.
///
/// The microtask is called after all other currently scheduled
/// microtasks, but as part of the current system event.
void _scheduleAsyncCallback(_AsyncCallback callback) {
  _AsyncCallbackEntry newEntry = new _AsyncCallbackEntry(callback);
  _AsyncCallbackEntry? lastCallback = _lastCallback;
  if (lastCallback == null) {
    _nextCallback = _lastCallback = newEntry;
    if (!_isInCallbackLoop) {
      _AsyncRun._scheduleImmediate(_startMicrotaskLoop);
    }
  } else {
    lastCallback.next = newEntry;
    _lastCallback = newEntry;
  }
}

/// Schedules a callback to be called before all other currently scheduled ones.
///
/// This callback takes priority over existing scheduled callbacks.
/// It is only used internally to give higher priority to error reporting.
///
/// Is always run in the root zone.
void _schedulePriorityAsyncCallback(_AsyncCallback callback) {
  if (_nextCallback == null) {
    _scheduleAsyncCallback(callback);
    _lastPriorityCallback = _lastCallback;
    return;
  }
  _AsyncCallbackEntry entry = new _AsyncCallbackEntry(callback);
  _AsyncCallbackEntry? lastPriorityCallback = _lastPriorityCallback;
  if (lastPriorityCallback == null) {
    entry.next = _nextCallback;
    _nextCallback = _lastPriorityCallback = entry;
  } else {
    var next = lastPriorityCallback.next;
    entry.next = next;
    lastPriorityCallback.next = entry;
    _lastPriorityCallback = entry;
    if (next == null) {
      _lastCallback = entry;
    }
  }
}

/// Runs a function asynchronously.
///
/// Callbacks registered through this function are always executed in order and
/// are guaranteed to run before other asynchronous events (like [Timer] events,
/// or DOM events).
///
/// **Warning:** it is possible to starve the DOM by registering asynchronous
/// callbacks through this method. For example the following program runs
/// the callbacks without ever giving the Timer callback a chance to execute:
/// ```dart
/// main() {
///   Timer.run(() { print("executed"); });  // Will never be executed.
///   foo() {
///     scheduleMicrotask(foo);  // Schedules [foo] in front of other events.
///   }
///   foo();
/// }
/// ```
/// ## Other resources
///
/// * [The Event Loop and Dart](https://dart.dev/articles/event-loop/):
/// Learn how Dart handles the event queue and microtask queue, so you can write
/// better asynchronous code with fewer surprises.
@pragma('vm:entry-point', 'call')
void scheduleMicrotask(void Function() callback) {
  _Zone currentZone = Zone._current;
  if (identical(_rootZone, currentZone)) {
    // No need to bind the callback. We know that the root's scheduleMicrotask
    // will be invoked in the root zone.
    _rootScheduleMicrotask(null, null, _rootZone, callback);
    return;
  }
  _ZoneFunction implementation = currentZone._scheduleMicrotask;
  if (identical(_rootZone, implementation.zone) &&
      _rootZone.inSameErrorZone(currentZone)) {
    _rootScheduleMicrotask(
        null, null, currentZone, currentZone.registerCallback(callback));
    return;
  }
  Zone.current.scheduleMicrotask(Zone.current.bindCallbackGuarded(callback));
}

class _AsyncRun {
  /// Schedule the given callback before any other event in the event-loop.
  external static void _scheduleImmediate(void Function() callback);
}
