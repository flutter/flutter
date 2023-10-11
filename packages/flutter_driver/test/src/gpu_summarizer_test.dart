// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/src/driver/gpu_sumarizer.dart';

import '../common.dart';

TimelineEvent newGPUStart(int timeStamp) => TimelineEvent(<String, dynamic>{
  'name': 'GPUStart',
  'ph': 'b',
  'ts': timeStamp,
  'args': <String, String>{},
});

TimelineEvent newGPUEnd(int timeStamp) => TimelineEvent(<String, dynamic>{
  'name': 'GPUEnd',
  'ph': 'b',
  'ts': timeStamp,
  'args': <String, String>{},
});


void main() {
  test('Can process GPU start and end events.', () {
    final GpuSumarizer summarizer = GpuSumarizer(<TimelineEvent>[
      newGPUStart(10000),
      newGPUEnd(50000),
      newGPUStart(50000),
      newGPUEnd(100000),
    ]);

    expect(summarizer.computeAverageGPUTime(), 45);
    expect(summarizer.computePercentileGPUTime(50.0), 50);
    expect(summarizer.computeWorstGPUTime(), 50);
  });
}
