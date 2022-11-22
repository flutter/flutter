// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')

import 'package:flutter_test/flutter_test.dart';

// Regression test for: https://github.com/dart-lang/sdk/issues/47207
// Needs: https://github.com/dart-lang/sdk/commit/6c4593929f067af259113eae5dc1b3b1c04f1035 to pass.
// Originally here: https://github.com/flutter/engine/pull/28808
void main() {
  test('Web library environment define exists', () {
    expect(const bool.fromEnvironment('dart.library.js_util'), isTrue);
    expect(const bool.fromEnvironment('dart.library.someFooLibrary'), isFalse);
  });
}
