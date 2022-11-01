// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This tag must be at the top of every test file that executes golden file
// tests. It is analyzer enforced.
@Tags(<String>['reduced-test-set'])

import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';

// Custom matchesGoldenFile wrapper for handling flaky tests
Future<void> expectFlutterGoldenMatches(
    Object key,
    String goldenFile, {
      bool isFlaky = false,
    }) {
  if (isFlaky) {
    print('Flaky!');
    (goldenFileComparator as FlutterGoldenFileComparator).addFlakyTest(goldenFile);
  } else {
    print('Not flaky!');
  }
  return expectLater(key, matchesGoldenFile(goldenFile));
}
