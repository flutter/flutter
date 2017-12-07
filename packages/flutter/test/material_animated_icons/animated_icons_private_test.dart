// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is the test for the private implementation of animated icons.
// To make the private API accessible from the test we do not import the 
// material material_animated_icons library, but instead, this test file is an
// implementation of that library, using some of the parts of the real
// material_animated_icons, this give the test access to the private APIs.
library material_animated_icons;

import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'dart:ui' as ui show Paint, Path, Canvas;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

part '../../lib/src/material_animated_icons/animated_icons.dart';
part '../../lib/src/material_animated_icons/animated_icons_data.dart';
part '../../lib/src/material_animated_icons/data/menu_arrow.g.dart';

void main () {
  group('Interpolate points', () {
    test('- single point', () {
      final List<Point<double>> points = const <Point<double>>[
        const Point<double>(25.0, 1.0),
      ];
      expect(_interpolate(points, 0.0, lerpDoublePoint), const Point<double>(25.0, 1.0));
      expect(_interpolate(points, 0.5, lerpDoublePoint), const Point<double>(25.0, 1.0));
      expect(_interpolate(points, 1.0, lerpDoublePoint), const Point<double>(25.0, 1.0));
    });

    test('- two points', () {
      final List<Point<double>> points = const <Point<double>>[
        const Point<double>(25.0, 1.0),
        const Point<double>(12.0, 12.0),
      ];
      expect(_interpolate(points, 0.0, lerpDoublePoint), const Point<double>(25.0, 1.0));
      expect(_interpolate(points, 0.5, lerpDoublePoint), const Point<double>(18.5, 6.5));
      expect(_interpolate(points, 1.0, lerpDoublePoint), const Point<double>(12.0, 12.0));
    });

    test('- three points', () {
      final List<Point<double>> points = const <Point<double>>[
        const Point<double>(25.0, 1.0),
        const Point<double>(12.0, 12.0),
        const Point<double>(23.0, 9.0),
      ];
      expect(_interpolate(points, 0.0, lerpDoublePoint), const Point<double>(25.0, 1.0));
      expect(_interpolate(points, 0.25, lerpDoublePoint), const Point<double>(18.5, 6.5));
      expect(_interpolate(points, 0.5, lerpDoublePoint), const Point<double>(12.0, 12.0));
      expect(_interpolate(points, 0.75, lerpDoublePoint), const Point<double>(17.5, 10.5));
      expect(_interpolate(points, 1.0, lerpDoublePoint), const Point<double>(23.0, 9.0));
    });
  });

  group('_AnimatedIconPainter', () {
    final Size size = const Size(48.0, 48.0);
    test('progress 0', () {
      final _AnimatedIconPainter painter = new
        _AnimatedIconPainter(movingBar.paths, 0.0, const Color(0xFF00FF00));
      expect(
        (Canvas canvas) {
          painter.paint(canvas, size);
        },
        paints
          ..path(
            includes: <Offset>[
              const Offset(0.0, 0.0),
              const Offset(48.0, 0.0),
              const Offset(48.0, 10.0),
              const Offset(0.0, 10.0),
            ],
            excludes: <Offset>[
              const Offset(24.0, 11.0),
            ],
            color: const Color(0xFF00FF00),
          )
      );
    });

    test('progress 1', () {
      final _AnimatedIconPainter painter = new
        _AnimatedIconPainter(movingBar.paths, 1.0, const Color(0xFF00FF00));
      expect(
        (Canvas canvas) {
          painter.paint(canvas, size);
        },
        paints
          ..path(
            includes: <Offset>[
              const Offset(0.0, 38.0),
              const Offset(48.0, 38.0),
              const Offset(48.0, 48.0),
              const Offset(0.0, 48.0),
            ],
            excludes: <Offset>[
              const Offset(24.0, 37.0),
            ],
            color: const Color(0x3300FF00),
          )
      );
    });

    test('interpolated frame', () {
      final _AnimatedIconPainter painter = new
        _AnimatedIconPainter(movingBar.paths, 0.5, const Color(0xFF00FF00));
      expect(
        (Canvas canvas) {
          painter.paint(canvas, size);
        },
        paints
          ..path(
            includes: <Offset>[
              const Offset(0.0, 19.0),
              const Offset(48.0, 19.0),
              const Offset(48.0, 29.0),
              const Offset(0.0, 29.0),
            ],
            excludes: <Offset>[
              const Offset(24.0, 37.0),
            ],
            color: const Color(0x9900FF00),
          )
      );
    });

    test('curved frame', () {
      final _AnimatedIconPainter painter = new
        _AnimatedIconPainter(bow.paths, 1.0, const Color(0xFFFF0000));
      expect(
        (Canvas canvas) {
          painter.paint(canvas, size);
        },
        paints
          ..path(
            includes: <Offset>[
              const Offset(0.0, 24.0),
              const Offset(48.0, 24.0),
              const Offset(24.0, 30.0),
            ],
            excludes: <Offset>[
              const Offset(48.0, 48.0),
            ],
            color: const Color(0xFFFF0000),
          )
      );
    });

  });
}

const _AnimatedIconData movingBar = const _AnimatedIconData(
  const Size(48.0, 48.0),
  const <_Path> [
    const _Path(
      opacities: const <double> [1.0, 0.2],
      commands: const <_PathCommand> [
        const _PathMoveTo(
          const <Point<double>> [
            const Point<double>(0.0, 0.0),
            const Point<double>(0.0, 38.0),
          ],
        ),
        const _PathLineTo(
          const <Point<double>> [
            const Point<double>(48.0, 0.0),
            const Point<double>(48.0, 38.0),
          ],
        ),
        const _PathLineTo(
          const <Point<double>> [
            const Point<double>(48.0, 10.0),
            const Point<double>(48.0, 48.0),
          ],
        ),
        const _PathLineTo(
          const <Point<double>> [
            const Point<double>(0.0, 10.0),
            const Point<double>(0.0, 48.0),
          ],
        ),
        const _PathLineTo(
          const <Point<double>> [
            const Point<double>(0.0, 00.0),
            const Point<double>(0.0, 38.0),
          ],
        ),
        const _PathClose(),
      ],
    ),
  ],
);

const _AnimatedIconData bow = const _AnimatedIconData(
  const Size(48.0, 48.0),
  const <_Path> [
    const _Path(
      opacities: const <double> [1.0, 1.0],
      commands: const <_PathCommand> [
        const _PathMoveTo(
          const <Point<double>> [
            const Point<double>(0.0, 24.0),
            const Point<double>(0.0, 24.0),
            const Point<double>(0.0, 24.0),
          ],
        ),
        const _PathCubicTo(
          const <Point<double>> [
            const Point<double>(16.0, 24.0),
            const Point<double>(16.0, 10.0),
            const Point<double>(16.0, 48.0),
          ],
          const <Point<double>> [
            const Point<double>(32.0, 24.0),
            const Point<double>(32.0, 10.0),
            const Point<double>(32.0, 48.0),
          ],
          const <Point<double>> [
            const Point<double>(48.0, 24.0),
            const Point<double>(48.0, 24.0),
            const Point<double>(48.0, 24.0),
          ],
        ),
        const _PathLineTo(
          const <Point<double>> [
            const Point<double>(0.0, 24.0),
            const Point<double>(0.0, 24.0),
            const Point<double>(0.0, 24.0),
          ],
        ),
        const _PathClose(),
      ],
    ),
  ],
);
