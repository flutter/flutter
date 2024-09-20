// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._isolate_helper;

import 'dart:_runtime' as dart;
import 'dart:async';
import 'dart:_foreign_helper' show JS;

/// Deprecated way of initializing `main()` in DDC, typically called from JS.
@deprecated
void startRootIsolate(main, args) {
  if (args == null) args = <String>[];
  if (args is List) {
    if (args is! List<String>) args = List<String>.from(args);
    // DDC attaches signatures only when torn off, and the typical way of
    // getting `main` via the JS ABI won't do this. So use JS to invoke main.
    if (JS<bool>('!', 'typeof # == "function"', main)) {
      // JS will ignore extra arguments.
      JS('', '#(#, #)', main, args, null);
    } else {
      // Not a function. Use a dynamic call to throw an error.
      (main as dynamic)(args);
    }
  } else {
    throw ArgumentError("Arguments to main must be a List: $args");
  }
}

// TODO(vsm): Other libraries import global from here.  Consider replacing
// those uses to just refer to the one in dart:runtime.
final global = dart.global_;

class TimerImpl implements Timer {
  final bool _once;
  int? _handle;
  int _tick = 0;

  TimerImpl(int milliseconds, void callback()) : _once = true {
    if (hasTimer()) {
      int currentHotRestartIteration = dart.hotRestartIteration;
      void internalCallback() {
        _handle = null;
        dart.removeAsyncCallback();
        _tick = 1;
        if (currentHotRestartIteration == dart.hotRestartIteration) {
          callback();
        }
      }

      dart.addAsyncCallback();

      _handle = JS(
          'int', '#.setTimeout(#, #)', global, internalCallback, milliseconds);
    } else {
      throw UnsupportedError("`setTimeout()` not found.");
    }
  }

  TimerImpl.periodic(int milliseconds, void callback(Timer timer))
      : _once = false {
    if (hasTimer()) {
      dart.addAsyncCallback();
      int start = JS<int>('!', 'Date.now()');
      int currentHotRestartIteration = dart.hotRestartIteration;
      _handle = JS<int>('!', '#.setInterval(#, #)', global, () {
        if (currentHotRestartIteration != dart.hotRestartIteration) {
          cancel();
          return;
        }
        int tick = this._tick + 1;
        if (milliseconds > 0) {
          int duration = JS<int>('!', 'Date.now()') - start;
          if (duration > (tick + 1) * milliseconds) {
            tick = duration ~/ milliseconds;
          }
        }
        this._tick = tick;
        callback(this);
      }, milliseconds);
    } else {
      throw UnsupportedError("Periodic timer.");
    }
  }

  int get tick => _tick;

  void cancel() {
    if (hasTimer()) {
      if (_handle == null) return;
      dart.removeAsyncCallback();
      if (_once) {
        JS('void', '#.clearTimeout(#)', global, _handle);
      } else {
        JS('void', '#.clearInterval(#)', global, _handle);
      }
      _handle = null;
    } else {
      throw UnsupportedError("Canceling a timer.");
    }
  }

  bool get isActive => _handle != null;
}

bool hasTimer() {
  return JS('', '#.setTimeout', global) != null;
}
