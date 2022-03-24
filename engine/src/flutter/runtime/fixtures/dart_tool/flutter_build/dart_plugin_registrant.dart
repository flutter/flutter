// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';
import 'dart:ui';
import 'dart:io' show Platform;

void passMessage(String message) native 'PassMessage';

bool didCallRegistrantBeforeEntrypoint = false;

// Test the Dart plugin registrant.
@pragma('vm:entry-point')
class _PluginRegistrant {

  @pragma('vm:entry-point')
  static void register() {
    if (didCallRegistrantBeforeEntrypoint) {
      throw '_registerPlugins is being called twice';
    }
    didCallRegistrantBeforeEntrypoint = true;
  }

}


@pragma('vm:entry-point')
void mainForPluginRegistrantTest() {
  if (didCallRegistrantBeforeEntrypoint) {
    passMessage('_PluginRegistrant.register() was called');
  } else {
    passMessage('_PluginRegistrant.register() was not called');
  }
}

void main() {}

void dartPluginRegistrantIsolate(SendPort sendPort) {
  DartPluginRegistrant.ensureInitialized();
  sendPort.send(didCallRegistrantBeforeEntrypoint);
}

@pragma('vm:entry-point')
void callDartPluginRegistrantFromBackgroundIsolate() async {
  ReceivePort receivePort = ReceivePort();
  Isolate isolate = await Isolate.spawn(dartPluginRegistrantIsolate, receivePort.sendPort);
  bool didCallEntrypoint = await receivePort.first;
  if (didCallEntrypoint) {
    passMessage('_PluginRegistrant.register() was called on background isolate');
  } else {
    passMessage('_PluginRegistrant.register() was not called on background isolate');
  }
  isolate.kill();
}

void noDartPluginRegistrantIsolate(SendPort sendPort) {
  sendPort.send(didCallRegistrantBeforeEntrypoint);
}

@pragma('vm:entry-point')
void dontCallDartPluginRegistrantFromBackgroundIsolate() async {
  ReceivePort receivePort = ReceivePort();
  Isolate isolate = await Isolate.spawn(noDartPluginRegistrantIsolate, receivePort.sendPort);
  bool didCallEntrypoint = await receivePort.first;
  if (didCallEntrypoint) {
    passMessage('_PluginRegistrant.register() was called on background isolate');
  } else {
    passMessage('_PluginRegistrant.register() was not called on background isolate');
  }
  isolate.kill();
}
