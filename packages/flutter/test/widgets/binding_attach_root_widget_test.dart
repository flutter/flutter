// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('attachRootWidget will schedule a frame', () async {
    final WidgetsFlutterBinding binding = WidgetsFlutterBinding.ensureInitialized();
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

    binding.attachRootWidget(const Placeholder());
    expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
  });
}
