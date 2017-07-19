// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flutter.Frame events are fired', (WidgetTester tester) async {
    final Future<FrameInfo> infoFuture =
        SchedulerBinding.instance.onFrameInfo.first;

    await tester.pumpWidget(const Text('foo'));

    final FrameInfo info = await infoFuture;
    expect(info.number, greaterThanOrEqualTo(0));
    expect(info.startTime, greaterThanOrEqualTo(0));
    expect(info.elapsed, greaterThanOrEqualTo(0));
  });
}
