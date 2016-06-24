// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('toString control test', () {
    expect(Curves.linear, hasOneLineDescription);
    expect(new SawTooth(3), hasOneLineDescription);
    expect(new Interval(0.25, 0.75), hasOneLineDescription);
    expect(new Interval(0.25, 0.75, curve: Curves.ease), hasOneLineDescription);
  });

  test('Curve flipped control test', () {
    Curve ease = Curves.ease;
    Curve flippedEase = ease.flipped;
    expect(flippedEase.transform(0.0), lessThan(0.001));
    expect(flippedEase.transform(0.5), lessThan(ease.transform(0.5)));
    expect(flippedEase.transform(1.0), greaterThan(0.999));
    expect(flippedEase, hasOneLineDescription);
  });

  test('Step has a step', () {
    Curve step = new Step(0.25);
    expect(step.transform(0.0), 0.0);
    expect(step.transform(0.24), 0.0);
    expect(step.transform(0.25), 1.0);
    expect(step.transform(0.26), 1.0);
    expect(step.transform(1.0), 1.0);
  });
}
