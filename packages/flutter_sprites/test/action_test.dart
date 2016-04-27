// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_sprites/flutter_sprites.dart';
import 'package:test/test.dart';

const double epsilon = 0.01;

void main() {
  test("Actions - ActionTween", () {
    // Tween doubles.
    double doubleValue;
    ActionTween tween = new ActionTween((double a) => doubleValue = a, 0.0, 10.0, 60.0);

    tween.update(0.0);
    expect(doubleValue, closeTo(0.0, epsilon));

    tween.update(0.1);
    expect(doubleValue, closeTo(1.0, epsilon));

    tween.update(0.5);
    expect(doubleValue, closeTo(5.0, epsilon));

    tween.update(1.0);
    expect(doubleValue, closeTo(10.0, epsilon));

    tween.update(1.5);
    expect(doubleValue, closeTo(15.0, epsilon));

    tween.update(-0.5);
    expect(doubleValue, closeTo(-5.0, epsilon));

    // Tween Points.
    Point pointValue;
    tween = new ActionTween((Point a) => pointValue = a, Point.origin, new Point(10.0, 20.0), 60.0);

    tween.update(0.0);
    expect(pointValue.x, closeTo(0.0, epsilon));
    expect(pointValue.y, closeTo(0.0, epsilon));

    tween.update(0.1);
    expect(pointValue.x, closeTo(1.0, epsilon));
    expect(pointValue.y, closeTo(2.0, epsilon));

    tween.update(0.5);
    expect(pointValue.x, closeTo(5.0, epsilon));
    expect(pointValue.y, closeTo(10.0, epsilon));

    tween.update(1.0);
    expect(pointValue.x, closeTo(10.0, epsilon));
    expect(pointValue.y, closeTo(20.0, epsilon));

    tween.update(1.5);
    expect(pointValue.x, closeTo(15.0, epsilon));
    expect(pointValue.y, closeTo(30.0, epsilon));

    tween.update(-0.5);
    expect(pointValue.x, closeTo(-5.0, epsilon));
    expect(pointValue.y, closeTo(-10.0, epsilon));

    // Tween Colors.
    Color colorValue;
    tween = new ActionTween((Color a) => colorValue = a, const Color(0xff000000), const Color(0xffffffff), 60.0);

    tween.update(0.0);
    expect(colorValue, equals(const Color(0xff000000)));

    tween.update(0.5);
    expect(colorValue, equals(const Color(0xff7f7f7f)));

    tween.update(1.0);
    expect(colorValue, equals(const Color(0xffffffff)));

    tween.update(-0.5);
    expect(colorValue, equals(const Color(0xff000000)));

    tween.update(1.5);
    expect(colorValue, equals(const Color(0xffffffff)));

    // Tween Size.
    Size sizeValue;
    tween = new ActionTween((Size a) => sizeValue = a, Size.zero, const Size(200.0, 100.0), 60.0);

    tween.update(0.0);
    expect(sizeValue, equals(Size.zero));

    tween.update(1.0);
    expect(sizeValue, equals(const Size(200.0, 100.0)));

    tween.update(0.5);
    expect(sizeValue.width, closeTo(100.0, epsilon));
    expect(sizeValue.height, closeTo(50.0, epsilon));

    // Tween Rect.
    Rect rectValue;
    tween = new ActionTween(
      (Rect a) => rectValue = a,
      new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
      new Rect.fromLTWH(100.0, 100.0, 200.0, 200.0),
      60.0
    );

    tween.update(0.0);
    expect(rectValue, equals(new Rect.fromLTWH(0.0, 0.0, 100.0, 100.0)));

    tween.update(1.0);
    expect(rectValue, equals(new Rect.fromLTWH(100.0, 100.0, 200.0, 200.0)));

    tween.update(0.5);
    expect(rectValue.left, closeTo(50.0, epsilon));
    expect(rectValue.top, closeTo(50.0, epsilon));
    expect(rectValue.width, closeTo(150.0, epsilon));
    expect(rectValue.height, closeTo(150.0, epsilon));
  });

  test("Actions - ActionRepeat", () {
    double doubleValue;
    ActionTween tween = new ActionTween((double a) => doubleValue = a, 0.0, 1.0, 60.0);

    ActionRepeat repeat2x = new ActionRepeat(tween, 2);
    expect(repeat2x.duration, closeTo(120.0, epsilon));

    repeat2x.update(0.0);
    expect(doubleValue, closeTo(0.0, epsilon));

    repeat2x.update(0.25);
    expect(doubleValue, closeTo(0.5, epsilon));

    repeat2x.update(0.75);
    expect(doubleValue, closeTo(0.5, epsilon));

    repeat2x.update(1.0);
    expect(doubleValue, closeTo(1.0, epsilon));

    ActionRepeat repeat4x = new ActionRepeat(tween, 4);
    expect(repeat4x.duration, closeTo(240.0, epsilon));

    repeat4x.update(0.0);
    expect(doubleValue, closeTo(0.0, epsilon));

    repeat4x.update(0.125);
    expect(doubleValue, closeTo(0.5, epsilon));

    repeat4x.update(0.875);
    expect(doubleValue, closeTo(0.5, epsilon));

    repeat4x.update(1.0);
    expect(doubleValue, closeTo(1.0, epsilon));
  });

  test("Actions - ActionGroup", () {
    double value0;
    double value1;

    ActionTween tween0 = new ActionTween((double a) => value0 = a, 0.0, 1.0, 10.0);
    ActionTween tween1 = new ActionTween((double a) => value1 = a, 0.0, 1.0, 20.0);

    ActionGroup group = new ActionGroup([tween0, tween1]);
    expect(group.duration, closeTo(20.0, epsilon));

    group.update(0.0);
    expect(value0, closeTo(0.0, epsilon));
    expect(value1, closeTo(0.0, epsilon));

    group.update(0.5);
    expect(value0, closeTo(1.0, epsilon));
    expect(value1, closeTo(0.5, epsilon));

    group.update(1.0);
    expect(value0, closeTo(1.0, epsilon));
    expect(value1, closeTo(1.0, epsilon));
  });

  test("Actions - ActionSequence", () {
    double doubleValue;

    ActionTween tween0 = new ActionTween((double a) => doubleValue = a, 0.0, 1.0, 4.0);
    ActionTween tween1 = new ActionTween((double a) => doubleValue = a, 1.0, 0.0, 12.0);

    ActionSequence sequence = new ActionSequence([tween0, tween1]);
    expect(sequence.duration, closeTo(16.0, epsilon));

    sequence.update(0.0);
    expect(doubleValue, closeTo(0.0, epsilon));

    sequence.update(0.125);
    expect(doubleValue, closeTo(0.5, epsilon));

    sequence.update(0.25);
    expect(doubleValue, closeTo(1.0, epsilon));

    sequence.update(1.0);
    expect(doubleValue, closeTo(0.0, epsilon));
  });

  test("Actions - stepping", () {
    double doubleValue;

    ActionTween tween = new ActionTween((double a) => doubleValue = a, 0.0, 1.0, 60.0);

    tween.step(0.0);
    expect(doubleValue, closeTo(0.0, epsilon));

    tween.step(30.0);
    expect(doubleValue, closeTo(0.5, epsilon));

    tween.step(30.0);
    expect(doubleValue, closeTo(1.0, epsilon));
  });
}
