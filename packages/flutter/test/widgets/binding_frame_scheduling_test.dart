// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show window;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Instantiating WidgetsFlutterBinding does neither schedule a frame nor register frame callbacks', () async {
    // Regression test for https://github.com/flutter/flutter/issues/39494.

    // Preconditions.
    expect(window.onBeginFrame, isNull);
    expect(window.onDrawFrame, isNull);

    // Instantiation does nothing with regards to frame scheduling.
    expect(WidgetsFlutterBinding.ensureInitialized(), isA<WidgetsFlutterBinding>());
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
    expect(window.onBeginFrame, isNull);
    expect(window.onDrawFrame, isNull);

    // Framework starts with detached statue. Sends resumed signal to enable frame.
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed')!;
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    expect(window.onBeginFrame, isNull);
    expect(window.onDrawFrame, isNull);
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

    // Frame callbacks are registered lazily (and a frame scheduled) when the root widget is attached.
    WidgetsBinding.instance.attachRootWidget(const Placeholder());
    expect(window.onBeginFrame, isNotNull);
    expect(window.onDrawFrame, isNotNull);
    expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
  });
}
