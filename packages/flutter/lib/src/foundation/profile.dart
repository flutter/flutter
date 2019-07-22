// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic_types.dart';
import 'constants.dart';

/// DEPRECATED. `function` cannot be treeshaken out of release builds.
///
/// Instead use:
///
/// ```dart
/// if (!kReleaseMode) {
///   function();
/// }
/// ```
@Deprecated('Use `if (!kReleaseMode) { function(); }` instead')
void profile(VoidCallback function) {
  if (kReleaseMode)
    return;
  function();
}
