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
Profile _autoProfile({
  void Function(Profile profile)? onCreate,
  void Function(int sampleIndex)? afterSample,
}) {
  final profile = Profile(name: 'bench_test');
  onCreate?.call(profile);
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
    _autoProfile(
      onCreate: (Profile created) => profile = created,
      afterSample: (int i) => callsAfterSample[i] = calls.length,
    );

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

  test('toJson(reportSamples: true) splits each series at its own warm-up and keeps outliers', () {
    final profile = Profile(name: 'custom_warm_up', useCustomWarmUp: true);
    for (var i = 0; i < 3; i += 1) {
      profile.addDataPoint('layout', _warmUpDuration(i), reported: true);
    }
    profile.addDataPoint('paint', _warmUpDuration(7), reported: false);
    profile.stopWarmingUp();
    final layoutMeasured = <double>[
      for (var i = 0; i < 10; i += 1)
        if (i == 4) 100000.0 else 1000.0,
    ];
    for (final value in layoutMeasured) {
      profile.addDataPoint('layout', Duration(microseconds: value.toInt()), reported: true);
    }
    profile.addDataPoint('paint', _measuredDuration(9000, 0), reported: false);
    profile.addDataPoint('paint', _measuredDuration(9000, 1), reported: false);
    profile.stopBenchmark();

    final Map<String, dynamic> json = profile.toJson(reportSamples: true);

    // The 100000 µs sample is classified as an outlier, yet it is still a
    // measured sample and is reported in place.
    expect(json['layout.outlierAverage'], 100000.0);
    expect(json['layout.average'], 1000.0);
    expect(json['layout.samples'], layoutMeasured);
    expect(json['paint.samples'], <double>[9000.0, 9001.0]);
  });

  test('extraData is merged after samples and may override them', () {
    final Profile profile = _autoProfile();
    profile.extraData['drawFrameDuration.samples'] = 'overridden';
    profile.extraData['totalUploadedBytes'] = 42;

    final Map<String, dynamic> json = profile.toJson(reportSamples: true);

    expect(json['drawFrameDuration.samples'], 'overridden');
    expect(json['totalUploadedBytes'], 42);
    expect(json['sceneBuildDuration.samples'], <double>[
      for (var i = 0; i < _measuredCount; i += 1) 9000.0 + i,
    ]);
  });

  test('toJson(reportSamples: true) returns fresh lists and does not change the profile', () {
    final Profile profile = _autoProfile();
    final expectedSamples = <double>[for (var i = 0; i < _measuredCount; i += 1) 5000.0 + i];

    final Map<String, dynamic> first = profile.toJson(reportSamples: true);
    (first['drawFrameDuration.samples'] as List<double>).clear();

    expect(profile.extraData, isEmpty);
    expect(profile.toJson().keys.toSet(), _legacyKeys);
    final Map<String, dynamic> second = profile.toJson(reportSamples: true);
    expect(second['drawFrameDuration.samples'], expectedSamples);
    expect(second['drawFrameDuration.average'], 5049.5);
  });

  test('phaseListener is read at each warm-up switch, not when the profile is created', () {
    final replaced = <(String, String)>[];
    final current = <(String, String)>[];
    Profile.phaseListener = (String benchmarkName, String phase) {
      replaced.add((benchmarkName, phase));
    };
    final early = Profile(name: 'created_before_swap', useCustomWarmUp: true);
    Profile.phaseListener = (String benchmarkName, String phase) {
      current.add((benchmarkName, phase));
    };

    early.stopWarmingUp();
    _autoProfile();

    expect(replaced, isEmpty);
    expect(current, <(String, String)>[
      ('created_before_swap', 'measure'),
      ('bench_test', 'measure'),
    ]);
  });
}
