// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/time.dart';

import 'src/common.dart';

void main() {
  group(SystemClock, () {
    test('can set a fixed time', () {
      final SystemClock clock = SystemClock.fixed(DateTime(1991, 8, 23));
      expect(clock.now(), DateTime(1991, 8, 23));
    });

    test('can find a time ago', () {
      final SystemClock clock = SystemClock.fixed(DateTime(1991, 8, 23));
      expect(clock.ago(const Duration(days: 10)), DateTime(1991, 8, 13));
    });
  });
}
