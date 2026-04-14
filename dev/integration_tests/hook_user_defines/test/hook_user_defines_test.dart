// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:hook_user_defines/hook_user_defines.dart';
import 'package:test/test.dart';

void main() {
  test('invoke native function', () {
    const magicValue = 1000;
    expect(sum(24, 18), 42 + magicValue);
  });
}
