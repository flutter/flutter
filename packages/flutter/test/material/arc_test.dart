// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  test('MaterialPointArcTween control test', () {
    final MaterialPointArcTween a = new MaterialPointArcTween(
      begin: Offset.zero,
      end: const Offset(0.0, 10.0)
    );

    final MaterialPointArcTween b = new MaterialPointArcTween(
      begin: Offset.zero,
      end: const Offset(0.0, 10.0)
    );

    expect(a, hasOneLineDescription);
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('MaterialRectArcTween control test', () {
    final MaterialRectArcTween a = new MaterialRectArcTween(
      begin: new Rect.fromLTWH(0.0, 0.0, 10.0, 10.0),
      end: new Rect.fromLTWH(0.0, 10.0, 10.0, 10.0)
    );

    final MaterialRectArcTween b = new MaterialRectArcTween(
      begin: new Rect.fromLTWH(0.0, 0.0, 10.0, 10.0),
      end: new Rect.fromLTWH(0.0, 10.0, 10.0, 10.0)
    );
    expect(a, hasOneLineDescription);
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('on-axis MaterialPointArcTween', () {
    MaterialPointArcTween tween = new MaterialPointArcTween(
      begin: Offset.zero,
      end: const Offset(0.0, 10.0)
    );
    expect(tween.lerp(0.5), equals(const Offset(0.0, 5.0)));
    expect(tween, hasOneLineDescription);

    tween = new MaterialPointArcTween(
      begin: Offset.zero,
      end: const Offset(10.0, 0.0)
    );
    expect(tween.lerp(0.5), equals(const Offset(5.0, 0.0)));
  });

  test('on-axis MaterialRectArcTween', () {
    MaterialRectArcTween tween = new MaterialRectArcTween(
      begin: new Rect.fromLTWH(0.0, 0.0, 10.0, 10.0),
      end: new Rect.fromLTWH(0.0, 10.0, 10.0, 10.0)
    );
    expect(tween.lerp(0.5), equals(new Rect.fromLTWH(0.0, 5.0, 10.0, 10.0)));
    expect(tween, hasOneLineDescription);

    tween = new MaterialRectArcTween(
      begin: new Rect.fromLTWH(0.0, 0.0, 10.0, 10.0),
      end: new Rect.fromLTWH(10.0, 0.0, 10.0, 10.0)
    );
    expect(tween.lerp(0.5), equals(new Rect.fromLTWH(5.0, 0.0, 10.0, 10.0)));
  });

  test('MaterialPointArcTween', () {
    const Offset begin = const Offset(180.0, 110.0);
    const Offset end = const Offset(37.0, 250.0);

    MaterialPointArcTween tween = new MaterialPointArcTween(begin: begin, end: end);
    expect(tween.lerp(0.0), begin);
    expect(tween.lerp(0.25), within<Offset>(distance: 2.0, from: const Offset(126.0, 120.0)));
    expect(tween.lerp(0.75), within<Offset>(distance: 2.0, from: const Offset(48.0, 196.0)));
    expect(tween.lerp(1.0), end);

    tween = new MaterialPointArcTween(begin: end, end: begin);
    expect(tween.lerp(0.0), end);
    expect(tween.lerp(0.25), within<Offset>(distance: 2.0, from: const Offset(91.0, 239.0)));
    expect(tween.lerp(0.75), within<Offset>(distance: 2.0, from: const Offset(168.3, 163.8)));
    expect(tween.lerp(1.0), begin);
  });

  test('MaterialRectArcTween', () {
    final Rect begin = new Rect.fromLTRB(180.0, 100.0, 330.0, 200.0);
    final Rect end = new Rect.fromLTRB(32.0, 275.0, 132.0, 425.0);

    bool sameRect(Rect a, Rect b) {
      return (a.left - b.left).abs() < 2.0
        && (a.top - b.top).abs() < 2.0
        && (a.right - b.right).abs() < 2.0
        && (a.bottom - b.bottom).abs() < 2.0;
    }

    MaterialRectArcTween tween = new MaterialRectArcTween(begin: begin, end: end);
    expect(tween.lerp(0.0), begin);
    expect(sameRect(tween.lerp(0.25), new Rect.fromLTRB(120.0, 113.0, 259.0, 237.0)), isTrue);
    expect(sameRect(tween.lerp(0.75), new Rect.fromLTRB(42.3, 206.5, 153.5, 354.7)), isTrue);
    expect(tween.lerp(1.0), end);

    tween = new MaterialRectArcTween(begin: end, end: begin);
    expect(tween.lerp(0.0), end);
    expect(sameRect(tween.lerp(0.25), new Rect.fromLTRB(92.0, 262.0, 203.0, 388.0)), isTrue);
    expect(sameRect(tween.lerp(0.75), new Rect.fromLTRB(169.7, 168.5, 308.5, 270.3)), isTrue);
    expect(tween.lerp(1.0), begin);
  });

}
