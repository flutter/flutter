// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'package:test/test.dart';

void main() {
  test("EdgeDims.lerp()", () {
    EdgeDims a = new EdgeDims.all(10.0);
    EdgeDims b = new EdgeDims.all(20.0);
    expect(EdgeDims.lerp(a, b, 0.25), equals(a * 1.25));
    expect(EdgeDims.lerp(a, b, 0.25), equals(b * 0.625));
    expect(EdgeDims.lerp(a, b, 0.25), equals(a + const EdgeDims.all(2.5)));
    expect(EdgeDims.lerp(a, b, 0.25), equals(b - const EdgeDims.all(7.5)));
  });
}
