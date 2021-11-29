// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../src/common.dart';

// This is a test that we can use to close the tree until
// https://github.com/flutter/flutter/issues/74529 is addressed.

void main() {
  test('Fail unconditionally', () { // ignore: void_checks
    fail('Failing to close the tree for https://github.com/flutter/flutter/issues/94356');
  }); // Skip this test to re-open the tree.
}
