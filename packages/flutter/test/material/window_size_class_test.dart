// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WindowSizeClass.fromSize', () {
    expect(WindowSizeClass.fromSize(const Size(100, 1000)), WindowSizeClass.compact);
  });

  test('WindowsSizeClass.fromWidth', () {
    expect(WindowSizeClass.fromWidth(0), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(599), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(839), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
    expect(WindowSizeClass.fromWidth(1199), WindowSizeClass.expanded);
    expect(WindowSizeClass.fromWidth(1200), WindowSizeClass.large);
    expect(WindowSizeClass.fromWidth(1599), WindowSizeClass.large);
    expect(WindowSizeClass.fromWidth(1600), WindowSizeClass.extraLarge);
    expect(WindowSizeClass.fromWidth(5000), WindowSizeClass.extraLarge);
  });

  test('WindowSizeClass <', () {
    for (final WindowSizeClass windowSizeClass in WindowSizeClass.values) {
      for (final WindowSizeClass other in WindowSizeClass.values.takeWhile((WindowSizeClass other) => other != windowSizeClass)) {
        expect(windowSizeClass < other, false);
      }
      for (final WindowSizeClass other in WindowSizeClass.values.skipWhile((WindowSizeClass other) => other != windowSizeClass).skip(1)) {
        expect(windowSizeClass < other, true);
      }
    }
  });

  test('WindowSizeClass <=', () {
    for (final WindowSizeClass windowSizeClass in WindowSizeClass.values) {
      for (final WindowSizeClass other in WindowSizeClass.values.takeWhile((WindowSizeClass other) => other != windowSizeClass)) {
        expect(windowSizeClass <= other, false);
      }
      expect(windowSizeClass <= windowSizeClass, true);
      for (final WindowSizeClass other in WindowSizeClass.values.skipWhile((WindowSizeClass other) => other != windowSizeClass).skip(1)) {
        expect(windowSizeClass <= other, true);
      }
    }
  });

  test('WindowSizeClass >', () {
    for (final WindowSizeClass windowSizeClass in WindowSizeClass.values) {
      for (final WindowSizeClass other in WindowSizeClass.values.takeWhile((WindowSizeClass other) => other != windowSizeClass)) {
        expect(windowSizeClass > other, true);
      }
      expect(windowSizeClass > windowSizeClass, false);
      for (final WindowSizeClass other in WindowSizeClass.values.skipWhile((WindowSizeClass other) => other != windowSizeClass)) {
        expect(windowSizeClass > other, false);
      }
    }
  });

  test('WindowSizeClass >=', () {
    for (final WindowSizeClass windowSizeClass in WindowSizeClass.values) {
      for (final WindowSizeClass other in WindowSizeClass.values.takeWhile((WindowSizeClass other) => other != windowSizeClass)) {
        expect(windowSizeClass >= other, true);
      }
      expect(windowSizeClass >= windowSizeClass, true);
      for (final WindowSizeClass other in WindowSizeClass.values.skipWhile((WindowSizeClass other) => other != windowSizeClass).skip(1)) {
        expect(windowSizeClass >= other, false);
      }
    }
  });
}
