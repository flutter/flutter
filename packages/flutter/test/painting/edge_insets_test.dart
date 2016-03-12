// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'package:test/test.dart';

void main() {
  test("EdgeInsets.lerp()", () {
    EdgeInsets a = new EdgeInsets.all(10.0);
    EdgeInsets b = new EdgeInsets.all(20.0);
    expect(EdgeInsets.lerp(a, b, 0.25), equals(a * 1.25));
    expect(EdgeInsets.lerp(a, b, 0.25), equals(b * 0.625));
    expect(EdgeInsets.lerp(a, b, 0.25), equals(a + const EdgeInsets.all(2.5)));
    expect(EdgeInsets.lerp(a, b, 0.25), equals(b - const EdgeInsets.all(7.5)));
  });
}
