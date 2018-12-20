// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

// Corelib 'print' implementation.
void _print(dynamic arg) {
  _Logger._printString(arg.toString());
}

class _Logger {
  static void _printString(String s) native 'Logger_PrintString';
}

// A service protocol extension to schedule a frame to be rendered into the
// window.
Future<developer.ServiceExtensionResponse> _scheduleFrame(
    String method,
    Map<String, String> parameters
    ) async {
  // Schedule the frame.
  window.scheduleFrame();
  // Always succeed.
  return new developer.ServiceExtensionResponse.result(json.encode(<String, String>{
    'type': 'Success',
  }));
}

@pragma('vm:entry-point')
void _setupHooks() {
  assert(() {
    // In debug mode, register the schedule frame extension.
    developer.registerExtension('ext.ui.window.scheduleFrame', _scheduleFrame);
    return true;
  }());
}

/// Returns runtime Dart compilation trace as a UTF-8 encoded memory buffer.
///
/// The buffer contains a list of symbols compiled by the Dart JIT at runtime up to the point
/// when this function was called. This list can be saved to a text file and passed to tools
/// such as `flutter build` or Dart `gen_snapshot` in order to precompile this code offline.
///
/// The list has one symbol per line of the following format: `<namespace>,<class>,<symbol>\n`.
/// Here are some examples:
///
/// ```
/// dart:core,Duration,get:inMilliseconds
/// package:flutter/src/widgets/binding.dart,::,runApp
/// file:///.../my_app.dart,::,main
/// ```
///
/// This function is only effective in debug and dynamic modes, and will throw in AOT mode.
List<int> saveCompilationTrace() {
  final dynamic result = _saveCompilationTrace();
  if (result is Error)
    throw result;
  return result;
}

// TODO(sbaranov): This function will go away in subsequent PR, once the framework has caught up.
@Deprecated('Use saveCompilationTrace() instead.')
List<int> dumpCompilationTrace() => saveCompilationTrace();

dynamic _saveCompilationTrace() native 'SaveCompilationTrace';

void _scheduleMicrotask(void callback()) native 'ScheduleMicrotask';

int _getCallbackHandle(Function closure) native 'GetCallbackHandle';
Function _getCallbackFromHandle(int handle) native 'GetCallbackFromHandle';

// Required for gen_snapshot to work correctly.
int _isolateId;

@pragma('vm:entry-point')
Function _getPrintClosure() => _print;
@pragma('vm:entry-point')
Function _getScheduleMicrotaskClosure() => _scheduleMicrotask;

// Though the "main" symbol is not included in any of the libraries imported
// above, the builtin library will be included manually during VM setup. This
// symbol is only necessary for precompilation. It is marked as a stanalone
// entry point into the VM. This prevents the precompiler from tree shaking
// away "main".
@pragma('vm:entry-point')
Function _getMainClosure() => main;
