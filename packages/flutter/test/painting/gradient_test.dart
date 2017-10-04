// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

void main() {
  test('LinearGradient scale test', () {
    final LinearGradient testGradient = const LinearGradient(
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
    final LinearGradient testGradient1 = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomLeft,
      colors: const <Color>[
        const Color(0x33333333),
        const Color(0x66666666),
      ],
    );

    final LinearGradient testGradient2 = const LinearGradient(
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
        'LinearGradient(Alignment.topLeft, Alignment.bottomLeft, [Color(0x33333333), Color(0x66666666)], null, TileMode.clamp)',
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
}