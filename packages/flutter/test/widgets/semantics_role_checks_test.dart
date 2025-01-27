// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('All semantics roles has checks', () {
    expect(SemanticsRole.values.toSet(), DebugSemanticsRoleChecks.kChecks.keys.toSet());
  });
}
