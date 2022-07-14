// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('handleMetricsChanged does not scheduleForcedFrame unless there is a child to the renderView', () async {
    expect(SchedulerBinding.instance.hasScheduledFrame, false);
    RendererBinding.instance.handleMetricsChanged();
    expect(SchedulerBinding.instance.hasScheduledFrame, false);

    RendererBinding.instance.renderView.child = RenderLimitedBox();
    RendererBinding.instance.handleMetricsChanged();
    expect(SchedulerBinding.instance.hasScheduledFrame, true);
  });
}
