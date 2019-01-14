// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

void main() {
  test('rect accessors', () {
    final Rect r = Rect.fromLTRB(1.0, 3.0, 5.0, 7.0);
    expect(r.left, equals(1.0));
    expect(r.top, equals(3.0));
    expect(r.right, equals(5.0));
    expect(r.bottom, equals(7.0));
  });

  test('rect created by width and height', () {
    final Rect r = Rect.fromLTWH(1.0, 3.0, 5.0, 7.0);
    expect(r.left, equals(1.0));
    expect(r.top, equals(3.0));
    expect(r.right, equals(6.0));
    expect(r.bottom, equals(10.0));
  });

  test('rect intersection', () {
    final Rect r1 = Rect.fromLTRB(0.0, 0.0, 100.0, 100.0);
    final Rect r2 = Rect.fromLTRB(50.0, 50.0, 200.0, 200.0);
    final Rect r3 = r1.intersect(r2);
    expect(r3.left, equals(50.0));
    expect(r3.top, equals(50.0));
    expect(r3.right, equals(100.0));
    expect(r3.bottom, equals(100.0));
    final Rect r4 = r2.intersect(r1);
    expect(r4, equals(r3));
  });
}
