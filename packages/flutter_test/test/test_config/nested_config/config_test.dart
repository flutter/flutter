// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../config_test_utils.dart';

void main() {
  testConfig(
    'cwd config takes precedence over parent config',
    '/test_config/nested_config',
    otherExpectedValues: <Type, dynamic>{int: 123},
  );
}
