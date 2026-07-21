// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test verifies that ScrollCacheExtent is re-exported from the widgets
// library alone.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ScrollCacheExtent can be initialized from widget library alone', () {
    const viewportExtent = ScrollCacheExtent.viewport(1.0);
    const pixelExtent = ScrollCacheExtent.pixels(100.0);
    expect(viewportExtent, isA<ScrollCacheExtent>());
    expect(pixelExtent, isA<ScrollCacheExtent>());
  });
}
