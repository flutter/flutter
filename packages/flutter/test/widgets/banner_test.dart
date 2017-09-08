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
  test('A Banner with a location of topStart paints in the top left (LTR)', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.ltr,
      location: BannerLocation.topStart
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

  test('A Banner with a location of topStart paints in the top right (RTL)', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.rtl,
      location: BannerLocation.topStart,
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

  test('A Banner with a location of topEnd paints in the top right (LTR)', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.ltr,
      location: BannerLocation.topEnd
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

  test('A Banner with a location of topEnd paints in the top left (RTL)', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.rtl,
      location: BannerLocation.topEnd,
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

  test('A Banner with a location of bottomStart paints in the bottom left (LTR)', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.ltr,
      location: BannerLocation.bottomStart
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

  test('A Banner with a location of bottomStart paints in the bottom right (RTL)', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.rtl,
      location: BannerLocation.bottomStart,
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

  test('A Banner with a location of bottomEnd paints in the bottom right (LTR)', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.ltr,
      location: BannerLocation.bottomEnd
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

  test('A Banner with a location of bottomEnd paints in the bottom left (RTL)', () {
    final BannerPainter bannerPainter = new BannerPainter(
      message: 'foo',
      textDirection: TextDirection.rtl,
      location: BannerLocation.bottomEnd,
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

}
