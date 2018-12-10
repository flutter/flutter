// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

void main() {
  test('Trivial test', () {
    expect(42, 42);
  });
}
