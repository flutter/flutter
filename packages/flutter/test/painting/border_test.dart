// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Border.uniform constructor', () {
    const BorderSide side = BorderSide();
    const Border border = Border.fromBorderSide(side);
    expect(border.left, same(side));
    expect(border.top, same(side));
    expect(border.right, same(side));
    expect(border.bottom, same(side));
  });

  test('Border.symmetric constructor', () {
    const BorderSide side1 = BorderSide(color: Color(0xFFFFFFFF));
    const BorderSide side2 = BorderSide();
    const Border border = Border.symmetric(vertical: side1, horizontal: side2);
    expect(border.left, same(side1));
    expect(border.top, same(side2));
    expect(border.right, same(side1));
    expect(border.bottom, same(side2));
  });

  test('Border.merge', () {
    const BorderSide magenta3 = BorderSide(color: Color(0xFFFF00FF), width: 3.0);
    const BorderSide magenta6 = BorderSide(color: Color(0xFFFF00FF), width: 6.0);
    const BorderSide yellow2 = BorderSide(color: Color(0xFFFFFF00), width: 2.0);
    const BorderSide yellowNone0 = BorderSide(color: Color(0xFFFFFF00), width: 0.0, style: BorderStyle.none);
    expect(
      Border.merge(
        const Border(top: yellow2),
        const Border(right: magenta3),
      ),
      const Border(top: yellow2, right: magenta3),
    );
    expect(
      Border.merge(
        const Border(bottom: magenta3),
        const Border(bottom: magenta3),
      ),
      const Border(bottom: magenta6),
    );
    expect(
      Border.merge(
        const Border(left: magenta3, right: yellowNone0),
        const Border(right: yellow2),
      ),
      const Border(left: magenta3, right: yellow2),
    );
    expect(
      Border.merge(const Border(), const Border()),
      const Border(),
    );
    expect(
      () => Border.merge(
        const Border(left: magenta3),
        const Border(left: yellow2),
      ),
      throwsAssertionError,
    );
  });

  test('Border.add', () {
    const BorderSide magenta3 = BorderSide(color: Color(0xFFFF00FF), width: 3.0);
    const BorderSide magenta6 = BorderSide(color: Color(0xFFFF00FF), width: 6.0);
    const BorderSide yellow2 = BorderSide(color: Color(0xFFFFFF00), width: 2.0);
    const BorderSide yellowNone0 = BorderSide(color: Color(0xFFFFFF00), width: 0.0, style: BorderStyle.none);
    expect(
      const Border(top: yellow2) + const Border(right: magenta3),
      const Border(top: yellow2, right: magenta3),
    );
    expect(
      const Border(bottom: magenta3) + const Border(bottom: magenta3),
      const Border(bottom: magenta6),
    );
    expect(
      const Border(left: magenta3, right: yellowNone0) + const Border(right: yellow2),
      const Border(left: magenta3, right: yellow2),
    );
    expect(
      const Border() + const Border(),
      const Border(),
    );
    expect(
      const Border(left: magenta3) + const Border(left: yellow2),
      isNot(isA<Border>()), // see shape_border_test.dart for better tests of this case
    );
    const Border b3 = Border(top: magenta3);
    const Border b6 = Border(top: magenta6);
    expect(b3 + b3, b6);
    const Border b0 = Border(top: yellowNone0);
    const Border bZ = Border();
    expect(b0 + b0, bZ);
    expect(bZ + bZ, bZ);
    expect(b0 + bZ, bZ);
    expect(bZ + b0, bZ);
  });

  test('Border.scale', () {
    const BorderSide magenta3 = BorderSide(color: Color(0xFFFF00FF), width: 3.0);
    const BorderSide magenta6 = BorderSide(color: Color(0xFFFF00FF), width: 6.0);
    const BorderSide yellow2 = BorderSide(color: Color(0xFFFFFF00), width: 2.0);
    const BorderSide yellowNone0 = BorderSide(color: Color(0xFFFFFF00), width: 0.0, style: BorderStyle.none);
    const Border b3 = Border(left: magenta3);
    const Border b6 = Border(left: magenta6);
    expect(b3.scale(2.0), b6);
    const Border bY0 = Border(top: yellowNone0);
    expect(bY0.scale(3.0), bY0);
    const Border bY2 = Border(top: yellow2);
    expect(bY2.scale(0.0), bY0);
  });

  test('Border.dimensions', () {
    expect(
      const Border(
        left: BorderSide(width: 2.0),
        top: BorderSide(width: 3.0),
        bottom: BorderSide(width: 5.0),
        right: BorderSide(width: 7.0),
      ).dimensions,
      const EdgeInsets.fromLTRB(2.0, 3.0, 7.0, 5.0),
    );
  });

  test('Border.isUniform', () {
    expect(
      const Border(
        left: BorderSide(width: 3.0),
        top: BorderSide(width: 3.0),
        right: BorderSide(width: 3.0),
        bottom: BorderSide(width: 3.1),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: BorderSide(width: 3.0),
        top: BorderSide(width: 3.0),
        right: BorderSide(width: 3.0),
        bottom: BorderSide(width: 3.0),
      ).isUniform,
      true,
    );
    expect(
      const Border(
        left: BorderSide(color: Color(0xFFFFFFFE)),
        top: BorderSide(color: Color(0xFFFFFFFF)),
        right: BorderSide(color: Color(0xFFFFFFFF)),
        bottom: BorderSide(color: Color(0xFFFFFFFF)),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: BorderSide(color: Color(0xFFFFFFFF)),
        top: BorderSide(color: Color(0xFFFFFFFF)),
        right: BorderSide(color: Color(0xFFFFFFFF)),
        bottom: BorderSide(color: Color(0xFFFFFFFF)),
      ).isUniform,
      true,
    );
    expect(
      const Border(
        left: BorderSide(style: BorderStyle.none),
        top: BorderSide(style: BorderStyle.none),
        right: BorderSide(style: BorderStyle.none),
        bottom: BorderSide(width: 0.0),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: BorderSide(style: BorderStyle.none),
        top: BorderSide(style: BorderStyle.none),
        right: BorderSide(style: BorderStyle.none),
        bottom: BorderSide(width: 0.0),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: BorderSide(style: BorderStyle.none),
        top: BorderSide(style: BorderStyle.none),
        right: BorderSide(style: BorderStyle.none),
      ).isUniform,
      false,
    );
    expect(
      const Border().isUniform,
      true,
    );
    expect(
      const Border().isUniform,
      true,
    );
  });

  test('Border.lerp', () {
    const Border visualWithTop10 = Border(top: BorderSide(width: 10.0));
    const Border atMinus100 = Border(left: BorderSide(width: 0.0), right: BorderSide(width: 300.0));
    const Border at0 = Border(left: BorderSide(width: 100.0), right: BorderSide(width: 200.0));
    const Border at25 = Border(left: BorderSide(width: 125.0), right: BorderSide(width: 175.0));
    const Border at75 = Border(left: BorderSide(width: 175.0), right: BorderSide(width: 125.0));
    const Border at100 = Border(left: BorderSide(width: 200.0), right: BorderSide(width: 100.0));
    const Border at200 = Border(left: BorderSide(width: 300.0), right: BorderSide(width: 0.0));

    expect(Border.lerp(null, null, -1.0), null);
    expect(Border.lerp(visualWithTop10, null, -1.0), const Border(top: BorderSide(width: 20.0)));
    expect(Border.lerp(null, visualWithTop10, -1.0), const Border());
    expect(Border.lerp(at0, at100, -1.0), atMinus100);

    expect(Border.lerp(null, null, 0.0), null);
    expect(Border.lerp(visualWithTop10, null, 0.0), const Border(top: BorderSide(width: 10.0)));
    expect(Border.lerp(null, visualWithTop10, 0.0), const Border());
    expect(Border.lerp(at0, at100, 0.0), at0);

    expect(Border.lerp(null, null, 0.25), null);
    expect(Border.lerp(visualWithTop10, null, 0.25), const Border(top: BorderSide(width: 7.5)));
    expect(Border.lerp(null, visualWithTop10, 0.25), const Border(top: BorderSide(width: 2.5)));
    expect(Border.lerp(at0, at100, 0.25), at25);

    expect(Border.lerp(null, null, 0.75), null);
    expect(Border.lerp(visualWithTop10, null, 0.75), const Border(top: BorderSide(width: 2.5)));
    expect(Border.lerp(null, visualWithTop10, 0.75), const Border(top: BorderSide(width: 7.5)));
    expect(Border.lerp(at0, at100, 0.75), at75);

    expect(Border.lerp(null, null, 1.0), null);
    expect(Border.lerp(visualWithTop10, null, 1.0), const Border());
    expect(Border.lerp(null, visualWithTop10, 1.0), const Border(top: BorderSide(width: 10.0)));
    expect(Border.lerp(at0, at100, 1.0), at100);

    expect(Border.lerp(null, null, 2.0), null);
    expect(Border.lerp(visualWithTop10, null, 2.0), const Border());
    expect(Border.lerp(null, visualWithTop10, 2.0), const Border(top: BorderSide(width: 20.0)));
    expect(Border.lerp(at0, at100, 2.0), at200);
  });
}
