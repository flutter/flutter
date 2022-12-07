// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is an instrumented test application. It has a single field, is
// able to receive keyboard input from the test fixture, and is able to report
// back the contents of its text field to the test fixture.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:fidl_fuchsia_ui_test_input/fidl_async.dart' as test_text;
import 'package:fuchsia_services/services.dart';
import 'package:zircon/zircon.dart';

// Corresponds to the USB HID values provided in fidl.fuchsia.input
// https://fuchsia.dev/reference/fidl/fuchsia.input
final Map<int, String> hidToKey = {
  458977: 'LEFT_SHIFT', // Keyboard Left Shift
  458792: 'ENTER', // Keyboard Enter (Return)
  458782: 'KEY_1', // Keyboard 1 and !
  458763: 'H', // Keyboard h and H
  458760: 'E', // Keyboard e and E
  458767: 'L', // Keyboard l and L
  458770: 'O', // Keyboard o and O
  458778: 'W', // Keyboard w and W
  458773: 'R', // Keyboard r and R
  458759: 'D', // Keyboard d and D
};

int main() {
  print('Launching text-input-view');
  TestApp app = TestApp();
  app.run();
}

class TestApp {
  static const _yellow = Color.fromARGB(255, 255, 255, 0);
  Color _backgroundColor = _yellow;

  final _responseListener = test_text.KeyboardInputListenerProxy();

  void run() {
    // Connect to keyboard input response listener
    Incoming.fromSvcPath().connectToService(_responseListener);
    // Set up window callbacks
    window.onPlatformMessage = (String name, ByteData data, PlatformMessageResponseCallback callback) {
      this.decodeAndReportPlatformMessage(name, data);
    };
    window.onMetricsChanged = () {
      window.scheduleFrame();
    };
    window.onBeginFrame = (Duration duration) {
      this.beginFrame(duration);
    };

    window.scheduleFrame();
  }

  void beginFrame(Duration duration) {
    // Convert physical screen size of device to values
    final pixelRatio = window.devicePixelRatio;
    final size = window.physicalSize / pixelRatio;
    final physicalBounds = Offset.zero & size * pixelRatio;
    final windowBounds = Offset.zero & size;
    // Set up a Canvas that uses the screen size
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, physicalBounds);
    canvas.scale(pixelRatio, pixelRatio);
    // Draw something
    final paint = Paint()..color = this._backgroundColor;
    canvas.drawRect(windowBounds, paint);
    // Build the scene
    final picture = recorder.endRecording();
    final sceneBuilder = SceneBuilder()
      ..pushClipRect(physicalBounds)
      ..addPicture(Offset.zero, picture)
      ..pop();
    window.render(sceneBuilder.build());
  }

  void decodeAndReportPlatformMessage(String name, ByteData data) async {
    final buffer = data.buffer;
    var list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    var decoded = utf8.decode(list);
    var decodedJson = json.decode(decoded);
    print('received ${name} platform message: ${decodedJson}');

    if (name == "flutter/keyevent" && decodedJson["type"] == "keydown") {
      if (hidToKey[decodedJson["hidUsage"]] != null) {
        await _respond(test_text.KeyboardInputListenerReportTextInputRequest(
          text: hidToKey[decodedJson["hidUsage"]],
        ));
      }
    }

    window.scheduleFrame();
  }

  void _respond(test_text.KeyboardInputListenerReportTextInputRequest request) async {
    print('text-input-view reporting keyboard input to KeyboardInputListener');
    await _responseListener.reportTextInput(request);
  }
}
