// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:test/test.dart';

class TestImage implements ui.Image {
  TestImage({ this.width, this.height });

  @override
  final int width;

  @override
  final int height;

  @override
  void dispose() { }
}

class TestCanvas implements Canvas {
  final List<Invocation> invocations = <Invocation>[];

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

void main() {
  test('Cover and align', () {
    final TestImage image = new TestImage(width: 300, height: 300);
    final TestCanvas canvas = new TestCanvas();
    paintImage(
      canvas: canvas,
      rect: new Rect.fromLTWH(50.0, 75.0, 200.0, 100.0),
      image: image,
      fit: BoxFit.cover,
      alignment: const FractionalOffset(0.0, 0.5)
    );

    final Invocation command = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #drawImageRect;
    });

    expect(command, isNotNull);
    expect(command.positionalArguments[0], equals(image));
    expect(command.positionalArguments[1], equals(new Rect.fromLTWH(0.0, 75.0, 300.0, 150.0)));
    expect(command.positionalArguments[2], equals(new Rect.fromLTWH(50.0, 75.0, 200.0, 100.0)));
  });

  // See also the DecorationImage tests in: decoration_test.dart
}
