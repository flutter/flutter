// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Quad, Vector3;

import '../common.dart';

const int _kNumWarmUp = 20;
const int _kNumIters = 1000000;

final Vector3 _point = Vector3(250.0, 120.0, 0.0);
final Quad _quad = Quad.points(
  Vector3(0.0, 0.0, 0.0),
  Vector3(180.0, 12.0, 0.0),
  Vector3(150.0, 160.0, 0.0),
  Vector3(-18.0, 120.0, 0.0),
);

double _runGetNearestPointInside(int iterations) {
  var checksum = 0.0;
  final watch = Stopwatch()..start();
  for (var i = 0; i < iterations; i += 1) {
    // ignore: invalid_use_of_visible_for_testing_member
    final Vector3 nearest = InteractiveViewer.getNearestPointInside(_point, _quad);
    checksum += nearest.x + nearest.y;
  }
  watch.stop();

  if (!checksum.isFinite) {
    throw StateError('Unexpected benchmark checksum: $checksum');
  }
  return watch.elapsedMicroseconds / iterations;
}

Future<void> execute() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  _runGetNearestPointInside(_kNumWarmUp);

  final printer = BenchmarkResultPrinter()
    ..addResult(
      description: 'InteractiveViewer.getNearestPointInside',
      value: _runGetNearestPointInside(_kNumIters),
      unit: 'µs per iteration',
      name: 'interactive_viewer_get_nearest_point_inside',
    );

  printer.printToStdout();
}

//
//  Note that the benchmark is normally run by benchmark_collection.dart.
//
Future<void> main() async {
  return execute();
}
