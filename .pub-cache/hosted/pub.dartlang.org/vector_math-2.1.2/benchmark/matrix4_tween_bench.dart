// Copyright (c) 2019, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:vector_math/vector_math_64.dart';

mixin Setup on BenchmarkBase {
  final beginTransform = Matrix4.compose(
    Vector3(1.0, 1.0, 1.0),
    Quaternion.euler(0.0, 0.0, 0.0),
    Vector3(1.0, 1.0, 1.0),
  );

  final endTransform = Matrix4.compose(
    Vector3(5.0, 260.0, 1.0),
    Quaternion.euler(0.0, 1.0, -0.7),
    Vector3(0.6, 0.6, 0.6),
  );

  @override
  void run() {
    var sum_traces = 0.0;
    for (var i = 0; i <= 1024; i++) {
      final t = i / 1024.0;
      final m1 = lerp(beginTransform, endTransform, t);
      final m2 = lerp(endTransform, beginTransform, t);
      sum_traces += m1.trace();
      sum_traces += m2.trace();
    }
    if (sum_traces < 6320 || sum_traces > 6321) {
      throw StateError('Bad result: $sum_traces');
    }
  }

  Matrix4 lerp(Matrix4 begin, Matrix4 end, double t);
}

class Matrix4TweenBenchmark1 extends BenchmarkBase with Setup {
  Matrix4TweenBenchmark1() : super('Matrix4TweenBenchmark1');

  @override
  Matrix4 lerp(Matrix4 begin, Matrix4 end, double t) {
    final beginTranslation = Vector3.zero();
    final endTranslation = Vector3.zero();
    final beginRotation = Quaternion.identity();
    final endRotation = Quaternion.identity();
    final beginScale = Vector3.zero();
    final endScale = Vector3.zero();
    begin.decompose(beginTranslation, beginRotation, beginScale);
    end.decompose(endTranslation, endRotation, endScale);
    final lerpTranslation = beginTranslation * (1.0 - t) + endTranslation * t;
    final lerpRotation =
        (beginRotation.scaled(1.0 - t) + endRotation.scaled(t)).normalized();
    final lerpScale = beginScale * (1.0 - t) + endScale * t;
    return Matrix4.compose(lerpTranslation, lerpRotation, lerpScale);
  }
}

class Matrix4TweenBenchmark2 extends BenchmarkBase with Setup {
  Matrix4TweenBenchmark2() : super('Matrix4TweenBenchmark2');

  @override
  Matrix4 lerp(Matrix4 begin, Matrix4 end, double t) {
    begin.decompose(beginTranslation, beginRotation, beginScale);
    end.decompose(endTranslation, endRotation, endScale);
    Vector3.mix(beginTranslation, endTranslation, t, lerpTranslation);
    final lerpRotation =
        (beginRotation.scaled(1.0 - t) + endRotation.scaled(t)).normalized();
    Vector3.mix(beginScale, endScale, t, lerpScale);
    return Matrix4.compose(lerpTranslation, lerpRotation, lerpScale);
  }

  // Pre-allocated vectors.
  static final beginTranslation = Vector3.zero();
  static final endTranslation = Vector3.zero();
  static final lerpTranslation = Vector3.zero();
  static final beginRotation = Quaternion.identity();
  static final endRotation = Quaternion.identity();
  static final beginScale = Vector3.zero();
  static final endScale = Vector3.zero();
  static final lerpScale = Vector3.zero();
}

class Matrix4TweenBenchmark3 extends BenchmarkBase with Setup {
  Matrix4TweenBenchmark3() : super('Matrix4TweenBenchmark3');

  @override
  Matrix4 lerp(Matrix4 begin, Matrix4 end, double t) {
    begin.decompose(beginTranslation, beginRotation, beginScale);
    end.decompose(endTranslation, endRotation, endScale);
    Vector3.mix(beginTranslation, endTranslation, t, lerpTranslation);
    final lerpRotation =
        (beginRotation.scaled(1.0 - t) + endRotation.scaled(t)).normalized();
    Vector3.mix(beginScale, endScale, t, lerpScale);
    return Matrix4.compose(lerpTranslation, lerpRotation, lerpScale);
  }

  late final beginTranslation = Vector3.zero();
  late final endTranslation = Vector3.zero();
  late final lerpTranslation = Vector3.zero();
  late final beginRotation = Quaternion.identity();
  late final endRotation = Quaternion.identity();
  late final beginScale = Vector3.zero();
  late final endScale = Vector3.zero();
  late final lerpScale = Vector3.zero();
}

void main() {
  final benchmarks = [
    Matrix4TweenBenchmark1(),
    Matrix4TweenBenchmark2(),
    Matrix4TweenBenchmark3(),
  ];
  // Warmup all bencmarks.
  for (var b in benchmarks) {
    b.run();
  }
  for (var b in benchmarks) {
    b.exercise();
  }
  for (var b in benchmarks) {
    b.report();
  }
}
