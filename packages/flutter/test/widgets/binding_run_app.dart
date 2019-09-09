// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/testing/async.dart';

void main() {
  test('runApp will schedule a frame', () async {
    FakeAsync().run((FakeAsync fakeAsync) {
      WidgetsFlutterBinding.ensureInitialized();
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

      runApp(const Placeholder());
      fakeAsync.flushTimers();
      expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
    });
  });
}




