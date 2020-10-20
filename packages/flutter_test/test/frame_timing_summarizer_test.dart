// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test FrameTimingSummarizer', () {
    List<int> vsyncTimes = <int>[
      for (int i = 0; i < 100; i += 1) 100 * (i + 1),
    ];
    List<int> buildTimes = <int>[
      for (int i = 0; i < 100; i += 1) vsyncTimes[i] + 1000 * (i + 1),
    ];
    List<int> rasterTimes = <int>[
      for (int i = 0; i < 100; i += 1) 1000 * (i + 1) + 1000,
    ];
    // reversed to make sure sort is working.
    buildTimes = buildTimes.reversed.toList();
    rasterTimes = rasterTimes.reversed.toList();
    vsyncTimes = vsyncTimes.reversed.toList();
    final List<FrameTiming> inputData = <FrameTiming>[
      for (int i = 0; i < 100; i += 1)
        FrameTiming(
          vsyncStart: 0,
          buildStart: vsyncTimes[i],
          buildFinish: buildTimes[i],
          rasterStart: 500,
          rasterFinish: rasterTimes[i],
        ),
    ];

    final FrameTimingSummarizer summary = FrameTimingSummarizer(inputData);
    expect(summary.averageFrameBuildTime.inMicroseconds, 50500);
    expect(summary.p90FrameBuildTime.inMicroseconds, 90000);
    expect(summary.p99FrameBuildTime.inMicroseconds, 99000);
    expect(summary.worstFrameBuildTime.inMicroseconds, 100000);
    expect(summary.missedFrameBuildBudget, 84);

    expect(summary.averageFrameRasterizerTime.inMicroseconds, 51000);
    expect(summary.p90FrameRasterizerTime.inMicroseconds, 90500);
    expect(summary.p99FrameRasterizerTime.inMicroseconds, 99500);
    expect(summary.worstFrameRasterizerTime.inMicroseconds, 100500);
    expect(summary.missedFrameRasterizerBudget, 85);
    expect(summary.frameBuildTime.length, 100);

    expect(summary.averageVsyncOverhead.inMicroseconds, 5050);
    expect(summary.p90VsyncOverhead.inMicroseconds, 9000);
    expect(summary.p99VsyncOverhead.inMicroseconds, 9900);
    expect(summary.worstVsyncOverhead.inMicroseconds, 10000);
  });
}
