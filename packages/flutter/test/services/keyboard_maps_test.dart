// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('The Web physical key mapping do not have entries without a Chrome code.', () {
    // Regression test for https://github.com/flutter/flutter/pull/106074.
    // There is an entry called KBD_ILLUM_DOWN in dom_code_data.inc, but it
    // has an empty "Code" column. This entry should not be present in the
    // web mapping.
    expect(kWebToPhysicalKey['KbdIllumDown'], isNull);
  });
}
