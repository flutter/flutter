// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/physics/tolerance.dart';

import 'package:flutter_test/src/matchers.dart';
import 'package:flutter_test/src/test_compat.dart';
import 'package:flutter_test/src/widget_tester.dart';

void main() {
  test('Tolerance control test', () {
    expect(Tolerance.defaultTolerance, hasOneLineDescription);
  });
}
