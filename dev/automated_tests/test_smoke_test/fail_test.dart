// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

// this is a test to make sure our tests actually catch failures
// see //flutter/dev/bots/test.dart

void main() {
  test('test smoke test -- this test SHOULD FAIL', () async {
    expect(false, isTrue);
  });
}
