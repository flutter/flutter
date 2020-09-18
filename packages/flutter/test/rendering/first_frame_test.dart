// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../flutter_test_alternative.dart';
import '_first_frame_helper_io.dart' if (dart.library.html)
  '_first_frame_helper_web.dart';

void main() {
  test('Flutter dispatches first frame event on the web only', () async {
    if (!kIsWeb) {
      return;
    }
    final Future<bool> didDispatchFirstFrame = onFlutterFirstFrameEvent();

    final TestRenderBinding binding = TestRenderBinding();
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();

    expect(await didDispatchFirstFrame, true);
  });
}

class TestRenderBinding extends BindingBase with SchedulerBinding, ServicesBinding, GestureBinding, SemanticsBinding, RendererBinding {
  @override
  void initInstances() {
    super.initInstances();
  }
}
