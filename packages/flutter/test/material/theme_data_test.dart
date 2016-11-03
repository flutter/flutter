// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Defaults to the default typography for the platform', () {
    for (TargetPlatform platform in TargetPlatform.values) {
      ThemeData theme = new ThemeData(platform: platform);
      Typography typography = new Typography(platform: platform);
      expect(theme.textTheme, typography.black, reason: 'Not using default typography for $platform');
    }
  });
}
