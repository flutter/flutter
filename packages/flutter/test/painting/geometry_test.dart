// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('positionDependentBox', () {
    // For historical reasons, significantly more tests of this function
    // exist in: ../material/tooltip_test.dart
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(20.0, 10.0),
        target: const Offset(50.0, 50.0),
        preferBelow: false,
        margin: 0.0,
      ),
      const Offset(40.0, 40.0),
    );
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(200.0, 10.0),
        target: const Offset(50.0, 50.0),
        preferBelow: false,
        margin: 0.0,
      ),
      const Offset(-50.0, 40.0),
    );
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(200.0, 10.0),
        target: const Offset(0.0, 50.0),
        preferBelow: false,
        margin: 0.0,
      ),
      const Offset(-50.0, 40.0),
    );
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(200.0, 10.0),
        target: const Offset(100.0, 50.0),
        preferBelow: false,
        margin: 0.0,
      ),
      const Offset(-50.0, 40.0),
    );
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(50.0, 10.0),
        target: const Offset(50.0, 50.0),
        preferBelow: false,
        margin: 20.0, // 60.0 left
      ),
      const Offset(25.0, 40.0),
    );
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(50.0, 10.0),
        target: const Offset(50.0, 50.0),
        preferBelow: false,
        margin: 30.0, // 40.0 left
      ),
      const Offset(25.0, 40.0),
    );
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(50.0, 10.0),
        target: const Offset(0.0, 50.0),
        preferBelow: false,
        margin: 20.0, // 60.0 left
      ),
      const Offset(20.0, 40.0),
    );
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(50.0, 10.0),
        target: const Offset(0.0, 50.0),
        preferBelow: false,
        margin: 30.0, // 40.0 left
      ),
      const Offset(25.0, 40.0),
    );
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(50.0, 10.0),
        target: const Offset(100.0, 50.0),
        preferBelow: false,
        margin: 20.0, // 60.0 left
      ),
      const Offset(30.0, 40.0),
    );
    expect(
      positionDependentBox(
        size: const Size(100.0, 100.0),
        childSize: const Size(50.0, 10.0),
        target: const Offset(100.0, 50.0),
        preferBelow: false,
        margin: 30.0, // 40.0 left
      ),
      const Offset(25.0, 40.0),
    );
  });
}
