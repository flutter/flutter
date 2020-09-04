// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gravity simulation', () {
    expect(GravitySimulation(9.81, 10.0, 0.0, 0.0), hasOneLineDescription);
    expect(GravitySimulation(9.81, 10.0, 0.0, 0.0).x(10.0), moreOrLessEquals(50.0 * 9.81 + 10.0));
  });
}
