// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "async_patch.dart";

@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
abstract final class _MicrotaskMirrorQueue {
  // This will be set to true by the native runtime's
  // `DartUtils::PrepareAsyncLibrary` when the CLI flag `--profile-microtasks`
  // is set.
  @pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
  static bool _shouldProfileMicrotasks = false;

  @pragma("vm:external-name", "MicrotaskMirrorQueue_onScheduleAsyncCallback")
  external static void _onScheduleAsyncCallback();

  @pragma(
    "vm:external-name",
    "MicrotaskMirrorQueue_onSchedulePriorityAsyncCallback",
  )
  external static void _onSchedulePriorityAsyncCallback();

  @pragma("vm:external-name", "MicrotaskMirrorQueue_onAsyncCallbackComplete")
  external static void _onAsyncCallbackComplete(int startTime, int endTime);
}

@patch
void _beforeScheduleMicrotaskCallback() {
  if (!const bool.fromEnvironment("dart.vm.product") &&
      _MicrotaskMirrorQueue._shouldProfileMicrotasks) {
    _MicrotaskMirrorQueue._onScheduleAsyncCallback();
  }
}

@patch
void _beforeSchedulePriorityCallback() {
  if (!const bool.fromEnvironment("dart.vm.product") &&
      _MicrotaskMirrorQueue._shouldProfileMicrotasks) {
    _MicrotaskMirrorQueue._onSchedulePriorityAsyncCallback();
  }
}

@patch
void Function() _microtaskEntryCallback(_AsyncCallbackEntry entry) {
  if (const bool.fromEnvironment("dart.vm.product") ||
      !_MicrotaskMirrorQueue._shouldProfileMicrotasks) {
    return entry.callback;
  } else {
    @pragma("vm:invisible")
    void timedCallback() {
      final callbackStartTime = Timeline.now;
      (entry.callback)();
      final callbackEndTime = Timeline.now;
      _MicrotaskMirrorQueue._onAsyncCallbackComplete(
        callbackStartTime,
        callbackEndTime,
      );
    }

    ;
    return timedCallback;
  }
}

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    final closure = _ScheduleImmediate._closure;
    if (closure == null) {
      throw UnsupportedError("Microtasks are not supported");
    }
    closure(callback);
  }
}

typedef void _ScheduleImmediateClosure(void callback());

class _ScheduleImmediate {
  static _ScheduleImmediateClosure? _closure;
}

@pragma("vm:entry-point", "call")
void _setScheduleImmediateClosure(_ScheduleImmediateClosure closure) {
  _ScheduleImmediate._closure = closure;
}

@pragma("vm:entry-point", "call")
void _ensureScheduleImmediate() {
  _AsyncRun._scheduleImmediate(_startMicrotaskLoop);
}
