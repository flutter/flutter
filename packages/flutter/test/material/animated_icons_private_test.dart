// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

// This is the test for the private implementation of animated icons.
// To make the private API accessible from the test we do not import the
// material material_animated_icons library, but instead, this test file is an
// implementation of that library, using some of the parts of the real
// material_animated_icons, this give the test access to the private APIs.
library material_animated_icons;

import 'dart:math' as math show pi;
import 'dart:ui' show lerpDouble;
import 'dart:ui' as ui show Paint, Path, Canvas;

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import '../flutter_test_alternative.dart';

part 'package:flutter/src/material/animated_icons/animated_icons.dart';
part 'package:flutter/src/material/animated_icons/animated_icons_data.dart';

// We have to import all the generated files in the material library to avoid
// analysis errors (as the generated constants are all referenced in the
// animated_icons library).
part 'package:flutter/src/material/animated_icons/data/add_event.g.dart';
part 'package:flutter/src/material/animated_icons/data/arrow_menu.g.dart';
part 'package:flutter/src/material/animated_icons/data/close_menu.g.dart';
part 'package:flutter/src/material/animated_icons/data/ellipsis_search.g.dart';
part 'package:flutter/src/material/animated_icons/data/event_add.g.dart';
part 'package:flutter/src/material/animated_icons/data/home_menu.g.dart';
part 'package:flutter/src/material/animated_icons/data/list_view.g.dart';
part 'package:flutter/src/material/animated_icons/data/menu_arrow.g.dart';
part 'package:flutter/src/material/animated_icons/data/menu_close.g.dart';
part 'package:flutter/src/material/animated_icons/data/menu_home.g.dart';
part 'package:flutter/src/material/animated_icons/data/pause_play.g.dart';
part 'package:flutter/src/material/animated_icons/data/play_pause.g.dart';
part 'package:flutter/src/material/animated_icons/data/search_ellipsis.g.dart';
part 'package:flutter/src/material/animated_icons/data/view_list.g.dart';

class MockCanvas extends Mock implements ui.Canvas {}
class MockPath extends Mock implements ui.Path {}

