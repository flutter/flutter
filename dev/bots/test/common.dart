// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:test/test.dart' as test_package show TypeMatcher;

export 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

// Defines a 'package:test' shim.
// TODO(ianh): Remove this file once https://github.com/dart-lang/matcher/issues/98 is fixed

/// A matcher that compares the type of the actual value to the type argument T.
test_package.TypeMatcher<T> isInstanceOf<T>() => isA<T>();

void tryToDelete(Directory directory) {
  // This should not be necessary, but it turns out that
  // on Windows it's common for deletions to fail due to
  // bogus (we think) "access denied" errors.
  try {
    directory.deleteSync(recursive: true);
  } on FileSystemException catch (error) {
    print('Failed to delete ${directory.path}: $error');
  }
}
