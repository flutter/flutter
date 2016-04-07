// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'package:test/test.dart';

void main() {
  test("Decoration.lerp()", () {
    BoxDecoration a = new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF));
    BoxDecoration b = new BoxDecoration(backgroundColor: const Color(0x00000000));

    BoxDecoration c = Decoration.lerp(a, b, 0.0);
    expect(c.backgroundColor, equals(a.backgroundColor));

    c = Decoration.lerp(a, b, 0.25);
    expect(c.backgroundColor, equals(Color.lerp(const Color(0xFFFFFFFF), const Color(0x00000000), 0.25)));

    c = Decoration.lerp(a, b, 1.0);
    expect(c.backgroundColor, equals(b.backgroundColor));
  });
}
