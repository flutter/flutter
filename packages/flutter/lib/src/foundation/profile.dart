// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic_types.dart';
import 'constants.dart';

/// DEPRECATED. `function` cannot be tree-shaken out of release builds.
///
/// Instead use:
///
/// ```dart
/// if (!kReleaseMode) {
///   function();
/// }
/// ```
@Deprecated(
  'Use `if (!kReleaseMode) { function(); }` instead. '
  'This feature was deprecated after v1.3.9.'
)
void profile(VoidCallback function) {
  if (kReleaseMode)
    return;
  function();
}
