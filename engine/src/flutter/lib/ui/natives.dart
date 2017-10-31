// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

// Corelib 'print' implementation.
void _print(dynamic arg) {
  _Logger._printString(arg.toString());
}

class _Logger {
  static void _printString(String s) native "Logger_PrintString";
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
  return new developer.ServiceExtensionResponse.result(JSON.encode({
    'type': 'Success',
  }));
}

void _setupHooks() {
  assert(() {
    // In debug mode, register the schedule frame extension.
    developer.registerExtension('ext.ui.window.scheduleFrame', _scheduleFrame);
    return true;
  });
}

void _scheduleMicrotask(void callback()) native "ScheduleMicrotask";

String _baseURL;
Uri _getBaseURL() => Uri.parse(_baseURL);

// Required for gen_snapshot to work correctly.
int _isolateId;

Function _getPrintClosure() => _print;
Function _getScheduleMicrotaskClosure() => _scheduleMicrotask;
Function _getGetBaseURLClosure() => _getBaseURL;

// Though the "main" symbol is not included in any of the libraries imported
// above, the builtin library will be included manually during VM setup. This
// symbol is only necessary for precompilation. It is marked as a stanalone
// entry point into the VM. This prevents the precompiler from tree shaking
// away "main"
Function _getMainClosure() => main;
