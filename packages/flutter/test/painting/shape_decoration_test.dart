// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ShapeDecoration constructor', () {
    final Color colorR = const Color(0xffff0000);
    final Color colorG = const Color(0xff00ff00);
    final Gradient gradient = new LinearGradient(colors: <Color>[colorR, colorG]);
    expect(const ShapeDecoration(shape: const Border()), const ShapeDecoration(shape: const Border()));
    expect(() => new ShapeDecoration(color: colorR, gradient: gradient, shape: const Border()), throwsAssertionError);
    expect(() => new ShapeDecoration(color: colorR, shape: null), throwsAssertionError);
    expect(
      new ShapeDecoration.fromBoxDecoration(const BoxDecoration(shape: BoxShape.circle)),
      const ShapeDecoration(shape: const CircleBorder(BorderSide.none)),
    );
    expect(
      new ShapeDecoration.fromBoxDecoration(new BoxDecoration(shape: BoxShape.rectangle, borderRadius: new BorderRadiusDirectional.circular(100.0))),
      new ShapeDecoration(shape: new RoundedRectangleBorder(borderRadius: new BorderRadiusDirectional.circular(100.0))),
    );
    expect(
      new ShapeDecoration.fromBoxDecoration(new BoxDecoration(shape: BoxShape.circle, border: new Border.all(color: colorG))),
      new ShapeDecoration(shape: new CircleBorder(new BorderSide(color: colorG))),
    );
    expect(
      new ShapeDecoration.fromBoxDecoration(new BoxDecoration(shape: BoxShape.rectangle, border: new Border.all(color: colorR))),
      new ShapeDecoration(shape: new Border.all(color: colorR)),
    );
    expect(
      new ShapeDecoration.fromBoxDecoration(const BoxDecoration(shape: BoxShape.rectangle, border: const BorderDirectional(start: const BorderSide()))),
      const ShapeDecoration(shape: const BorderDirectional(start: const BorderSide())),
    );
  });

  test('ShapeDecoration.lerp and hit test', () {
    final Decoration a = const ShapeDecoration(shape: const CircleBorder());
    final Decoration b = const ShapeDecoration(shape: const RoundedRectangleBorder());
    expect(Decoration.lerp(a, b, 0.0), a);
    expect(Decoration.lerp(a, b, 1.0), b);
    const Size size = const Size(200.0, 100.0); // at t=0.5, width will be 150 (x=25 to x=175).
    expect(a.hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.1).hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.5).hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.9).hitTest(size, const Offset(20.0, 50.0)), isTrue);
    expect(b.hitTest(size, const Offset(20.0, 50.0)), isTrue);
  });
}
