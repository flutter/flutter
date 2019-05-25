// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('binarySearch', () {
    final List<int> items = <int>[1, 2, 3];

    expect(binarySearch(items, 1), 0);
    expect(binarySearch(items, 2), 1);
    expect(binarySearch(items, 3), 2);
    expect(binarySearch(items, 12), -1);
  });
}
