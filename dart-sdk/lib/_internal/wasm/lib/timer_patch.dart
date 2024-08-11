// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "async_patch.dart";

// Implementation of `Timer` and `scheduleMicrotask` via the JS event loop.

/// JS event loop and timer functions, in a private class to avoid leaking the
/// definitions to users.
class _JSEventLoop {
  /// Schedule a callback from JS via `setTimeout`.
  static int _setTimeout(double ms, dynamic Function() callback) => JS<double>(
          r"""(ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms)""",
          ms,
          callback)
      .toInt();

  /// Cancel a callback scheduled with `setTimeout`.
  static void _clearTimeout(int handle) =>
      JS<void>(r"""(handle) => clearTimeout(handle)""", handle.toDouble());

  /// Schedule a periodic callback from JS via `setInterval`.
  static int _setInterval(double ms, dynamic Function() callback) => JS<double>(
          r"""(ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms)""",
          ms,
          callback)
      .toInt();

  /// Cancel a callback scheduled with `setInterval`.
  static void _clearInterval(int handle) =>
      JS<void>(r"""(handle) => clearInterval(handle)""", handle.toDouble());

  /// Schedule a callback from JS via `queueMicrotask`.
  static void _queueMicrotask(dynamic Function() callback) => JS<void>(
      r"""(c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c))""",
      callback);

  /// JS `Date.now()`, returns the number of milliseconds elapsed since the
  /// epoch.
  static int _dateNow() => JS<double>('() => Date.now()').toInt();
}

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void callback()) {
    return _OneShotTimer(duration, callback);
  }

  @patch
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    return _PeriodicTimer(duration, callback);
  }
}

abstract class _Timer implements Timer {
  final int _milliseconds;
  int _tick;
  int? _handle;

  @override
  int get tick => _tick;

  @override
  bool get isActive => _handle != null;

  _Timer(Duration duration)
      : _milliseconds = duration.inMilliseconds,
        _tick = 0,
        _handle = null {
    _schedule();
  }

  void _schedule();
}

class _OneShotTimer extends _Timer {
  final void Function() _callback;

  _OneShotTimer(Duration duration, this._callback) : super(duration);

  @override
  void _schedule() {
    _handle = _JSEventLoop._setTimeout(_milliseconds.toDouble(), () {
      _tick++;
      _handle = null;
      _callback();
    });
  }

  @override
  void cancel() {
    final int? handle = _handle;
    if (handle != null) {
      _JSEventLoop._clearTimeout(handle);
      _handle = null;
    }
  }
}

class _PeriodicTimer extends _Timer {
  final void Function(Timer) _callback;

  _PeriodicTimer(Duration duration, this._callback) : super(duration);

  @override
  void _schedule() {
    final int start = _JSEventLoop._dateNow();
    _handle = _JSEventLoop._setInterval(_milliseconds.toDouble(), () {
      _tick++;
      if (_milliseconds > 0) {
        final int duration = _JSEventLoop._dateNow() - start;
        if (duration > _tick * _milliseconds) {
          _tick = duration ~/ _milliseconds;
        }
      }
      _callback(this);
    });
  }

  @override
  void cancel() {
    final int? handle = _handle;
    if (handle != null) {
      _JSEventLoop._clearInterval(handle);
      _handle = null;
    }
  }
}

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    _JSEventLoop._queueMicrotask(callback);
  }
}
