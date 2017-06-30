// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:test/test.dart';

const bool isReleaseMode = const bool.fromEnvironment("dart.vm.product");

void main() {
  test("profile invokes its closure in debug or profile mode", () {
    int count = 0;
    profile(() {
      count++;
    });
    expect(count, isReleaseMode ? 0 : 1);
  });
}
