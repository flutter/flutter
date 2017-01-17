// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FractionalOffset control test', () {
    const FractionalOffset offset = const FractionalOffset(0.5, 0.25);

    expect(offset, hasOneLineDescription);
    expect(offset.hashCode, equals(new FractionalOffset(0.5, 0.25).hashCode));

    expect(offset / 2.0, const FractionalOffset(0.25, 0.125));
    expect(offset ~/ 2.0, const FractionalOffset(0.0, 0.0));
    expect(offset % 5.0, const FractionalOffset(0.5, 0.25));
  });

  test('FractionalOffset.lerp()', () {
    FractionalOffset a = FractionalOffset.topLeft;
    FractionalOffset b = FractionalOffset.topCenter;
    expect(FractionalOffset.lerp(a, b, 0.25), equals(new FractionalOffset(0.125, 0.0)));

    expect(FractionalOffset.lerp(null, null, 0.25), isNull);
    expect(FractionalOffset.lerp(null, b, 0.25), equals(b * 0.25));
    expect(FractionalOffset.lerp(a, null, 0.25), equals(a * 0.75));
  });
}
