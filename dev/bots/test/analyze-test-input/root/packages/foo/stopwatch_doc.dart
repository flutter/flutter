// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Sample Code
///
/// No analysis failures should be found.
///
/// {@tool snippet}
/// Sample invocations of [Stopwatch].
///
/// ```dart
/// Stopwatch();
/// ```
/// {@end-tool}
String? foo;
// Other comments
// Stopwatch();

String literal = 'Stopwatch()'; // flutter_ignore: stopwatch (see analyze.dart)
