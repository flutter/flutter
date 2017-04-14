// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('Stack can layout with top, right, bottom, left 0.0', () {
    final RenderBox size = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tight(const Size(100.0, 100.0))
    );

    final RenderBox red = new RenderDecoratedBox(
      decoration: const BoxDecoration(
        backgroundColor: const Color(0xFFFF0000)
      ),
      child: size
    );

    final RenderBox green = new RenderDecoratedBox(
      decoration: const BoxDecoration(
        backgroundColor: const Color(0xFFFF0000)
      )
    );

    final RenderBox stack = new RenderStack(children: <RenderBox>[red, green]);
    final StackParentData greenParentData = green.parentData;
    greenParentData
      ..top = 0.0
      ..right = 0.0
      ..bottom = 0.0
      ..left = 0.0;

    layout(stack, constraints: const BoxConstraints());

    expect(stack.size.width, equals(100.0));
    expect(stack.size.height, equals(100.0));

    expect(red.size.width, equals(100.0));
    expect(red.size.height, equals(100.0));

    expect(green.size.width, equals(100.0));
    expect(green.size.height, equals(100.0));
  });

  // More tests in ../widgets/stack_test.dart
}
