// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// WindowingOwner used in Flutter Tester.
class TestWindowingOwner extends WindowingOwner {
  @override
  RegularWindowController createRegularWindowController({
    required WindowSizing contentSize,
    required RegularWindowControllerDelegate delegate,
  }) {
    throw UnsupportedError('Current platform does not support windowing.\n');
  }

  @override
  bool hasTopLevelWindows() {
    return false;
  }
}
