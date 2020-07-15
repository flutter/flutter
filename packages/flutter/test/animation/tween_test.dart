// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('Can chain tweens', () {
    final Tween<double> tween = Tween<double>(begin: 0.30, end: 0.50);
    expect(tween, hasOneLineDescription);
    final Animatable<double> chain = tween.chain(Tween<double>(begin: 0.50, end: 1.0));
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );
    expect(chain.evaluate(controller), 0.40);
    expect(chain, hasOneLineDescription);
  });

  test('Can animate tweens', () {
    final Tween<double> tween = Tween<double>(begin: 0.30, end: 0.50);
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );
    final Animation<double> animation = tween.animate(controller);
    controller.value = 0.50;
    expect(animation.value, 0.40);
    expect(animation, hasOneLineDescription);
    expect(animation.toStringDetails(), hasOneLineDescription);
  });

  test('Can drive tweens', () {
    final Tween<double> tween = Tween<double>(begin: 0.30, end: 0.50);
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );
    final Animation<double> animation = controller.drive(tween);
    controller.value = 0.50;
    expect(animation.value, 0.40);
    expect(animation, hasOneLineDescription);
    expect(animation.toStringDetails(), hasOneLineDescription);
  });

  test('SizeTween', () {
    final SizeTween tween = SizeTween(begin: Size.zero, end: const Size(20.0, 30.0));
    expect(tween.lerp(0.5), equals(const Size(10.0, 15.0)));
    expect(tween, hasOneLineDescription);
  });

  test('IntTween', () {
    final IntTween tween = IntTween(begin: 5, end: 9);
    expect(tween.lerp(0.5), 7);
    expect(tween.lerp(0.7), 8);
  });

  test('RectTween', () {
    const Rect a = Rect.fromLTWH(5.0, 3.0, 7.0, 11.0);
    const Rect b = Rect.fromLTWH(8.0, 12.0, 14.0, 18.0);
    final RectTween tween = RectTween(begin: a, end: b);
    expect(tween.lerp(0.5), equals(Rect.lerp(a, b, 0.5)));
    expect(tween, hasOneLineDescription);
  });

  test('Matrix4Tween', () {
    final Matrix4 a = Matrix4.identity();
    final Matrix4 b = a.clone()..translate(6.0, -8.0, 0.0)..scale(0.5, 1.0, 5.0);
    final Matrix4Tween tween = Matrix4Tween(begin: a, end: b);
    expect(tween.lerp(0.0), equals(a));
    expect(tween.lerp(1.0), equals(b));
    expect(
      tween.lerp(0.5),
      equals(a.clone()..translate(3.0, -4.0, 0.0)..scale(0.75, 1.0, 3.0)),
    );
    final Matrix4 c = a.clone()..rotateZ(1.0);
    final Matrix4Tween rotationTween = Matrix4Tween(begin: a, end: c);
    expect(rotationTween.lerp(0.0), equals(a));
    expect(rotationTween.lerp(1.0), equals(c));
    expect(
      rotationTween.lerp(0.5).absoluteError(
        a.clone()..rotateZ(0.5)
      ),
      moreOrLessEquals(0.0),
    );
  }, skip: isWindows); // floating point math not quite deterministic on Windows?

  test('ConstantTween', () {
    final ConstantTween<double> tween = ConstantTween<double>(100.0);
    expect(tween.begin, 100.0);
    expect(tween.end, 100.0);
    expect(tween.lerp(0.0), 100.0);
    expect(tween.lerp(0.5), 100.0);
    expect(tween.lerp(1.0), 100.0);
  });
}
