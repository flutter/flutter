// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('scheduleForcedFrame sets up frame callbacks', () async {
    SchedulerBinding.instance.scheduleForcedFrame();
    expect(SchedulerBinding.instance.platformDispatcher.onBeginFrame, isNotNull);
  });
}
