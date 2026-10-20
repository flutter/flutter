// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:macrobenchmarks/src/web/recorder.dart';

const int _warmUpCount = 200;
const int _measuredCount = 100;

/// Warm-up magnitudes (0..199 µs) never overlap the measured ones.
Duration _warmUpDuration(int i) => Duration(microseconds: i);

/// Measured magnitudes are distinct per series and per index so ordering
/// and warm-up exclusion are both observable.
Duration _measuredDuration(int seriesOffset, int i) => Duration(microseconds: seriesOffset + i);

/// Feeds a [Profile] that uses automatic warm-up through `addDataPoint`,
/// interleaving a reported series and an unreported series.
Profile _autoProfile({void Function(int sampleIndex)? afterSample}) {
  final profile = Profile(name: 'bench_test');
  for (var i = 0; i < _warmUpCount + _measuredCount; i += 1) {
    final bool warmUp = i < _warmUpCount;
    final int j = i - _warmUpCount;
    profile.addDataPoint(
      'drawFrameDuration',
      warmUp ? _warmUpDuration(i) : _measuredDuration(5000, j),
      reported: true,
    );
    profile.addDataPoint(
      'sceneBuildDuration',
      warmUp ? _warmUpDuration(i) : _measuredDuration(9000, j),
      reported: false,
    );
    afterSample?.call(i);
  }
  return profile;
}

const Set<String> _legacyKeys = <String>{
  'name',
  'scoreKeys',
  'drawFrameDuration.average',
  'drawFrameDuration.outlierAverage',
  'drawFrameDuration.outlierRatio',
  'drawFrameDuration.noise',
  'sceneBuildDuration.average',
  'sceneBuildDuration.outlierAverage',
  'sceneBuildDuration.outlierRatio',
  'sceneBuildDuration.noise',
};

void main() {
  tearDown(() {
    Profile.phaseListener = null;
  });

  test('toJson without options emits exactly the legacy key set', () {
    final Profile profile = _autoProfile();
    expect(profile.isRunning, isFalse);

    final Map<String, dynamic> json = profile.toJson();

    expect(json.keys.toSet(), _legacyKeys);
    expect(json['name'], 'bench_test');
    expect(json['scoreKeys'], <String>[
      'drawFrameDuration.average',
      'drawFrameDuration.outlierRatio',
    ]);
    expect(json['drawFrameDuration.average'], 5049.5);
    expect(json['sceneBuildDuration.average'], 9049.5);
  });

  test('toJson(reportSamples: true) adds only measured samples in order', () {
    final Profile profile = _autoProfile();

    final Map<String, dynamic> json = profile.toJson(reportSamples: true);

    expect(json.keys.toSet(), <String>{
      ..._legacyKeys,
      'drawFrameDuration.samples',
      'sceneBuildDuration.samples',
    });
    expect(json['scoreKeys'], <String>[
      'drawFrameDuration.average',
      'drawFrameDuration.outlierRatio',
    ]);
    expect(json['drawFrameDuration.samples'], isA<List<double>>());
    expect(json['drawFrameDuration.samples'], <double>[
      for (var i = 0; i < _measuredCount; i += 1) 5000.0 + i,
    ]);
    expect(json['sceneBuildDuration.samples'], <double>[
      for (var i = 0; i < _measuredCount; i += 1) 9000.0 + i,
    ]);
    // The aggregate statistics are unaffected by sample reporting.
    expect(json['drawFrameDuration.average'], 5049.5);
    expect(json['sceneBuildDuration.average'], 9049.5);
  });

  test('phaseListener fires once with measure at the automatic warm-up switch', () {
    final calls = <(String, String, bool)>[];
    late Profile profile;
    Profile.phaseListener = (String benchmarkName, String phase) {
      calls.add((benchmarkName, phase, profile.isWarmingUp));
    };
    final callsAfterSample = <int, int>{};
    profile = _autoProfile(afterSample: (int i) => callsAfterSample[i] = calls.length);

    // Silent through warm-up, fires on the sample that ends warm-up, then
    // stays silent for every measured sample.
    expect(callsAfterSample[_warmUpCount - 2], 0);
    expect(callsAfterSample[_warmUpCount - 1], 1);
    expect(callsAfterSample[_warmUpCount + _measuredCount - 1], 1);
    expect(calls, <(String, String, bool)>[('bench_test', 'measure', false)]);
  });

  test('phaseListener fires once when stopWarmingUp is called manually', () {
    final calls = <(String, String)>[];
    Profile.phaseListener = (String benchmarkName, String phase) {
      calls.add((benchmarkName, phase));
    };
    final profile = Profile(name: 'custom_warm_up', useCustomWarmUp: true);
    profile.addDataPoint('frame', _warmUpDuration(1), reported: true);
    expect(calls, isEmpty);

    profile.stopWarmingUp();
    expect(profile.isWarmingUp, isFalse);
    expect(calls, <(String, String)>[('custom_warm_up', 'measure')]);

    expect(profile.stopWarmingUp, throwsStateError);
    expect(calls, <(String, String)>[('custom_warm_up', 'measure')]);
  });

  test('no phaseListener means the warm-up switch completes without error', () {
    final Profile profile = _autoProfile();

    expect(profile.isWarmingUp, isFalse);
    expect(profile.isRunning, isFalse);
    expect(profile.toJson().keys.toSet(), _legacyKeys);
  });
}
