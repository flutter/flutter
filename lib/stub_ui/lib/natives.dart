// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(dnfield): remove unused_element ignores when https://github.com/dart-lang/sdk/issues/35164 is resolved.

part of ui;

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
void _setupHooks() {  // ignore: unused_element
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
/// such as `flutter build` or Dart `gen_snapshot` in order to pre-compile this code offline.
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
  throw UnimplementedError();
}
