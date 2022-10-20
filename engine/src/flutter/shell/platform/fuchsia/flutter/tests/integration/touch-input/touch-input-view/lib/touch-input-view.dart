// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(https://fxbug.dev/84961): Fix null safety and remove this language version.
// @dart=2.9

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:args/args.dart';
import 'package:fidl_fuchsia_ui_test_input/fidl_async.dart' as test_touch;
import 'package:fuchsia_services/services.dart';
import 'package:zircon/zircon.dart';

void main() {
  print('Launching two-flutter view');
  MyApp app = MyApp();
  app.run();
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
  final _responseListener = test_touch.TouchInputListenerProxy();

  void run() {
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
      print('touch-input-view received tap: ${data.toStringFull()}');

      if (data.change == PointerChange.down) {
        _touchCounter++;
      }

      if (data.change == PointerChange.down || data.change == PointerChange.move) {
        Incoming.fromSvcPath()
          ..connectToService(_responseListener)
          ..close();

        _respond(test_touch.TouchInputListenerReportTouchInputRequest(
          localX: data.physicalX,
          localY: data.physicalY,
          timeReceived: nowNanos,
          componentName: 'touch-input-view',
        ));
      }
    }

    window.scheduleFrame();
  }

  void _respond(test_touch.TouchInputListenerReportTouchInputRequest request) async {
    print('touch-input-view reporting touch input to TouchInputListener');
    await _responseListener.reportTouchInput(request);
  }
}
