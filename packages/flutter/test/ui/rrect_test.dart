// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'package:test/test.dart';

void main() {
  test("RRect.contains()", () {
    RRect rrect = new RRect.fromRectCustom(
      new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
      new Radius.circular(0.5),
      new Radius.circular(0.25),
      new Radius.elliptical(0.25, 0.75),
      Radius.zero
    );

    expect(rrect.contains(new Point(1.0, 1.0)), equals(false));
    expect(rrect.contains(new Point(1.1, 1.1)), equals(false));
    expect(rrect.contains(new Point(1.15, 1.15)), equals(true));
    expect(rrect.contains(new Point(2.0, 1.0)), equals(false));
    expect(rrect.contains(new Point(1.93, 1.07)), equals(false));
    expect(rrect.contains(new Point(1.97, 1.7)), equals(false));
    expect(rrect.contains(new Point(1.7, 1.97)), equals(true));
    expect(rrect.contains(new Point(1.0, 1.99)), equals(true));
  });

  test("RRect.contains() large radii", () {
    RRect rrect = new RRect.fromRectCustom(
      new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
      new Radius.circular(5000.0),
      new Radius.circular(2500.0),
      new Radius.elliptical(2500.0, 7500.0),
      Radius.zero
    );

    expect(rrect.contains(new Point(1.0, 1.0)), equals(false));
    expect(rrect.contains(new Point(1.1, 1.1)), equals(false));
    expect(rrect.contains(new Point(1.15, 1.15)), equals(true));
    expect(rrect.contains(new Point(2.0, 1.0)), equals(false));
    expect(rrect.contains(new Point(1.93, 1.07)), equals(false));
    expect(rrect.contains(new Point(1.97, 1.7)), equals(false));
    expect(rrect.contains(new Point(1.7, 1.97)), equals(true));
    expect(rrect.contains(new Point(1.0, 1.99)), equals(true));
  });
}
