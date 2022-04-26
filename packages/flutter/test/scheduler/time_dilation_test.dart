// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart' show test, expect;

// This file should not use testWidgets, and should not instantiate the binding.

void main() {
  test('timeDilation can be set without a binding', () {
    expect(timeDilation, 1.0);
    timeDilation = 2.0;
    expect(timeDilation, 2.0);
  });
}
