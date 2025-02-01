// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  // This test must start on Line 11 or the test
  // "flutter test should run a test by line number in URI format"
  // in test/integration.shard/test_test.dart updated.
  test('exactTestName', () {
    expect(2 + 2, 4);
  });
  test('not exactTestName', () {
    throw 'this test should have been filtered out';
  });
}
