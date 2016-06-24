// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('copyWith defaults to unchanged values', () {
    SpringForce force = kDefaultSpringForce.copyWith();
    expect(force.spring, kDefaultSpringForce.spring);
    expect(force.left, kDefaultSpringForce.left);
    expect(force.right, kDefaultSpringForce.right);
  });
}
