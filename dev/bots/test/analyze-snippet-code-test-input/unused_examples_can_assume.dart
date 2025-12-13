// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is used by ../analyze_snippet_code_test.dart to test detection
// of unused "Examples can assume:" declarations.

// Examples can assume:
// int usedVariable = 42;
// String alsoUsed = 'hello';
// double unusedVariable = 3.14;
// late String neverUsed;

/// Example that uses some preamble declarations
///
/// {@tool snippet}
/// ```dart
/// void example1() {
///   print(usedVariable);
///   print(alsoUsed);
/// }
/// ```
/// {@end-tool}
void function1() {}

/// Another example using only one
///
/// {@tool snippet}
/// ```dart
/// int result = usedVariable + 10;
/// ```
/// {@end-tool}
void function2() {}
