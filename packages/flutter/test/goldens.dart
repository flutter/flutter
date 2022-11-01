// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This tag must be at the top of every test file that executes golden file
// tests. It is analyzer enforced.
@Tags(<String>['reduced-test-set'])

import 'package:flutter_test/flutter_test.dart';
import '_goldens_io.dart'
  if (dart.library.html) '_goldens_web.dart' as flutter_goldens;

// Custom matchesGoldenFile wrapper for handling flaky tests
Future<void> expectFlutterGoldenMatches(
    Object key,
    String goldenFile, {
      bool isFlaky = false,
    }) {
  if (isFlaky) {
    (goldenFileComparator as flutter_goldens.FlutterGoldenFileComparator).addFlakyTest(goldenFile);
  }
  return expectLater(key, matchesGoldenFile(goldenFile));
}
