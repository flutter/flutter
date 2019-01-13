// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show VoidCallback;

/// Whether we've been built in release mode.
const bool _kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// When running in profile mode (or debug mode), invoke the given function.
///
/// In release mode, the function is not invoked.
// TODO(devoncarew): Going forward, we'll want the call to profile() to be tree-shaken out.
void profile(VoidCallback function) {
  if (_kReleaseMode)
    return;
  function();
}
