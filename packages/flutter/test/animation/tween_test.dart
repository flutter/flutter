// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('Can chain tweens', () {
    final Tween<double> tween = new Tween<double>(begin: 0.30, end: 0.50);
    expect(tween, hasOneLineDescription);
    final Animatable<double> chain = tween.chain(new Tween<double>(begin: 0.50, end: 1.0));
    final AnimationController controller = new AnimationController(
      vsync: const TestVSync(),
    );
    expect(chain.evaluate(controller), 0.40);
    expect(chain, hasOneLineDescription);
  });

  test('Can animated tweens', () {
    final Tween<double> tween = new Tween<double>(begin: 0.30, end: 0.50);
    final AnimationController controller = new AnimationController(
      vsync: const TestVSync(),
    );
    final Animation<double> animation = tween.animate(controller);
    controller.value = 0.50;
    expect(animation.value, 0.40);
    expect(animation, hasOneLineDescription);
    expect(animation.toStringDetails(), hasOneLineDescription);
  });

  test('SizeTween', () {
    final SizeTween tween = new SizeTween(begin: Size.zero, end: const Size(20.0, 30.0));
    expect(tween.lerp(0.5), equals(const Size(10.0, 15.0)));
    expect(tween, hasOneLineDescription);
  });

  test('IntTween', () {
    final IntTween tween = new IntTween(begin: 5, end: 9);
    expect(tween.lerp(0.5), 7);
    expect(tween.lerp(0.7), 8);
  });

  test('RectTween', () {
    final Rect a = new Rect.fromLTWH(5.0, 3.0, 7.0, 11.0);
    final Rect b = new Rect.fromLTWH(8.0, 12.0, 14.0, 18.0);
    final RectTween tween = new RectTween(begin: a, end: b);
    expect(tween.lerp(0.5), equals(Rect.lerp(a, b, 0.5)));
    expect(tween, hasOneLineDescription);
  });
}
