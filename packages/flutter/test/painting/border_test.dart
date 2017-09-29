// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}