// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test("Describe transform control test", () {
    Matrix4 identity = new Matrix4.identity();
    List<String> description = debugDescribeTransform(identity);
    expect(description, equals(<String>[
      '  [0] 1.0,0.0,0.0,0.0',
      '  [1] 0.0,1.0,0.0,0.0',
      '  [2] 0.0,0.0,1.0,0.0',
      '  [3] 0.0,0.0,0.0,1.0',
    ]));
  });
}
