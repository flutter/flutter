// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import "dart:ffi" show IntPtr, Handle, Native, Void;
import "dart:nativewrappers" show NativeFieldWrapperClass1;

@patch
@pragma("vm:entry-point")
abstract interface class Mutex {
  @patch
  factory Mutex._() => _MutexImpl();
}

@pragma("vm:deeply-immutable")
@pragma("vm:entry-point")
final class _MutexImpl extends NativeFieldWrapperClass1 implements Mutex {
  _MutexImpl() {
    _initialize();
  }

  @Native<Void Function(Handle)>(symbol: "Mutex_Initialize")
  external void _initialize();

  @Native<Handle Function(Handle, Handle)>(symbol: "Mutex_RunLocked")
  external Object _runLocked(Object action);

  R runLocked<R>(R Function() action) {
    return _runLocked(action) as R;
  }
}

@patch
@pragma("vm:entry-point")
abstract interface class ConditionVariable {
  @patch
  factory ConditionVariable._() => _ConditionVariableImpl();
}

@pragma("vm:deeply-immutable")
@pragma("vm:entry-point")
final class _ConditionVariableImpl extends NativeFieldWrapperClass1
    implements ConditionVariable {
  _ConditionVariableImpl() {
    _initialize();
  }

  @Native<Void Function(Handle)>(symbol: "ConditionVariable_Initialize")
  external void _initialize();

  @Native<Void Function(Handle, Handle, IntPtr)>(
    symbol: "ConditionVariable_Wait",
  )
  external void _wait(Mutex mutex, int timeout);

  void wait(Mutex mutex, [int timeout = 0]) {
    if (timeout < 0) {
      throw ArgumentError.value(timeout, "timeout", "must be positive or zero");
    }
    _wait(mutex, timeout);
  }

  @Native<Void Function(Handle)>(symbol: "ConditionVariable_Notify")
  external void notify();

  @Native<Void Function(Handle)>(symbol: "ConditionVariable_NotifyAll")
  external void notifyAll();
}
