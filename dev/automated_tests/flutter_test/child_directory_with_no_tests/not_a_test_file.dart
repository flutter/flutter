// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// File that does not end in "_test".

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('I should not run', () {
    expect(1, 1, reason: 'Test should succeed');
  });
}
