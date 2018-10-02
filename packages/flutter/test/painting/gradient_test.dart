// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

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
    final LinearGradient actual = LinearGradient.lerp(null, testGradient, 0.25);

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

    final LinearGradient actual = LinearGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const LinearGradient(
      begin: Alignment(0.0, -1.0),
      end: Alignment(-1.0, 0.0),
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
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

    final LinearGradient actual = LinearGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const LinearGradient(
      begin: Alignment(0.0, -1.0),
      end: Alignment(-1.0, 0.0),
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
      stops: <double>[
        0.25,
        0.75,
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
        'LinearGradient(topLeft, bottomLeft, [Color(0x33333333), Color(0x66666666)], null, TileMode.clamp)',
      ),
    );
  });

  test('LinearGradient with AlignmentDirectional', () {
    expect(
      () {
        return const LinearGradient(
          begin: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ]
        ).createShader(Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      throwsAssertionError,
    );
    expect(
      () {
        return const LinearGradient(
          begin: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ]
        ).createShader(Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.rtl);
      },
      returnsNormally,
    );
    expect(
      () {
        return const LinearGradient(
          begin: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ]
        ).createShader(Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.ltr);
      },
      returnsNormally,
    );
    expect(
      () {
        return const LinearGradient(
          begin: Alignment.topLeft,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ]
        ).createShader(Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      returnsNormally,
    );
  });

  test('RadialGradient with AlignmentDirectional', () {
    expect(
      () {
        return const RadialGradient(
          center: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ]
        ).createShader(Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      throwsAssertionError,
    );

    expect(
      () {
        return const RadialGradient(
          center: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ]
        ).createShader(Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.rtl);
      },
      returnsNormally,
    );
    expect(
      () {
        return const RadialGradient(
          center: AlignmentDirectional.topStart,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ]
        ).createShader(Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.ltr);
      },
      returnsNormally,
    );
    expect(
      () {
        return const RadialGradient(
          center: Alignment.topLeft,
          colors: <Color>[ Color(0xFFFFFFFF), Color(0xFFFFFFFF) ]
        ).createShader(Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
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

    final RadialGradient actual = RadialGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const RadialGradient(
      center: Alignment(0.0, -1.0),
      radius: 15.0,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
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

    final RadialGradient actual = RadialGradient.lerp(testGradient1, testGradient2, 0.5);

    expect(actual.focal, isNull);

    expect(actual, const RadialGradient(
      center: Alignment(0.0, -1.0),
      radius: 15.0,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
      stops: <double>[
        0.25,
        0.75,
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

    final RadialGradient actual = RadialGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const RadialGradient(
      center: Alignment(0.0, -1.0),
      focal: Alignment(0.0, 0.0),
      radius: 15.0,
      focalRadius: 7.5,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
    ));

    final RadialGradient actual2 = RadialGradient.lerp(testGradient1, testGradient3, 0.5);
    expect(actual2, const RadialGradient(
      center: Alignment(0.0, -1.0),
      focal: Alignment(-0.5, 0.0),
      radius: 15.0,
      focalRadius: 5.0,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
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

    final SweepGradient actual = SweepGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const SweepGradient(
      center: Alignment(0.0, -1.0),
      startAngle: math.pi / 4,
      endAngle: math.pi * 3/4,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
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

    final SweepGradient actual = SweepGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const SweepGradient(
      center: Alignment(0.0, -1.0),
      startAngle: math.pi / 4,
      endAngle: math.pi * 3/4,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
      ],
      stops: <double>[
        0.25,
        0.75,
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
    );
    const RadialGradient testGradient2 = RadialGradient(
      center: Alignment(0.0, -1.0),
      radius: 15.0,
      colors: <Color>[
        Color(0x3B3B3B3B),
        Color(0x77777777),
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
    final Rect rect = Rect.fromLTWH(1.0, 2.0, 3.0, 4.0);
    expect(test1a.createShader(rect), isNotNull);
    expect(test1b.createShader(rect), isNotNull);
    expect(() { test2a.createShader(rect); }, throwsArgumentError);
    expect(() { test2b.createShader(rect); }, throwsArgumentError);
  });
}
