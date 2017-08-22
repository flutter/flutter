// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class TestCanvas implements Canvas {
  final List<Invocation> invocations = <Invocation>[];

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

void main() {
  test('A Banner with a location of topLeft paints in the top left', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.ltr,
      location: BannerLocation.topLeft
    );

    final TestCanvas canvas = new TestCanvas();

    bannerPainter.paint(canvas, const Size(1000.0, 1000.0));

    final Invocation translateCommand = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #translate;
    });

    expect(translateCommand, isNotNull);
    expect(translateCommand.positionalArguments[0], lessThan(100.0));
    expect(translateCommand.positionalArguments[1], lessThan(100.0));

    final Invocation rotateCommand = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #rotate;
    });

    expect(rotateCommand, isNotNull);
    expect(rotateCommand.positionalArguments[0], equals(-math.PI / 4.0));
  });

  test('A Banner with a location of topRight paints in the top right', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.ltr,
      location: BannerLocation.topRight
    );

    final TestCanvas canvas = new TestCanvas();

    bannerPainter.paint(canvas, const Size(1000.0, 1000.0));

    final Invocation translateCommand = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #translate;
    });

    expect(translateCommand, isNotNull);
    expect(translateCommand.positionalArguments[0], greaterThan(900.0));
    expect(translateCommand.positionalArguments[1], lessThan(100.0));

    final Invocation rotateCommand = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #rotate;
    });

    expect(rotateCommand, isNotNull);
    expect(rotateCommand.positionalArguments[0], equals(math.PI / 4.0));
  });

  test('A Banner with a location of bottomLeft paints in the bottom left', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.ltr,
      location: BannerLocation.bottomLeft
    );

    final TestCanvas canvas = new TestCanvas();

    bannerPainter.paint(canvas, const Size(1000.0, 1000.0));

    final Invocation translateCommand = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #translate;
    });

    expect(translateCommand, isNotNull);
    expect(translateCommand.positionalArguments[0], lessThan(100.0));
    expect(translateCommand.positionalArguments[1], greaterThan(900.0));

    final Invocation rotateCommand = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #rotate;
    });

    expect(rotateCommand, isNotNull);
    expect(rotateCommand.positionalArguments[0], equals(math.PI / 4.0));
  });

  test('A Banner with a location of bottomRight paints in the bottom right', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.ltr,
      location: BannerLocation.bottomRight
    );

    final TestCanvas canvas = new TestCanvas();

    bannerPainter.paint(canvas, const Size(1000.0, 1000.0));

    final Invocation translateCommand = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #translate;
    });

    expect(translateCommand, isNotNull);
    expect(translateCommand.positionalArguments[0], greaterThan(900.0));
    expect(translateCommand.positionalArguments[1], greaterThan(900.0));

    final Invocation rotateCommand = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #rotate;
    });

    expect(rotateCommand, isNotNull);
    expect(rotateCommand.positionalArguments[0], equals(-math.PI / 4.0));
  });
}
