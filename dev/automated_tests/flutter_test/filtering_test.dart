// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  test('included', () {
    expect(2 + 2, 4);
  });
  test('excluded', () {
    throw 'this test should have been filtered out';
  });
}