void main () {
  group('Interpolate points', () {
    test('- single point', () {
      const List<Offset> points = <Offset>[
        Offset(25.0, 1.0),
      ];
      expect(_interpolate(points, 0.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(_interpolate(points, 0.5, Offset.lerp), const Offset(25.0, 1.0));
      expect(_interpolate(points, 1.0, Offset.lerp), const Offset(25.0, 1.0));
    });

    test('- two points', () {
      const List<Offset> points = <Offset>[
        Offset(25.0, 1.0),
        Offset(12.0, 12.0),
      ];
      expect(_interpolate(points, 0.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(_interpolate(points, 0.5, Offset.lerp), const Offset(18.5, 6.5));
      expect(_interpolate(points, 1.0, Offset.lerp), const Offset(12.0, 12.0));
    });

    test('- three points', () {
      const List<Offset> points = <Offset>[
        Offset(25.0, 1.0),
        Offset(12.0, 12.0),
        Offset(23.0, 9.0),
      ];
      expect(_interpolate(points, 0.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(_interpolate(points, 0.25, Offset.lerp), const Offset(18.5, 6.5));
      expect(_interpolate(points, 0.5, Offset.lerp), const Offset(12.0, 12.0));
      expect(_interpolate(points, 0.75, Offset.lerp), const Offset(17.5, 10.5));
      expect(_interpolate(points, 1.0, Offset.lerp), const Offset(23.0, 9.0));
    });
  });

  group('_AnimatedIconPainter', () {
    const Size size = Size(48.0, 48.0);
    final MockCanvas mockCanvas = MockCanvas();
    List<MockPath> generatedPaths;
    final _UiPathFactory pathFactory = () {
      final MockPath path = MockPath();
      generatedPaths.add(path);
      return path;
    };

    setUp(() {
      generatedPaths = <MockPath> [];
    });

    test('progress 0', () {
      final _AnimatedIconPainter painter = _AnimatedIconPainter(
        paths: movingBar.paths,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<void>[
        generatedPaths[0].moveTo(0.0, 0.0),
        generatedPaths[0].lineTo(48.0, 0.0),
        generatedPaths[0].lineTo(48.0, 10.0),
        generatedPaths[0].lineTo(0.0, 10.0),
        generatedPaths[0].lineTo(0.0, 0.0),
        generatedPaths[0].close(),
      ]);
    });

    test('progress 1', () {
      final _AnimatedIconPainter painter = _AnimatedIconPainter(
        paths: movingBar.paths,
        progress: const AlwaysStoppedAnimation<double>(1.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<void>[
        generatedPaths[0].moveTo(0.0, 38.0),
        generatedPaths[0].lineTo(48.0, 38.0),
        generatedPaths[0].lineTo(48.0, 48.0),
        generatedPaths[0].lineTo(0.0, 48.0),
        generatedPaths[0].lineTo(0.0, 38.0),
        generatedPaths[0].close(),
      ]);
    });

    test('clamped progress', () {
      final _AnimatedIconPainter painter = _AnimatedIconPainter(
        paths: movingBar.paths,
        progress: const AlwaysStoppedAnimation<double>(1.5),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<void>[
        generatedPaths[0].moveTo(0.0, 38.0),
        generatedPaths[0].lineTo(48.0, 38.0),
        generatedPaths[0].lineTo(48.0, 48.0),
        generatedPaths[0].lineTo(0.0, 48.0),
        generatedPaths[0].lineTo(0.0, 38.0),
        generatedPaths[0].close(),
      ]);
    });

    test('scale', () {
      final _AnimatedIconPainter painter = _AnimatedIconPainter(
        paths: movingBar.paths,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 0.5,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      verify(mockCanvas.scale(0.5, 0.5));
    });

    test('mirror', () {
      final _AnimatedIconPainter painter = _AnimatedIconPainter(
        paths: movingBar.paths,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: true,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      verifyInOrder(<void>[
        mockCanvas.rotate(math.pi),
        mockCanvas.translate(-48.0, -48.0),
      ]);
    });

    test('interpolated frame', () {
      final _AnimatedIconPainter painter = _AnimatedIconPainter(
        paths: movingBar.paths,
        progress: const AlwaysStoppedAnimation<double>(0.5),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<void>[
        generatedPaths[0].moveTo(0.0, 19.0),
        generatedPaths[0].lineTo(48.0, 19.0),
        generatedPaths[0].lineTo(48.0, 29.0),
        generatedPaths[0].lineTo(0.0, 29.0),
        generatedPaths[0].lineTo(0.0, 19.0),
        generatedPaths[0].close(),
      ]);
    });

    test('curved frame', () {
      final _AnimatedIconPainter painter = _AnimatedIconPainter(
        paths: bow.paths,
        progress: const AlwaysStoppedAnimation<double>(1.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<void>[
        generatedPaths[0].moveTo(0.0, 24.0),
        generatedPaths[0].cubicTo(16.0, 48.0, 32.0, 48.0, 48.0, 24.0),
        generatedPaths[0].lineTo(0.0, 24.0),
        generatedPaths[0].close(),
      ]);
    });

    test('interpolated curved frame', () {
      final _AnimatedIconPainter painter = _AnimatedIconPainter(
        paths: bow.paths,
        progress: const AlwaysStoppedAnimation<double>(0.25),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<void>[
        generatedPaths[0].moveTo(0.0, 24.0),
        generatedPaths[0].cubicTo(16.0, 17.0, 32.0, 17.0, 48.0, 24.0),
        generatedPaths[0].lineTo(0.0, 24.0),
        generatedPaths[0].close(),
      ]);
    });

    test('should not repaint same values', () {
      final _AnimatedIconPainter painter1 = _AnimatedIconPainter(
        paths: bow.paths,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      final _AnimatedIconPainter painter2 = _AnimatedIconPainter(
        paths: bow.paths,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      expect(painter1.shouldRepaint(painter2), false);
    });

    test('should repaint on progress change', () {
      final _AnimatedIconPainter painter1 = _AnimatedIconPainter(
        paths: bow.paths,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      final _AnimatedIconPainter painter2 = _AnimatedIconPainter(
        paths: bow.paths,
        progress: const AlwaysStoppedAnimation<double>(0.1),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('should repaint on color change', () {
      final _AnimatedIconPainter painter1 = _AnimatedIconPainter(
        paths: bow.paths,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      final _AnimatedIconPainter painter2 = _AnimatedIconPainter(
        paths: bow.paths,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFFFF0000),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('should repaint on paths change', () {
      final _AnimatedIconPainter painter1 = _AnimatedIconPainter(
        paths: bow.paths,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF0000FF),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      final _AnimatedIconPainter painter2 = _AnimatedIconPainter(
        paths: const <_PathFrames> [],
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF0000FF),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

  });
}

const _AnimatedIconData movingBar = _AnimatedIconData(
  Size(48.0, 48.0),
  <_PathFrames> [
    _PathFrames(
      opacities: <double> [1.0, 0.2],
      commands: <_PathCommand> [
        _PathMoveTo(
          <Offset> [
            Offset(0.0, 0.0),
            Offset(0.0, 38.0),
          ],
        ),
        _PathLineTo(
          <Offset> [
            Offset(48.0, 0.0),
            Offset(48.0, 38.0),
          ],
        ),
        _PathLineTo(
          <Offset> [
            Offset(48.0, 10.0),
            Offset(48.0, 48.0),
          ],
        ),
        _PathLineTo(
          <Offset> [
            Offset(0.0, 10.0),
            Offset(0.0, 48.0),
          ],
        ),
        _PathLineTo(
          <Offset> [
            Offset(0.0, 0.0),
            Offset(0.0, 38.0),
          ],
        ),
        _PathClose(),
      ],
    ),
  ],
);

const _AnimatedIconData bow = _AnimatedIconData(
  Size(48.0, 48.0),
  <_PathFrames> [
    _PathFrames(
      opacities: <double> [1.0, 1.0],
      commands: <_PathCommand> [
        _PathMoveTo(
          <Offset> [
            Offset(0.0, 24.0),
            Offset(0.0, 24.0),
            Offset(0.0, 24.0),
          ],
        ),
        _PathCubicTo(
          <Offset> [
            Offset(16.0, 24.0),
            Offset(16.0, 10.0),
            Offset(16.0, 48.0),
          ],
          <Offset> [
            Offset(32.0, 24.0),
            Offset(32.0, 10.0),
            Offset(32.0, 48.0),
          ],
          <Offset> [
            Offset(48.0, 24.0),
            Offset(48.0, 24.0),
            Offset(48.0, 24.0),
          ],
        ),
        _PathLineTo(
          <Offset> [
            Offset(0.0, 24.0),
            Offset(0.0, 24.0),
            Offset(0.0, 24.0),
          ],
        ),
        _PathClose(),
      ],
    ),
  ],
);
