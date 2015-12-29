// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_sprites/flutter_sprites.dart';
import 'package:test/test.dart';

void main() {
  test("Simple test of ColorSequence", () {
    List<Color> colors = <Color>[const Color(0xFFFFFFFF), const Color(0x000000FF)];
    List<double> stops = <double>[0.0, 1.0];
    ColorSequence cs = new ColorSequence(colors, stops);
    expect(cs.colorAtPosition(0.0), equals(const Color(0xFFFFFFFF)));
    expect(cs.colorAtPosition(0.5), equals(const Color(0x7F7F7FFF)));
    expect(cs.colorAtPosition(1.0), equals(const Color(0x000000FF)));
  });
}
