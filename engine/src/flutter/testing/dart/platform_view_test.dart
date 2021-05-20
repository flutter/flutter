// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:litetest/litetest.dart';

void main() {
  test('PlatformView layers do not emit errors from tester', () async {
    final SceneBuilder builder = SceneBuilder();
    builder.addPlatformView(1);
    final Scene scene = builder.build();

    window.render(scene);
    scene.dispose();
    // Test harness asserts that this does not emit an error from the shell logs.
  });
}
