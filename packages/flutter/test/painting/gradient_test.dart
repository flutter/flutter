// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

void main() {
  test('LinearGradient scale test', () {
    const LinearGradient testGradient = const LinearGradient(
      begin: Alignment.bottomRight,
      end: const Alignment(0.7, 1.0),
      colors: const <Color>[
        const Color(0x00FFFFFF),
        const Color(0x11777777),
        const Color(0x44444444),
      ],
    );
    final LinearGradient actual = LinearGradient.lerp(null, testGradient, 0.25);

    expect(actual, const LinearGradient(
      begin: Alignment.bottomRight,
      end: const Alignment(0.7, 1.0),
      colors: const <Color>[
        const Color(0x00FFFFFF),
        const Color(0x04777777),
        const Color(0x11444444),
      ],
    ));
  });

  test('LinearGradient lerp test', () {
    const LinearGradient testGradient1 = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomLeft,
      colors: const <Color>[
        const Color(0x33333333),
        const Color(0x66666666),
      ],
    );
    const LinearGradient testGradient2 = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.topLeft,
      colors: const <Color>[
        const Color(0x44444444),
        const Color(0x88888888),
      ],
    );

    final LinearGradient actual = LinearGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const LinearGradient(
      begin: const Alignment(0.0, -1.0),
      end: const Alignment(-1.0, 0.0),
      colors: const <Color>[
        const Color(0x3B3B3B3B),
        const Color(0x77777777),
      ],
    ));
  });

  test('LinearGradient toString', () {
    expect(
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomLeft,
        colors: const <Color>[
          const Color(0x33333333),
          const Color(0x66666666),
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
          colors: const <Color>[ const Color(0xFFFFFFFF), const Color(0xFFFFFFFF) ]
        ).createShader(new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      throwsAssertionError,
    );
    expect(
      () {
        return const LinearGradient(
          begin: AlignmentDirectional.topStart,
          colors: const <Color>[ const Color(0xFFFFFFFF), const Color(0xFFFFFFFF) ]
        ).createShader(new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.rtl);
      },
      returnsNormally,
    );
    expect(
      () {
        return const LinearGradient(
          begin: AlignmentDirectional.topStart,
          colors: const <Color>[ const Color(0xFFFFFFFF), const Color(0xFFFFFFFF) ]
        ).createShader(new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.ltr);
      },
      returnsNormally,
    );
    expect(
      () {
        return const LinearGradient(
          begin: Alignment.topLeft,
          colors: const <Color>[ const Color(0xFFFFFFFF), const Color(0xFFFFFFFF) ]
        ).createShader(new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      returnsNormally,
    );
  });

  test('RadialGradient with AlignmentDirectional', () {
    expect(
      () {
        return const RadialGradient(
          center: AlignmentDirectional.topStart,
          colors: const <Color>[ const Color(0xFFFFFFFF), const Color(0xFFFFFFFF) ]
        ).createShader(new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      throwsAssertionError,
    );
    expect(
      () {
        return const RadialGradient(
          center: AlignmentDirectional.topStart,
          colors: const <Color>[ const Color(0xFFFFFFFF), const Color(0xFFFFFFFF) ]
        ).createShader(new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.rtl);
      },
      returnsNormally,
    );
    expect(
      () {
        return const RadialGradient(
          center: AlignmentDirectional.topStart,
          colors: const <Color>[ const Color(0xFFFFFFFF), const Color(0xFFFFFFFF) ]
        ).createShader(new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0), textDirection: TextDirection.ltr);
      },
      returnsNormally,
    );
    expect(
      () {
        return const RadialGradient(
          center: Alignment.topLeft,
          colors: const <Color>[ const Color(0xFFFFFFFF), const Color(0xFFFFFFFF) ]
        ).createShader(new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0));
      },
      returnsNormally,
    );
  });

  test('RadialGradient lerp test', () {
    const RadialGradient testGradient1 = const RadialGradient(
      center: Alignment.topLeft,
      radius: 20.0,
      colors: const <Color>[
        const Color(0x33333333),
        const Color(0x66666666),
      ],
    );
    const RadialGradient testGradient2 = const RadialGradient(
      center: Alignment.topRight,
      radius: 10.0,
      colors: const <Color>[
        const Color(0x44444444),
        const Color(0x88888888),
      ],
    );

    final RadialGradient actual = RadialGradient.lerp(testGradient1, testGradient2, 0.5);
    expect(actual, const RadialGradient(
      center: const Alignment(0.0, -1.0),
      radius: 15.0,
      colors: const <Color>[
        const Color(0x3B3B3B3B),
        const Color(0x77777777),
      ],
    ));
  });

  test('Gradient lerp test (with RadialGradient)', () {
    const RadialGradient testGradient1 = const RadialGradient(
      center: Alignment.topLeft,
      radius: 20.0,
      colors: const <Color>[
        const Color(0x33333333),
        const Color(0x66666666),
      ],
    );
    const RadialGradient testGradient2 = const RadialGradient(
      center: const Alignment(0.0, -1.0),
      radius: 15.0,
      colors: const <Color>[
        const Color(0x3B3B3B3B),
        const Color(0x77777777),
      ],
    );
    const RadialGradient testGradient3 = const RadialGradient(
      center: Alignment.topRight,
      radius: 10.0,
      colors: const <Color>[
        const Color(0x44444444),
        const Color(0x88888888),
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
    const LinearGradient testGradient1 = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const <Color>[
        const Color(0x33333333),
        const Color(0x66666666),
      ],
    );
    const RadialGradient testGradient2 = const RadialGradient(
      center: Alignment.center,
      radius: 20.0,
      colors: const <Color>[
        const Color(0x44444444),
        const Color(0x88888888),
      ],
    );

    expect(Gradient.lerp(testGradient1, testGradient2, 0.0), testGradient1);
    expect(Gradient.lerp(testGradient1, testGradient2, 1.0), testGradient2);
    expect(Gradient.lerp(testGradient1, testGradient2, 0.5), testGradient2.scale(0.0));
  });

  test('Gradients can handle missing stops and report mismatched stops', () {
    const LinearGradient test1a = const LinearGradient(
      colors: const <Color>[
        const Color(0x11111111),
        const Color(0x22222222),
        const Color(0x33333333),
      ],
    );
    const RadialGradient test1b = const RadialGradient(
      colors: const <Color>[
        const Color(0x11111111),
        const Color(0x22222222),
        const Color(0x33333333),
      ],
    );
    const LinearGradient test2a = const LinearGradient(
      colors: const <Color>[
        const Color(0x11111111),
        const Color(0x22222222),
        const Color(0x33333333),
      ],
      stops: const <double>[0.0, 1.0],
    );
    const RadialGradient test2b = const RadialGradient(
      colors: const <Color>[
        const Color(0x11111111),
        const Color(0x22222222),
        const Color(0x33333333),
      ],
      stops: const <double>[0.0, 1.0],
    );
    final Rect rect = new Rect.fromLTWH(1.0, 2.0, 3.0, 4.0);
    expect(test1a.createShader(rect), isNotNull);
    expect(test1b.createShader(rect), isNotNull);
    expect(() { test2a.createShader(rect); }, throwsArgumentError);
    expect(() { test2b.createShader(rect); }, throwsArgumentError);
  });
}