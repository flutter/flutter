// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nearEquals', () {
    expect(nearEqual(double.infinity, double.infinity, 0.1), isTrue);
    expect(nearEqual(double.negativeInfinity, double.negativeInfinity, 0.1), isTrue);

    expect(nearEqual(double.infinity, double.negativeInfinity, 0.1), isFalse);

    expect(nearEqual(0.1, 0.11, 0.001), isFalse);
    expect(nearEqual(0.1, 0.11, 0.1), isTrue);
    expect(nearEqual(0.1, 0.1, 0.0000001), isTrue);
  });
}
