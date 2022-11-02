// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:fidl_fuchsia_ui_test_input/fidl_async.dart' as test_mouse;
import 'package:fuchsia_services/services.dart';
import 'package:zircon/zircon.dart';

void main() {
  print('Launching mouse-input-view');
  MyApp app = MyApp();
  app.run();
}

List<test_mouse.MouseButton> getPressedButtons(int buttons) {
  var pressed_buttons = <test_mouse.MouseButton>[];
  if (buttons & 0x1 != 0) {
    pressed_buttons.add(test_mouse.MouseButton.first);
  }
  if (buttons & (0x1 >> 1) != 0) {
    pressed_buttons.add(test_mouse.MouseButton.second);
  }
  if (buttons & (0x1 >> 2) != 0) {
    pressed_buttons.add(test_mouse.MouseButton.third);
  }

  return pressed_buttons;
}

test_mouse.MouseEventPhase getPhase(String event_type) {
  switch (event_type) {
    case 'add':
      return test_mouse.MouseEventPhase.add;
    case 'hover':
      return test_mouse.MouseEventPhase.hover;
    case 'down':
      return test_mouse.MouseEventPhase.down;
    case 'move':
      return test_mouse.MouseEventPhase.move;
    case 'up':
      return test_mouse.MouseEventPhase.up;
    default:
      print('Invalid event type: ${event_type}');
  }
}

class MyApp {
  static const _red = Color.fromARGB(255, 244, 67, 54);
  static const _orange = Color.fromARGB(255, 255, 152, 0);
  static const _yellow = Color.fromARGB(255, 255, 235, 59);
  static const _green = Color.fromARGB(255, 76, 175, 80);
  static const _blue = Color.fromARGB(255, 33, 150, 143);
  static const _purple = Color.fromARGB(255, 156, 39, 176);

  final List<Color> _colors = <Color>[
    _red,
    _orange,
    _yellow,
    _green,
    _blue,
    _purple,
  ];

  // Each tap will increment the counter, we then determine what color to choose
  int _touchCounter = 0;
  final _responseListener = test_mouse.MouseInputListenerProxy();

  void run() {
    Incoming.fromSvcPath()
      ..connectToService(_responseListener);
    // Set up window callbacks.
    window.onPointerDataPacket = (PointerDataPacket packet) {
      this.pointerDataPacket(packet);
    };
    window.onMetricsChanged = () {
      window.scheduleFrame();
    };
    window.onBeginFrame = (Duration duration) {
      this.beginFrame(duration);
    };

    // The child view should be attached to Scenic now.
    // Ready to build the scene.
    window.scheduleFrame();
  }

  void beginFrame(Duration duration) {
    // Convert physical screen size of device to values
    final pixelRatio = window.devicePixelRatio;
    final size = window.physicalSize / pixelRatio;
    final physicalBounds = Offset.zero & size * pixelRatio;
    // Set up Canvas that uses the screen size
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, physicalBounds);
    canvas.scale(pixelRatio, pixelRatio);
    // Draw something
    // Color of the screen is set initially to the first value in _colors
    // Incrementing _touchCounter will change screen color
    final paint = Paint()..color = _colors[_touchCounter % _colors.length];
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    // Build the scene
    final picture = recorder.endRecording();
    final sceneBuilder = SceneBuilder()
      ..pushClipRect(physicalBounds)
      ..addPicture(Offset.zero, picture)
      ..pop();
    window.render(sceneBuilder.build());
  }

  void pointerDataPacket(PointerDataPacket packet) async {
    int nowNanos = System.clockGetMonotonic();

    for (PointerData data in packet.data) {
      print('mouse-input-view received input: ${data.toStringFull()}');

      if (data.kind == PointerDeviceKind.mouse) {
        if (data.change == PointerChange.down) {
          _touchCounter++;
        }

        // Incoming.fromSvcPath()
        //   ..connectToService(_responseListener)
          // ..close();

        _respond(test_mouse.MouseInputListenerReportMouseInputRequest(
          localX: data.physicalX,
          localY: data.physicalY,
          buttons: getPressedButtons(data.buttons),
          phase: getPhase(data.change.name),
          timeReceived: nowNanos,
          wheelXPhysicalPixel: data.scrollDeltaX,
          wheelYPhysicalPixel: data.scrollDeltaY,
          componentName: 'mouse-input-view',
        ));
      }
    }

    window.scheduleFrame();
  }

  void _respond(test_mouse.MouseInputListenerReportMouseInputRequest request) async {
    print('mouse-input-view reporting mouse input to MouseInputListener');
    await _responseListener.reportMouseInput(request);
  }
}
