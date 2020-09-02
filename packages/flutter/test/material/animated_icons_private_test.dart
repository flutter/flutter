// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math show pi;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/src/material/animated_icons.dart';
import 'package:flutter/widgets.dart';

import '../flutter_test_alternative.dart';

void main() {
  AnimatedIconPrivateTestHarness harness;

  setUp(() {
    harness = const AnimatedIconPrivateTestHarness();
  });

  tearDown(() {
    harness = null;
  });

  group('Interpolate points', () {
    test('- single point', () {
      const List<Offset> points = <Offset>[
        Offset(25.0, 1.0),
      ];
      expect(harness.interpolate(points, 0.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(harness.interpolate(points, 0.5, Offset.lerp), const Offset(25.0, 1.0));
      expect(harness.interpolate(points, 1.0, Offset.lerp), const Offset(25.0, 1.0));
    });

    test('- two points', () {
      const List<Offset> points = <Offset>[
        Offset(25.0, 1.0),
        Offset(12.0, 12.0),
      ];
      expect(harness.interpolate(points, 0.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(harness.interpolate(points, 0.5, Offset.lerp), const Offset(18.5, 6.5));
      expect(harness.interpolate(points, 1.0, Offset.lerp), const Offset(12.0, 12.0));
    });

    test('- three points', () {
      const List<Offset> points = <Offset>[
        Offset(25.0, 1.0),
        Offset(12.0, 12.0),
        Offset(23.0, 9.0),
      ];
      expect(harness.interpolate(points, 0.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(harness.interpolate(points, 0.25, Offset.lerp), const Offset(18.5, 6.5));
      expect(harness.interpolate(points, 0.5, Offset.lerp), const Offset(12.0, 12.0));
      expect(harness.interpolate(points, 0.75, Offset.lerp), const Offset(17.5, 10.5));
      expect(harness.interpolate(points, 1.0, Offset.lerp), const Offset(23.0, 9.0));
    });
  });

  group('AnimatedIconPainter', () {
    const Size size = Size(48.0, 48.0);
    MockPath mockPath;
    MockCanvas mockCanvas;
    List<MockPath> generatedPaths;
    _UiPathFactory pathFactory;

    setUp(() {
      generatedPaths = <MockPath>[];
      mockCanvas = MockCanvas();
      mockPath = MockPath();
      pathFactory = () {
        generatedPaths.add(mockPath);
        return mockPath;
      };
    });

    test('progress 0', () {
      final CustomPainter painter = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.movingBar,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      generatedPaths[0].verifyCallsInOrder(<MockCall>[
        MockCall('moveTo', <dynamic>[0.0, 0.0]),
        MockCall('lineTo', <dynamic>[48.0, 0.0]),
        MockCall('lineTo', <dynamic>[48.0, 10.0]),
        MockCall('lineTo', <dynamic>[0.0, 10.0]),
        MockCall('lineTo', <dynamic>[0.0, 0.0]),
        MockCall('close'),
      ]);
    });

    test('progress 1', () {
      final CustomPainter painter = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.movingBar,
        progress: const AlwaysStoppedAnimation<double>(1.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      generatedPaths[0].verifyCallsInOrder(<MockCall>[
        MockCall('moveTo', <dynamic>[0.0, 38.0]),
        MockCall('lineTo', <dynamic>[48.0, 38.0]),
        MockCall('lineTo', <dynamic>[48.0, 48.0]),
        MockCall('lineTo', <dynamic>[0.0, 48.0]),
        MockCall('lineTo', <dynamic>[0.0, 38.0]),
        MockCall('close'),
      ]);
    });

    test('clamped progress', () {
      final CustomPainter painter = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.movingBar,
        progress: const AlwaysStoppedAnimation<double>(1.5),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      generatedPaths[0].verifyCallsInOrder(<MockCall>[
        MockCall('moveTo', <dynamic>[0.0, 38.0]),
        MockCall('lineTo', <dynamic>[48.0, 38.0]),
        MockCall('lineTo', <dynamic>[48.0, 48.0]),
        MockCall('lineTo', <dynamic>[0.0, 48.0]),
        MockCall('lineTo', <dynamic>[0.0, 38.0]),
        MockCall('close'),
      ]);
    });

    test('scale', () {
      expect(mockCanvas._calls, isEmpty);
      final CustomPainter painter = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.movingBar,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 0.5,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      mockCanvas.verifyCallsInOrder(<MockCall>[
        MockCall('scale', <dynamic>[0.5, 0.5]),
        MockCall.any('drawPath'),
      ]);
    });

    test('mirror', () {
      final CustomPainter painter = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.movingBar,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: true,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      mockCanvas.verifyCallsInOrder(<MockCall>[
        MockCall('scale', <dynamic>[1.0, 1.0]),
        MockCall('rotate', <dynamic>[math.pi]),
        MockCall('translate', <dynamic>[-48.0, -48.0]),
        MockCall.any('drawPath'),
      ]);
    });

    test('interpolated frame', () {
      final CustomPainter painter = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.movingBar,
        progress: const AlwaysStoppedAnimation<double>(0.5),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      generatedPaths[0].verifyCallsInOrder(<MockCall>[
        MockCall('moveTo', <dynamic>[0.0, 19.0]),
        MockCall('lineTo', <dynamic>[48.0, 19.0]),
        MockCall('lineTo', <dynamic>[48.0, 29.0]),
        MockCall('lineTo', <dynamic>[0.0, 29.0]),
        MockCall('lineTo', <dynamic>[0.0, 19.0]),
        MockCall('close'),
      ]);
    });

    test('curved frame', () {
      final CustomPainter painter = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.bow,
        progress: const AlwaysStoppedAnimation<double>(1.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      generatedPaths[0].verifyCallsInOrder(<MockCall>[
        MockCall('moveTo', <dynamic>[0.0, 24.0]),
        MockCall('cubicTo', <dynamic>[16.0, 48.0, 32.0, 48.0, 48.0, 24.0]),
        MockCall('lineTo', <dynamic>[0.0, 24.0]),
        MockCall('close'),
      ]);
    });

    test('interpolated curved frame', () {
      final CustomPainter painter = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.bow,
        progress: const AlwaysStoppedAnimation<double>(0.25),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );
      painter.paint(mockCanvas, size);
      expect(generatedPaths.length, 1);

      generatedPaths[0].verifyCallsInOrder(<MockCall>[
        MockCall('moveTo', <dynamic>[0.0, 24.0]),
        MockCall('cubicTo', <dynamic>[16.0, 17.0, 32.0, 17.0, 48.0, 24.0]),
        MockCall('lineTo', <dynamic>[0.0, 24.0]),
        MockCall('close', <dynamic>[]),
      ]);
    });

    test('should not repaint same values', () {
      final CustomPainter painter1 = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.bow,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      final CustomPainter painter2 = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.bow,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      expect(painter1.shouldRepaint(painter2), false);
    });

    test('should repaint on progress change', () {
      final CustomPainter painter1 = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.bow,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      final CustomPainter painter2 = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.bow,
        progress: const AlwaysStoppedAnimation<double>(0.1),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('should repaint on color change', () {
      final CustomPainter painter1 = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.bow,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF00FF00),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      final CustomPainter painter2 = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.bow,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFFFF0000),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('should repaint on paths change', () {
      final CustomPainter painter1 = harness.createAnimatedIconPainter(
        paths: AnimatedIconPrivateTestHarness.bow,
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: const Color(0xFF0000FF),
        scale: 1.0,
        shouldMirror: false,
        uiPathFactory: pathFactory,
      );

      final CustomPainter painter2 = harness.createAnimatedIconPainter(
        paths: null,
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

typedef _UiPathFactory = ui.Path Function();

// Contains the data from an invocation used for collection of calls and for
// expectations in Mock class.
class MockCall {
  // Creates a mock call with optional positional arguments.
  MockCall(String memberName, [this.positionalArguments, this.acceptAny = false])
      : memberSymbol = Symbol(memberName);
  MockCall.fromSymbol(this.memberSymbol, [this.positionalArguments, this.acceptAny = false]);
  // Creates a mock call expectation that doesn't care about what the arguments were.
  MockCall.any(String memberName)
      : memberSymbol = Symbol(memberName),
        acceptAny = true,
        positionalArguments = null;

  final Symbol memberSymbol;
  String get memberName {
    final RegExp symbolMatch = RegExp(r'Symbol\("(?<name>.*)"\)');
    final RegExpMatch match = symbolMatch.firstMatch(memberSymbol.toString());
    assert(match != null);
    return match.namedGroup('name');
  }
  final List<dynamic> positionalArguments;
  final bool acceptAny;

  @override
  String toString() {
    return '$memberName(${positionalArguments?.join(', ') ?? ''})';
  }
}

// A very simplified version of a Mock class.
//
// Only verifies positional arguments, and only can verify calls in order.
class Mock {
  final List<MockCall> _calls = <MockCall>[];

  void addMockCall(Symbol symbol, [List<dynamic> args]) {
    _calls.add(MockCall.fromSymbol(symbol, args));
  }

  // Verify that the given calls happened in the order given.
  void verifyCallsInOrder(List<MockCall> expected) {
    int count = 0;
    expect(expected.length, equals(_calls.length),
        reason: 'Incorrect number of calls received. '
            'Expected ${expected.length} and received ${_calls.length}.\n'
            '  Calls Received: $_calls\n'
            '  Calls Expected: $expected');
    for (final MockCall call in _calls) {
      expect(call.memberSymbol, equals(expected[count].memberSymbol),
          reason: 'Unexpected call to ${call.memberName}, expected a call to '
              '${expected[count].memberName} instead.');
      if (call.positionalArguments != null && !expected[count].acceptAny) {
        int countArg = 0;
        for (final dynamic arg in call.positionalArguments) {
          expect(arg, equals(expected[count].positionalArguments[countArg]),
              reason: 'Failed at call $count. Positional argument $countArg to ${call.memberName} '
                  'not as expected. Expected ${expected[count].positionalArguments[countArg]} '
                  'and received $arg');
          countArg++;
        }
      }
      count++;
    }
  }

  @override
  void noSuchMethod(Invocation invocation) {
    addMockCall(invocation.memberName, invocation.positionalArguments);
  }
}

class MockCanvas extends Mock implements ui.Canvas {}

class MockPath extends Mock implements ui.Path {}
