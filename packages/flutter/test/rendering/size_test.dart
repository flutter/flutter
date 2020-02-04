// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

import 'rendering_tester.dart';

void main() {
  test('Stack can layout with top, right, bottom, left 0.0', () {
    final RenderBox box = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)));

    layout(box, constraints: const BoxConstraints());

    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));
    expect(box.size, equals(const Size(100.0, 100.0)));
    expect(box.size.runtimeType.toString(), equals('_DebugSize'));
  });
}
