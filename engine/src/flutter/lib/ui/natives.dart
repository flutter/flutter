// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
part of dart.ui;

// ignore_for_file: avoid_classes_with_only_static_members

/// Helper functions for Dart Plugin Registrants.
class DartPluginRegistrant {
  static bool _wasInitialized = false;

  /// Makes sure the that the Dart Plugin Registrant has been called for this
  /// isolate. This can safely be executed multiple times on the same isolate,
  /// but should not be called on the Root isolate.
  static void ensureInitialized() {
    if (!_wasInitialized) {
      _wasInitialized = true;
      _ensureInitialized();
    }
  }
  @FfiNative<Void Function()>('DartPluginRegistrant_EnsureInitialized')
  external static void _ensureInitialized();
}

// Corelib 'print' implementation.
void _print(String arg) {
  _Logger._printString(arg);
}

void _printDebug(String arg) {
  _Logger._printDebugString(arg);
}

class _Logger {
  @FfiNative<Void Function(Handle)>('DartRuntimeHooks::Logger_PrintString')
  external static void _printString(String? s);

  @FfiNative<Void Function(Handle)>('DartRuntimeHooks::Logger_PrintDebugString')
  external static void _printDebugString(String? s);
}

// If we actually run on big endian machines, we'll need to do something smarter
// here. We don't use [Endian.Host] because it's not a compile-time
// constant and can't propagate into the set/get calls.
const Endian _kFakeHostEndian = Endian.little;

// A service protocol extension to schedule a frame to be rendered into the
// window.
Future<developer.ServiceExtensionResponse> _scheduleFrame(
  String method,
  Map<String, String> parameters,
) async {
  // Schedule the frame.
  PlatformDispatcher.instance.scheduleFrame();
  // Always succeed.
  return developer.ServiceExtensionResponse.result(json.encode(<String, String>{
    'type': 'Success',
  }));
}

Future<developer.ServiceExtensionResponse> _reinitializeShader(
  String method,
  Map<String, String> parameters,
) async {
  final String? assetKey = parameters['assetKey'];
  if (assetKey != null) {
    FragmentProgram._reinitializeShader(assetKey);
  }

  // Always succeed.
  return developer.ServiceExtensionResponse.result(json.encode(<String, String>{
    'type': 'Success',
  }));
}

Future<developer.ServiceExtensionResponse> _getImpellerEnabled(
  String method,
  Map<String, String> parameters,
) async {
  return developer.ServiceExtensionResponse.result(json.encode(<String, Object>{
    'type': 'Success',
    'enabled': _impellerEnabled,
  }));
}

@pragma('vm:entry-point')
void _setupHooks() {
  assert(() {
    // In debug mode, register the schedule frame extension.
    developer.registerExtension('ext.ui.window.scheduleFrame', _scheduleFrame);

    // In debug mode, allow shaders to be reinitialized.
    developer.registerExtension(
      'ext.ui.window.reinitializeShader',
      _reinitializeShader,
    );
    return true;
  }());

  // In debug and profile mode, allow tools to display the current rendering backend.
  if (!_kReleaseMode) {
    developer.registerExtension(
      'ext.ui.window.impellerEnabled',
      _getImpellerEnabled,
    );
  }
}

const bool _kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// Returns runtime Dart compilation trace as a UTF-8 encoded memory buffer.
///
/// The buffer contains a list of symbols compiled by the Dart JIT at runtime up
/// to the point when this function was called. This list can be saved to a text
/// file and passed to tools such as `flutter build` or Dart `gen_snapshot` in
/// order to pre-compile this code offline.
///
/// The list has one symbol per line of the following format:
/// `<namespace>,<class>,<symbol>\n`.
///
/// Here are some examples:
///
/// ```csv
/// dart:core,Duration,get:inMilliseconds
/// package:flutter/src/widgets/binding.dart,::,runApp
/// file:///.../my_app.dart,::,main
/// ```
///
/// This function is only effective in debug and dynamic modes, and will throw in AOT mode.
List<int> saveCompilationTrace() {
  throw UnimplementedError();
}

@FfiNative<Void Function(Handle)>('DartRuntimeHooks::ScheduleMicrotask')
external void _scheduleMicrotask(void Function() callback);

@FfiNative<Handle Function(Handle)>('DartRuntimeHooks::GetCallbackHandle')
external int? _getCallbackHandle(Function closure);

@FfiNative<Handle Function(Int64)>('DartRuntimeHooks::GetCallbackFromHandle')
external Function? _getCallbackFromHandle(int handle);

typedef _PrintClosure = void Function(String line);

// Used by the embedder to initialize how printing is performed.
// See also https://github.com/dart-lang/sdk/blob/main/sdk/lib/_internal/vm/lib/print_patch.dart
@pragma('vm:entry-point')
_PrintClosure _getPrintClosure() => _print;

typedef _ScheduleImmediateClosure = void Function(void Function());

// Used by the embedder to initialize how microtasks are scheduled.
// See also https://github.com/dart-lang/sdk/blob/main/sdk/lib/_internal/vm/lib/schedule_microtask_patch.dart
@pragma('vm:entry-point')
_ScheduleImmediateClosure _getScheduleMicrotaskClosure() => _scheduleMicrotask;

// Used internally to indicate whether the Engine is using Impeller for
// rendering.
@pragma('vm:entry-point')
bool _impellerEnabled = false;
