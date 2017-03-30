// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'package:test/test.dart';

void main() {
  test('applyBoxFit', () {
    FittedSizes result;

    result = applyBoxFit(BoxFit.scaleDown, const Size(100.0, 1000.0), const Size(200.0, 2000.0));
    expect(result.source, equals(const Size(100.0, 1000.0)));
    expect(result.destination, equals(const Size(100.0, 1000.0)));

    result = applyBoxFit(BoxFit.scaleDown, const Size(300.0, 3000.0), const Size(200.0, 2000.0));
    expect(result.source, equals(const Size(300.0, 3000.0)));
    expect(result.destination, equals(const Size(200.0, 2000.0)));

    result = applyBoxFit(BoxFit.fitWidth, const Size(2000.0, 400.0), const Size(1000.0, 100.0));
    expect(result.source, equals(const Size(2000.0, 200.0)));
    expect(result.destination, equals(const Size(1000.0, 100.0)));

    result = applyBoxFit(BoxFit.fitHeight, const Size(400.0, 2000.0), const Size(100.0, 1000.0));
    expect(result.source, equals(const Size(200.0, 2000.0)));
    expect(result.destination, equals(const Size(100.0, 1000.0)));
  });
}
