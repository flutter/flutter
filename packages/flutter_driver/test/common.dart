// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_driver/src/common/error.dart';
import 'package:test_api/test_api.dart'; // ignore: deprecated_member_use

export 'package:test_api/fake.dart'; // ignore: deprecated_member_use
export 'package:test_api/test_api.dart' hide isInstanceOf; // ignore: deprecated_member_use

/// A matcher that compares the type of the actual value to the type argument T.
TypeMatcher<T> isInstanceOf<T>() => isA<T>();

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

/// Matcher for functions that throw [DriverError].
final Matcher throwsDriverError = throwsA(isA<DriverError>());

/// Matcher for functions that throw [AssertionError].
final Matcher throwsAssertionError = throwsA(isA<AssertionError>());
