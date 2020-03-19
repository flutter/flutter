// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/testing/async.dart';

void main() {
  test('The frames will only enable after runApp has bootstrapped the app', () async {
    WidgetsFlutterBinding.ensureInitialized();
    expect(SchedulerBinding.instance.framesEnabled, isFalse);
    // Framework starts with detached statue. Sends resumed signal to enable frame.
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed');
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });

    // The runApp will schedule timers to bootstrap the app. Uses FakeAsync
    // to make sure we flushes all timers before checking the result.
    FakeAsync().run((FakeAsync async) {
      runApp(const Placeholder());
      async.flushTimers();
    });
    expect(SchedulerBinding.instance.framesEnabled, isTrue);
  });
}
