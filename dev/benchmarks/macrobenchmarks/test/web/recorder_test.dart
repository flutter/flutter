// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrobenchmarks/src/web/recorder.dart';

void main() {
  test('profile JSON preserves warm-up, measured, and outlier samples in order', () {
    final profile = Profile(name: 'presentation', useCustomWarmUp: true);
    profile.addDataPoint(
      'presentation_duration',
      const Duration(microseconds: 500),
      reported: true,
    );
    profile.stopWarmingUp();
    for (var i = 0; i < 9; i++) {
      profile.addDataPoint(
        'presentation_duration',
        const Duration(microseconds: 10),
        reported: true,
      );
    }
    profile.addDataPoint(
      'presentation_duration',
      const Duration(microseconds: 1000),
      reported: true,
    );
    profile.stopBenchmark();

    final json = jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>;
    expect(json['scoreKeys'], <String>[
      'presentation_duration.average',
      'presentation_duration.outlierRatio',
    ]);
    expect(json['presentation_duration.average'], 10);
    expect(json['presentation_duration.outlierAverage'], 1000);
    expect(json['presentation_duration.outlierRatio'], 100);
    expect(json['presentation_duration.samples'], <Map<String, Object>>[
      <String, Object>{'valueUs': 500, 'warmUp': true, 'outlier': false},
      for (var i = 0; i < 9; i++)
        <String, Object>{'valueUs': 10, 'warmUp': false, 'outlier': false},
      <String, Object>{'valueUs': 1000, 'warmUp': false, 'outlier': true},
    ]);
  });
}
