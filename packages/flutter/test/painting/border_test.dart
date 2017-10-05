// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Border constructor', () {
    final Null $null = null;
    expect(() => new Border(left: $null), throwsAssertionError);
    expect(() => new Border(top: $null), throwsAssertionError);
    expect(() => new Border(right: $null), throwsAssertionError);
    expect(() => new Border(bottom: $null), throwsAssertionError);
  });

  test('Border.merge', () {
    final BorderSide magenta3 = const BorderSide(color: const Color(0xFFFF00FF), width: 3.0);
    final BorderSide magenta6 = const BorderSide(color: const Color(0xFFFF00FF), width: 6.0);
    final BorderSide yellow2 = const BorderSide(color: const Color(0xFFFFFF00), width: 2.0);
    final BorderSide yellowNone0 = const BorderSide(color: const Color(0xFFFFFF00), width: 0.0, style: BorderStyle.none);
    expect(
      Border.merge(
        new Border(top: yellow2),
        new Border(right: magenta3),
      ),
      new Border(top: yellow2, right: magenta3),
    );
    expect(
      Border.merge(
        new Border(bottom: magenta3),
        new Border(bottom: magenta3),
      ),
      new Border(bottom: magenta6),
    );
    expect(
      Border.merge(
        new Border(left: magenta3, right: yellowNone0),
        new Border(right: yellow2),
      ),
      new Border(left: magenta3, right: yellow2),
    );
    expect(
      Border.merge(const Border(), const Border()),
      const Border(),
    );
    expect(
      () => Border.merge(
        new Border(left: magenta3),
        new Border(left: yellow2),
      ),
      throwsAssertionError,
    );
  });

  test('Border.add', () {
    final BorderSide magenta3 = const BorderSide(color: const Color(0xFFFF00FF), width: 3.0);
    final BorderSide magenta6 = const BorderSide(color: const Color(0xFFFF00FF), width: 6.0);
    final BorderSide yellow2 = const BorderSide(color: const Color(0xFFFFFF00), width: 2.0);
    final BorderSide yellowNone0 = const BorderSide(color: const Color(0xFFFFFF00), width: 0.0, style: BorderStyle.none);
    expect(
      new Border(top: yellow2) + new Border(right: magenta3),
      new Border(top: yellow2, right: magenta3),
    );
    expect(
      new Border(bottom: magenta3) + new Border(bottom: magenta3),
      new Border(bottom: magenta6),
    );
    expect(
      new Border(left: magenta3, right: yellowNone0) + new Border(right: yellow2),
      new Border(left: magenta3, right: yellow2),
    );
    expect(
      const Border() + const Border(),
      const Border(),
    );
    expect(
      new Border(left: magenta3) + new Border(left: yellow2),
      isNot(const isInstanceOf<Border>()), // see shape_border_test.dart for better tests of this case
    );
    final Border b3 = new Border(top: magenta3);
    final Border b6 = new Border(top: magenta6);
    expect(b3 + b3, b6);
    final Border b0 = new Border(top: yellowNone0);
    final Border bZ = const Border();
    expect(b0 + b0, bZ);
    expect(bZ + bZ, bZ);
    expect(b0 + bZ, bZ);
    expect(bZ + b0, bZ);
  });

  test('Border.scale', () {
    final BorderSide magenta3 = const BorderSide(color: const Color(0xFFFF00FF), width: 3.0);
    final BorderSide magenta6 = const BorderSide(color: const Color(0xFFFF00FF), width: 6.0);
    final BorderSide yellow2 = const BorderSide(color: const Color(0xFFFFFF00), width: 2.0);
    final BorderSide yellowNone0 = const BorderSide(color: const Color(0xFFFFFF00), width: 0.0, style: BorderStyle.none);
    final Border b3 = new Border(left: magenta3);
    final Border b6 = new Border(left: magenta6);
    expect(b3.scale(2.0), b6);
    final Border bY0 = new Border(top: yellowNone0);
    expect(bY0.scale(3.0), bY0);
    final Border bY2 = new Border(top: yellow2);
    expect(bY2.scale(0.0), bY0);
  });

  test('Border.dimensions', () {
    expect(
      const Border(
        left: const BorderSide(width: 2.0),
        top: const BorderSide(width: 3.0),
        bottom: const BorderSide(width: 5.0),
        right: const BorderSide(width: 7.0),
      ).dimensions,
      const EdgeInsets.fromLTRB(2.0, 3.0, 7.0, 5.0),
    );
  });

  test('Border.isUniform', () {
    expect(
      const Border(
        left: const BorderSide(width: 3.0),
        top: const BorderSide(width: 3.0),
        right: const BorderSide(width: 3.0),
        bottom: const BorderSide(width: 3.1),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: const BorderSide(width: 3.0),
        top: const BorderSide(width: 3.0),
        right: const BorderSide(width: 3.0),
        bottom: const BorderSide(width: 3.0),
      ).isUniform,
      true,
    );
    expect(
      const Border(
        left: const BorderSide(color: const Color(0xFFFFFFFE)),
        top: const BorderSide(color: const Color(0xFFFFFFFF)),
        right: const BorderSide(color: const Color(0xFFFFFFFF)),
        bottom: const BorderSide(color: const Color(0xFFFFFFFF)),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: const BorderSide(color: const Color(0xFFFFFFFF)),
        top: const BorderSide(color: const Color(0xFFFFFFFF)),
        right: const BorderSide(color: const Color(0xFFFFFFFF)),
        bottom: const BorderSide(color: const Color(0xFFFFFFFF)),
      ).isUniform,
      true,
    );
    expect(
      const Border(
        left: const BorderSide(style: BorderStyle.none),
        top: const BorderSide(style: BorderStyle.none),
        right: const BorderSide(style: BorderStyle.none),
        bottom: const BorderSide(style: BorderStyle.solid, width: 0.0),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: const BorderSide(style: BorderStyle.none),
        top: const BorderSide(style: BorderStyle.none),
        right: const BorderSide(style: BorderStyle.none),
        bottom: const BorderSide(style: BorderStyle.solid, width: 0.0),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: const BorderSide(style: BorderStyle.none),
        top: const BorderSide(style: BorderStyle.none),
        right: const BorderSide(style: BorderStyle.none),
        bottom: BorderSide.none,
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: const BorderSide(style: BorderStyle.none, width: 0.0),
        top: const BorderSide(style: BorderStyle.none, width: 0.0),
        right: const BorderSide(style: BorderStyle.none, width: 0.0),
        bottom: BorderSide.none,
      ).isUniform,
      true,
    );
    expect(
      const Border().isUniform,
      true,
    );
  });

  test('Border.lerp', () {
    final Border visualWithTop10 = const Border(top: const BorderSide(width: 10.0));
    final Border atMinus100 = const Border(left: const BorderSide(width: 0.0), right: const BorderSide(width: 300.0));
    final Border at0 = const Border(left: const BorderSide(width: 100.0), right: const BorderSide(width: 200.0));
    final Border at25 = const Border(left: const BorderSide(width: 125.0), right: const BorderSide(width: 175.0));
    final Border at75 = const Border(left: const BorderSide(width: 175.0), right: const BorderSide(width: 125.0));
    final Border at100 = const Border(left: const BorderSide(width: 200.0), right: const BorderSide(width: 100.0));
    final Border at200 = const Border(left: const BorderSide(width: 300.0), right: const BorderSide(width: 0.0));

    expect(Border.lerp(null, null, -1.0), null);
    expect(Border.lerp(visualWithTop10, null, -1.0), const Border(top: const BorderSide(width: 20.0)));
    expect(Border.lerp(null, visualWithTop10, -1.0), const Border());
    expect(Border.lerp(at0, at100, -1.0), atMinus100);

    expect(Border.lerp(null, null, 0.0), null);
    expect(Border.lerp(visualWithTop10, null, 0.0), const Border(top: const BorderSide(width: 10.0)));
    expect(Border.lerp(null, visualWithTop10, 0.0), const Border());
    expect(Border.lerp(at0, at100, 0.0), at0);

    expect(Border.lerp(null, null, 0.25), null);
    expect(Border.lerp(visualWithTop10, null, 0.25), const Border(top: const BorderSide(width: 7.5)));
    expect(Border.lerp(null, visualWithTop10, 0.25), const Border(top: const BorderSide(width: 2.5)));
    expect(Border.lerp(at0, at100, 0.25), at25);

    expect(Border.lerp(null, null, 0.75), null);
    expect(Border.lerp(visualWithTop10, null, 0.75), const Border(top: const BorderSide(width: 2.5)));
    expect(Border.lerp(null, visualWithTop10, 0.75), const Border(top: const BorderSide(width: 7.5)));
    expect(Border.lerp(at0, at100, 0.75), at75);

    expect(Border.lerp(null, null, 1.0), null);
    expect(Border.lerp(visualWithTop10, null, 1.0), const Border());
    expect(Border.lerp(null, visualWithTop10, 1.0), const Border(top: const BorderSide(width: 10.0)));
    expect(Border.lerp(at0, at100, 1.0), at100);

    expect(Border.lerp(null, null, 2.0), null);
    expect(Border.lerp(visualWithTop10, null, 2.0), const Border());
    expect(Border.lerp(null, visualWithTop10, 2.0), const Border(top: const BorderSide(width: 20.0)));
    expect(Border.lerp(at0, at100, 2.0), at200);
  });
}