// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';

import '../flutter_test_alternative.dart';

void main() {
  test('test_friction', () {
    expect(nearEqual(5.0, 6.0, 2.0), isTrue);
    expect(nearEqual(6.0, 5.0, 2.0), isTrue);
    expect(nearEqual(5.0, 6.0, 0.5), isFalse);
    expect(nearEqual(6.0, 5.0, 0.5), isFalse);
  });

  test('test_null', () {
    expect(nearEqual(5.0, null, 2.0), isFalse);
    expect(nearEqual(null, 5.0, 2.0), isFalse);
    expect(nearEqual(null, null, 2.0), isTrue);
  });
}
