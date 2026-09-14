// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'src/allow_list_devices.dart';

/// Test harness for verifying `SystemUiMode` transitions on Android.
///
/// The companion test driver issues `flutterDriver.requestData(...)` calls
/// to apply modes and read the resulting decor-view `systemUiVisibility`
/// flags, which is the most direct signal of the regression class addressed
/// by https://github.com/flutter/flutter/pull/187207.
const MethodChannel _nativeDriver = MethodChannel('native_driver');

const Map<String, SystemUiMode> _modesByName = <String, SystemUiMode>{
  'leanBack': SystemUiMode.leanBack,
  'immersive': SystemUiMode.immersive,
  'immersiveSticky': SystemUiMode.immersiveSticky,
  'edgeToEdge': SystemUiMode.edgeToEdge,
};

void main() {
  ensureAndroidDevice();
  enableFlutterDriverExtension(
    handler: _handleCommand,
    commands: <CommandExtension>[nativeDriverCommands],
  );
  runApp(const _App());
}

Future<String> _handleCommand(String? command) async {
  if (command == null || command.isEmpty) {
    throw ArgumentError.value(command, 'command', 'must not be null or empty');
  }
  if (command == 'getSystemUiVisibility') {
    final Map<Object?, Object?>? raw = await _nativeDriver.invokeMethod<Map<Object?, Object?>>(
      'get_system_ui_visibility',
    );
    final int flags = (raw?['system_ui_visibility'] as int?) ?? 0;
    return json.encode(<String, Object?>{'systemUiVisibility': flags});
  }
  if (command.startsWith('applyMode:')) {
    final String name = command.substring('applyMode:'.length);
    final SystemUiMode? mode = _modesByName[name];
    if (mode == null) {
      throw ArgumentError.value(name, 'mode', 'unknown SystemUiMode');
    }
    await SystemChrome.setEnabledSystemUIMode(mode);
    return json.encode(<String, Object?>{'mode': name});
  }
  throw ArgumentError.value(command, 'command', 'unrecognized');
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ColoredBox(color: Color(0xFF202020)));
  }
}
