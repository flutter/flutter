// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// This test verifies that the test_release shard is configured correctly.
// See README.md in this directory for more information.
void main() {
  test('kReleaseMode is set to true', () {
    expect(kReleaseMode, true);
  });
}
