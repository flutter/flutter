// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'channel_util.dart';

import 'platform_echo_mixin.dart';
import 'scenario.dart';

/// A blank page with a button that pops the page when tapped.
class PoppableScreenScenario extends Scenario with PlatformEchoMixin {
  /// Creates the PoppableScreenScenario.
  ///
  /// The [dispatcher] parameter must not be null.
  PoppableScreenScenario(PlatformDispatcher dispatcher)
      : super(dispatcher);

  // Rect for the pop button. Only defined once onMetricsChanged is called.
  Rect? _buttonRect;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.drawPaint(Paint()..color = const Color.fromARGB(255, 255, 255, 255));

    if (_buttonRect != null) {
      canvas.drawRect(
        _buttonRect!,
        Paint()..color = const Color.fromARGB(255, 255, 0, 0),
      );
    }
    final Picture picture = recorder.endRecording();

    builder.pushOffset(0, 0);
    builder.addPicture(Offset.zero, picture);
    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }

  @override
  void onDrawFrame() {
    // Just draw once since the content never changes.
  }

  @override
  void onMetricsChanged() {
    _buttonRect = Rect.fromLTRB(
      window.physicalSize.width / 4,
      window.physicalSize.height * 2 / 5,
      window.physicalSize.width * 3 / 4,
      window.physicalSize.height * 3 / 5,
    );
    window.scheduleFrame();
  }

  @override
  void onPointerDataPacket(PointerDataPacket packet) {
    for (final PointerData data in packet.data) {
      if (data.change == PointerChange.up &&
          (_buttonRect?.contains(Offset(data.physicalX, data.physicalY)) ?? false)
      ) {
        _pop();
      }
    }
  }

  void _pop() {
    sendJsonMethodCall(
      dispatcher: dispatcher,
      // 'flutter/platform' is the hardcoded name of the 'platform'
      // `SystemChannel` from the `SystemNavigator` API.
      // https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/services/system_navigator.dart.
      channel: 'flutter/platform',
      method: 'SystemNavigator.pop',
      // Don't care about the response. If it doesn't go through, the test
      // will fail.
    );
  }
}
