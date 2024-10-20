// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_driver/src/common/error.dart';
import 'package:test/test.dart';

export 'package:test/fake.dart';
export 'package:test/test.dart';

void tryToDelete(Directory directory) {
  // This should not be necessary, but it turns out that
  // on Windows it's common for deletions to fail due to
  // bogus (we think) "access denied" errors.
  try {
    directory.deleteSync(recursive: true);
  } on FileSystemException catch (error) {
    driverLog('test', 'Failed to delete ${directory.path}: $error');
  }
}

/// Matcher for functions that throw [DriverError].
final Matcher throwsDriverError = throwsA(isA<DriverError>());
