// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is used by ../analyze_snippet_code_test.dart to test detection
// of unused imports in "Examples can assume:" declarations.

// Examples can assume:
// import 'dart:async';
// import 'dart:math' as math;

/// Example that doesn't use the imports
///
/// {@tool snippet}
/// ```dart
/// void example() {
///   print('Hello');
/// }
/// ```
/// {@end-tool}
void function1() {}
