// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regex that matches a version number at the beginning of a string.
final startVersion = RegExp(r'^' // Start at beginning.
    r'(\d+)\.(\d+)\.(\d+)' // Version number.
    r'(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?' // Pre-release.
    r'(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?'); // Build.

/// Like [startVersion] but matches the entire string.
final completeVersion = RegExp('${startVersion.pattern}\$');

/// Parses a comparison operator ("<", ">", "<=", or ">=") at the beginning of
/// a string.
final startComparison = RegExp(r'^[<>]=?');

/// The "compatible with" operator.
const compatibleWithChar = '^';
