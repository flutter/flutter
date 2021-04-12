// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LinearGradient scale test', () {
    const LinearGradient testGradient = LinearGradient(
      begin: Alignment.bottomRight,
      end: Alignment(0.7, 1.0),
      colors: <Color>[
        Color(0x00FFFFFF),
        Color(0x11777777),
        Color(0x44444444),
      ],
    );
    final LinearGradient? actual = LinearGradient.lerp(null, testGradient, 0.25);

    expect(actual, const LinearGradient(
      begin: Alignment.bottomRight,
      end: Alignment(0.7, 1.0),
      colors: <Color>[
        Color(0x00FFFFFF),
        Color(0x04777777),
        Color(0x11444444),
      ],
    ));
  });

  test('LinearGradient lerp test', () {
    const LinearGradient testGradient1 = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomLeft,
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
    );
    const LinearGradient testGradient2 = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.topLeft,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
    );

    final LinearGradient? actual = LinearGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.centerLeft,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
      stops: <double>[0, 1],
    ));
  });

  test('LinearGradient lerp test with stops', () {
    const LinearGradient testGradient1 = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomLeft,
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
      stops: <double>[
        0.0,
        0.5,
      ],
    );
    const LinearGradient testGradient2 = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.topLeft,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
      stops: <double>[
        0.5,
        1.0,
      ],
    );

    final LinearGradient? actual = LinearGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.centerLeft,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x55555555),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        0.5,
        1.0,
      ],
    ));
  });

  test('LinearGradient lerp test with unequal number of colors', () {
    const LinearGradient testGradient1 = LinearGradient(
      colors: <Color>[
        Color(0x22222222),
        Color(0x66666666),
      ],
    );
    const LinearGradient testGradient2 = LinearGradient(
      colors: <Color>[
        Color(0x44444444),
        Color(0x66666666),
        Color(0x88888888),
      ],
    );

    final LinearGradient? actual = LinearGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const LinearGradient(
      colors: <Color>[
        Color(0x33333333),
        Color(0x55555555),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        0.5,
        1.0,
      ],
    ));
  });

  test('LinearGradient lerp test with stops and unequal number of colors', () {
    const LinearGradient testGradient1 = LinearGradient(
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
      stops: <double>[
        0.0,
        0.5,
      ],
    );
    const LinearGradient testGradient2 = LinearGradient(
      colors: <Color>[
        Color(0x44444444),
        Color(0x48484848),
        Color(0x88888888),
      ],
      stops: <double>[
        0.5,
        0.7,
        1.0,
      ],
    );

    final LinearGradient? actual = LinearGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const LinearGradient(
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x55555555),
        Color(0x57575757),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        0.5,
        0.7,
        1.0,
      ],
    ));
  });

  test('LinearGradient toString', () {
    expect(
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomLeft,
        colors: <Color>[
          Color(0x33333333),
          Color(0x66666666),
        ],
      ).toString(),
      equals(
        'LinearGradient(Alignment.topLeft, Alignment.bottomLeft, [Color(0x33333333), Color(0x66666666)], null, TileMode.clamp)',
      ),
    );
  });

  test('LinearGradient with AlignmentDirectional', () {
    expect(
      () {
        return const LinearGradient(
          begin: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ],
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      throwsAssertionError,
    );
    expect(
      () {
        return const LinearGradient(
          begin: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ],
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.rtl);
      },
      returnsNormally,
    );
    expect(
      () {
        return const LinearGradient(
          begin: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ],
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.ltr);
      },
      returnsNormally,
    );
    expect(
      () {
        return const LinearGradient(
          begin: Alignment.topLeft,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ],
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      returnsNormally,
    );
  });

  test('RadialGradient with AlignmentDirectional', () {
    expect(
      () {
        return const RadialGradient(
          center: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ],
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      throwsAssertionError,
    );

    expect(
      () {
        return const RadialGradient(
          center: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ],
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.rtl);
      },
      returnsNormally,
    );
    expect(
      () {
        return const RadialGradient(
          center: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ],
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.ltr);
      },
      returnsNormally,
    );
    expect(
      () {
        return const RadialGradient(
          center: Alignment.topLeft,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ],
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      returnsNormally,
    );
  });

  test('RadialGradient lerp test', () {
    const RadialGradient testGradient1 = RadialGradient(
      center: Alignment.topLeft,
      radius: 20.0,
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
    );
    const RadialGradient testGradient2 = RadialGradient(
      center: Alignment.topRight,
      radius: 10.0,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
    );

    final RadialGradient? actual = RadialGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const RadialGradient(
      center: Alignment.topCenter,
      radius: 15.0,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        1.0,
      ],
    ));
  });

  test('RadialGradient lerp test with stops', () {
    const RadialGradient testGradient1 = RadialGradient(
      center: Alignment.topLeft,
      radius: 20.0,
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
      stops: <double>[
        0.0,
        0.5,
      ],
    );
    const RadialGradient testGradient2 = RadialGradient(
      center: Alignment.topRight,
      radius: 10.0,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
      stops: <double>[
        0.5,
        1.0,
      ],
    );

    final RadialGradient? actual = RadialGradient.lerp(testGradient1, testGradient2, 0.5);

    expect(actual, const RadialGradient(
      center: Alignment.topCenter,
      radius: 15.0,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x55555555),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        0.5,
        1.0,
      ],
    ));

    expect(actual!.focal, isNull);
  });

  test('RadialGradient lerp test with unequal number of colors', () {
    const RadialGradient testGradient1 = RadialGradient(
      colors: <Color>[
        Color(0x22222222),
        Color(0x66666666),
      ],
    );
    const RadialGradient testGradient2 = RadialGradient(
      colors: <Color>[
        Color(0x44444444),
        Color(0x66666666),
        Color(0x88888888),
      ],
    );

    final RadialGradient? actual = RadialGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const RadialGradient(
      colors: <Color>[
        Color(0x33333333),
        Color(0x55555555),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        0.5,
        1.0,
      ],
    ));
  });

  test('RadialGradient lerp test with stops and unequal number of colors', () {
    const RadialGradient testGradient1 = RadialGradient(
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
      stops: <double>[
        0.0,
        0.5,
      ],
    );
    const RadialGradient testGradient2 = RadialGradient(
      colors: <Color>[
        Color(0x44444444),
        Color(0x48484848),
        Color(0x88888888),
      ],
      stops: <double>[
        0.5,
        0.7,
        1.0,
      ],
    );

    final RadialGradient? actual = RadialGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const RadialGradient(
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x55555555),
        Color(0x57575757),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        0.5,
        0.7,
        1.0,
      ],
    ));
  });

  test('RadialGradient lerp test with focal', () {
    const RadialGradient testGradient1 = RadialGradient(
      center: Alignment.topLeft,
      focal: Alignment.centerLeft,
      radius: 20.0,
      focalRadius: 10.0,
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
    );
    const RadialGradient testGradient2 = RadialGradient(
      center: Alignment.topRight,
      focal: Alignment.centerRight,
      radius: 10.0,
      focalRadius: 5.0,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
    );
    const RadialGradient testGradient3 = RadialGradient(
      center: Alignment.topRight,
      radius: 10.0,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
    );

    final RadialGradient? actual = RadialGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const RadialGradient(
      center: Alignment.topCenter,
      focal: Alignment.center,
      radius: 15.0,
      focalRadius: 7.5,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        1.0,
      ],
    ));

    final RadialGradient? actual2 = RadialGradient.lerp(testGradient1, testGradient3, 0.5);
    expect(actual2, const RadialGradient(
      center: Alignment.topCenter,
      focal: Alignment(-0.5, 0.0),
      radius: 15.0,
      focalRadius: 5.0,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        1.0,
      ],
    ));
  });

  test('SweepGradient lerp test', () {
    const SweepGradient testGradient1 = SweepGradient(
      center: Alignment.topLeft,
      startAngle: 0.0,
      endAngle: math.pi / 2,
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
    );
    const SweepGradient testGradient2 = SweepGradient(
      center: Alignment.topRight,
      startAngle: math.pi / 2,
      endAngle: math.pi,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
    );

    final SweepGradient? actual = SweepGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const SweepGradient(
      center: Alignment.topCenter,
      startAngle: math.pi / 4,
      endAngle: math.pi * 3/4,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        1.0,
      ],
    ));
  });

  test('SweepGradient lerp test with stops', () {
    const SweepGradient testGradient1 = SweepGradient(
      center: Alignment.topLeft,
      startAngle: 0.0,
      endAngle: math.pi / 2,
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
      stops: <double>[
        0.0,
        0.5,
      ],
    );
    const SweepGradient testGradient2 = SweepGradient(
      center: Alignment.topRight,
      startAngle: math.pi / 2,
      endAngle:  math.pi,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
      stops: <double>[
        0.5,
        1.0,
      ],
    );

    final SweepGradient? actual = SweepGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const SweepGradient(
      center: Alignment.topCenter,
      startAngle: math.pi / 4,
      endAngle: math.pi * 3/4,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x55555555),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        0.5,
        1.0,
      ],
    ));
  });

  test('SweepGradient lerp test with unequal number of colors', () {
    const SweepGradient testGradient1 = SweepGradient(
      colors: <Color>[
        Color(0x22222222),
        Color(0x66666666),
      ],
    );
    const SweepGradient testGradient2 = SweepGradient(
      colors: <Color>[
        Color(0x44444444),
        Color(0x66666666),
        Color(0x88888888),
      ],
    );

    final SweepGradient? actual = SweepGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const SweepGradient(
      colors: <Color>[
        Color(0x33333333),
        Color(0x55555555),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        0.5,
        1.0,
      ],
    ));
  });

  test('SweepGradient lerp test with stops and unequal number of colors', () {
    const SweepGradient testGradient1 = SweepGradient(
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
      stops: <double>[
        0.0,
        0.5,
      ],
    );
    const SweepGradient testGradient2 = SweepGradient(
      colors: <Color>[
        Color(0x44444444),
        Color(0x48484848),
        Color(0x88888888),
      ],
      stops: <double>[
        0.5,
        0.7,
        1.0,
      ],
    );

    final SweepGradient? actual = SweepGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const SweepGradient(
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x55555555),
        Color(0x57575757),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        0.5,
        0.7,
        1.0,
      ],
    ));
  });

  test('SweepGradient scale test)', () {
    const SweepGradient testGradient = SweepGradient(
      center: Alignment.topLeft,
      startAngle: 0.0,
      endAngle: math.pi / 2,
      colors: <Color>[
        Color(0xff333333),
        Color(0xff666666),
      ],
    );

    final SweepGradient actual = testGradient.scale(0.5);

    expect(actual, const SweepGradient(
      center: Alignment.topLeft,
      startAngle: 0.0,
      endAngle: math.pi / 2,
      colors: <Color>[
        Color(0x80333333),
        Color(0x80666666),
      ],
    ));
  });

  test('Gradient lerp test (with RadialGradient)', () {
    const RadialGradient testGradient1 = RadialGradient(
      center: Alignment.topLeft,
      radius: 20.0,
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
      stops: <double>[
        0.0,
        1.0,
      ],
    );
    const RadialGradient testGradient2 = RadialGradient(
      center: Alignment.topCenter,
      radius: 15.0,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
      stops: <double>[
        0.0,
        1.0,
      ],
    );
    const RadialGradient testGradient3 = RadialGradient(
      center: Alignment.topRight,
      radius: 10.0,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
      stops: <double>[
        0.0,
        1.0,
      ],
    );

    expect(Gradient.lerp(testGradient1, testGradient3, 0.0), testGradient1);
    expect(Gradient.lerp(testGradient1, testGradient3, 0.5), testGradient2);
    expect(Gradient.lerp(testGradient1, testGradient3, 1.0), testGradient3);
    expect(Gradient.lerp(testGradient3, testGradient1, 0.0), testGradient3);
    expect(Gradient.lerp(testGradient3, testGradient1, 0.5), testGradient2);
    expect(Gradient.lerp(testGradient3, testGradient1, 1.0), testGradient1);
  });

  test('Gradient lerp test (LinearGradient to RadialGradient)', () {
    const LinearGradient testGradient1 = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color(0x33333333),
        Color(0x66666666),
      ],
    );
    const RadialGradient testGradient2 = RadialGradient(
      center: Alignment.center,
      radius: 20.0,
      colors: <Color>[
        Color(0x44444444),
        Color(0x88888888),
      ],
    );

    expect(Gradient.lerp(testGradient1, testGradient2, 0.0), testGradient1);
    expect(Gradient.lerp(testGradient1, testGradient2, 1.0), testGradient2);
    expect(Gradient.lerp(testGradient1, testGradient2, 0.5), testGradient2.scale(0.0));
  });

  test('Gradients can handle missing stops and report mismatched stops', () {
    const LinearGradient test1a = LinearGradient(
      colors: <Color>[
        Color(0x11111111),
        Color(0x22222222),
        Color(0x33333333),
      ],
    );
    const RadialGradient test1b = RadialGradient(
      colors: <Color>[
        Color(0x11111111),
        Color(0x22222222),
        Color(0x33333333),
      ],
    );
    const LinearGradient test2a = LinearGradient(
      colors: <Color>[
        Color(0x11111111),
        Color(0x22222222),
        Color(0x33333333),
      ],
      stops: <double>[0.0, 1.0],
    );
    const RadialGradient test2b = RadialGradient(
      colors: <Color>[
        Color(0x11111111),
        Color(0x22222222),
        Color(0x33333333),
      ],
      stops: <double>[0.0, 1.0],
    );
    const Rect rect = Rect.fromLTWH(1.0, 2.0, 3.0, 4.0);
    expect(test1a.createShader(rect), isNotNull);
    expect(test1b.createShader(rect), isNotNull);
    expect(() { test2a.createShader(rect); }, throwsArgumentError);
    expect(() { test2b.createShader(rect); }, throwsArgumentError);
  });

  group('Transforms', () {
    const List<Color> colors = <Color>[Color(0xFFFFFFFF), Color(0xFF000088)];
    const Rect rect = Rect.fromLTWH(0.0, 0.0, 300.0, 400.0);
    const List<Gradient> gradients45 = <Gradient>[
      LinearGradient(colors: colors, transform: GradientRotation(math.pi/4)),
      // A radial gradient won't be interesting to rotate unless the center is changed.
      RadialGradient(colors: colors, center: Alignment.topCenter, transform: GradientRotation(math.pi/4)),
      SweepGradient(colors: colors, transform: GradientRotation(math.pi/4)),
    ];
    const List<Gradient> gradients90 = <Gradient>[
      LinearGradient(colors: colors, transform: GradientRotation(math.pi/2)),
      // A radial gradient won't be interesting to rotate unless the center is changed.
      RadialGradient(colors: colors, center: Alignment.topCenter, transform: GradientRotation(math.pi/2)),
      SweepGradient(colors: colors, transform: GradientRotation(math.pi/2)),
    ];

    const Map<Type, String> gradientSnakeCase = <Type, String> {
      LinearGradient: 'linear_gradient',
      RadialGradient: 'radial_gradient',
      SweepGradient: 'sweep_gradient',
    };

    Future<void> runTest(WidgetTester tester, Gradient gradient, double degrees) async {
      final String goldenName = '${gradientSnakeCase[gradient.runtimeType]}_$degrees.png';
      final Shader shader = gradient.createShader(
        rect,
      );
      final Key painterKey = UniqueKey();
      await tester.pumpWidget(Center(
        child: SizedBox.fromSize(
          size: rect.size,
          child: RepaintBoundary(
            key: painterKey,
            child: CustomPaint(
              painter: GradientPainter(shader, rect)
            ),
          ),
        ),
      ));
      await expectLater(
        find.byKey(painterKey),
        matchesGoldenFile(goldenName),
      );
    }

    group('Gradients - 45 degrees', () {
      for (final Gradient gradient in gradients45) {
        testWidgets('$gradient', (WidgetTester tester) async {
          await runTest(tester, gradient, 45);
        }, skip: isBrowser); // https://github.com/flutter/flutter/issues/41389
      }
    });

    group('Gradients - 90 degrees', () {
      for (final Gradient gradient in gradients90) {
        testWidgets('$gradient', (WidgetTester tester) async {
          await runTest(tester, gradient, 90);
        }, skip: isBrowser); // https://github.com/flutter/flutter/issues/41389
      }
    });
  });
}

class GradientPainter extends CustomPainter {
  const GradientPainter(this.shader, this.rect);

  final Shader shader;
  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

}
