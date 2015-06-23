// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library builtin_natives;

import "dart:async";

// Corelib 'print' implementation.
void _print(arg) {
  _Logger._printString(arg.toString());
}

class _Logger {
  static void _printString(String s) native "Logger_PrintString";
}

class _Timer implements Timer {
  _Timer(int milliseconds,
         void callback(Timer timer),
         bool repeating) {
    _id = _create(milliseconds, () {
      if (!repeating)
        _id = 0;
      callback(this);
    }, repeating);
  }

  void cancel() {
    _cancel(_id);
    _id = 0;
  }

  bool get isActive => _id != 0;

  static int _create(int milliseconds,
                     void callback(),
                     bool repeating) native "Timer_create";
  static void _cancel(int id) native "Timer_cancel";

  int _id;
}

void _scheduleMicrotask(void callback()) native "ScheduleMicrotask";
Timer _createTimer(int milliseconds,
                   void callback(Timer timer),
                   bool repeating) {
  return new _Timer(milliseconds, callback, repeating);
}

String _getBaseURLString() native "GetBaseURLString";
Uri _getBaseURL() => Uri.parse(_getBaseURLString());

_getPrintClosure() => _print;
_getScheduleMicrotaskClosure() => _scheduleMicrotask;
_getGetBaseURLClosure() =>_getBaseURL;
_getCreateTimerClosure() => _createTimer;
