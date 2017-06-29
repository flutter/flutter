// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:test/test.dart';

void main() {
  test("profile invokes its closure in debug or profile mode", () {
    int count = 0;
    profile(() {
      count++;
    });
    expect(count, kReleaseMode ? 0 : 1);
  });
}
