// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

import '../common.dart';

const int _kNumIterations = 1000000;
const int _kNumWarmUp = 10000;

void main() {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");
  print('MatrixUtils.transformRect benchmark...');

  Matrix4 _makePerspective(double radius, double angle, double perspective) {
    return MatrixUtils.createCylindricalProjectionTransform(
      radius: radius,
      angle: angle,
      perspective: perspective,
    );
  }

  final List<Matrix4> _transforms = <Matrix4>[
    Matrix4.identity()..scale(1.2, 1.3, 1.0)..rotateZ(0.1),
    Matrix4.identity()..translate(12.0, 13.0, 10.0),
    Matrix4.identity()..scale(1.2, 1.3, 1.0)..translate(12.0, 13.0, 10.0),
  ];
  final List<Matrix4> _perspectiveTransforms = <Matrix4>[
    _makePerspective(10.0, math.pi / 8.0, 0.3),
    _makePerspective( 8.0, math.pi / 8.0, 0.2),
    _makePerspective( 1.0, math.pi / 4.0, 0.1)..rotateX(0.1),
  ];
  final List<Rect> _rects = <Rect>[
    const Rect.fromLTRB(1.1, 1.2, 1.5, 1.8),
    const Rect.fromLTRB(1.1, 1.2, 0.0, 1.0),
    const Rect.fromLTRB(1.1, 1.2, 1.3, 1.0),
    const Rect.fromLTRB(-1.1, -1.2, 0.0, 1.0),
    const Rect.fromLTRB(-1.1, -1.2, -1.5, -1.8),
  ];
  final List<Offset> _offsets = <Offset>[
    const Offset(1.1, 1.2),
    const Offset(1.5, 1.8),
    const Offset(0.0, 0.0),
    const Offset(-1.1, -1.2),
    const Offset(-1.5, -1.8),
  ];
  assert(_rects.length.gcd(_transforms.length) == 1);
  assert(_rects.length.gcd(_perspectiveTransforms.length) == 1);
  assert(_offsets.length.gcd(_perspectiveTransforms.length) == 1);
  assert(_offsets.length.gcd(_transforms.length) == 1);

  // Warm up lap
  for (int i = 0; i < _kNumWarmUp; i += 1) {
    final Rect rect = _rects[i % _rects.length];
    final Offset offset = _offsets[i % _offsets.length];
    final Matrix4 transform = (i > _kNumWarmUp / 2)
        ? _perspectiveTransforms[i % _perspectiveTransforms.length]
        : _transforms[i % _transforms.length];
    MatrixUtils.transformRect(transform, rect);
    MatrixUtils.transformPoint(transform, offset);
  }

  final Stopwatch watch = Stopwatch();
  watch.start();
  for (int i = 0; i < _kNumIterations; i += 1) {
    final Rect rect = _rects[i % _rects.length];
    final Matrix4 transform = _perspectiveTransforms[i % _perspectiveTransforms.length];
    MatrixUtils.transformRect(transform, rect);
  }
  watch.stop();
  final int rectMicrosecondsPerspective = watch.elapsedMicroseconds;

  watch.reset();
  watch.start();
  for (int i = 0; i < _kNumIterations; i += 1) {
    final Rect rect = _rects[i % _rects.length];
    final Matrix4 transform = _transforms[i % _transforms.length];
    MatrixUtils.transformRect(transform, rect);
  }
  watch.stop();
  final int rectMicrosecondsAffine = watch.elapsedMicroseconds;

  watch.reset();
  watch.start();
  for (int i = 0; i < _kNumIterations; i += 1) {
    final Offset offset = _offsets[i % _offsets.length];
    final Matrix4 transform = _perspectiveTransforms[i % _perspectiveTransforms.length];
    MatrixUtils.transformPoint(transform, offset);
  }
  watch.stop();
  final int pointMicrosecondsPerspective = watch.elapsedMicroseconds;

  watch.reset();
  watch.start();
  for (int i = 0; i < _kNumIterations; i += 1) {
    final Offset offset = _offsets[i % _offsets.length];
    final Matrix4 transform = _transforms[i % _transforms.length];
    MatrixUtils.transformPoint(transform, offset);
  }
  watch.stop();
  final int pointMicrosecondsAffine = watch.elapsedMicroseconds;

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  const double scale = 1000.0 / _kNumIterations;
  printer.addResult(
    description: 'MatrixUtils.transformRectPerspective',
    value: rectMicrosecondsPerspective * scale,
    unit: 'ns per iteration',
    name: 'MatrixUtils_persp_transformRect_iteration',
  );
  printer.addResult(
    description: 'MatrixUtils.transformRectAffine',
    value: rectMicrosecondsAffine * scale,
    unit: 'ns per iteration',
    name: 'MatrixUtils_affine_transformRect_iteration',
  );
  printer.addResult(
    description: 'MatrixUtils.TransformPointPerspective',
    value: pointMicrosecondsPerspective * scale,
    unit: 'ns per iteration',
    name: 'MatrixUtils_persp_transformPoint_iteration',
  );
  printer.addResult(
    description: 'MatrixUtils.TransformPointAffine',
    value: pointMicrosecondsAffine * scale,
    unit: 'ns per iteration',
    name: 'MatrixUtils_affine_transformPoint_iteration',
  );
  printer.printToStdout();
}
