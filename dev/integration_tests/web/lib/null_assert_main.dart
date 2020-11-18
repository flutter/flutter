// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'null_enabled_api.dart';

void main() {
  dynamic error;
  try {
    // Validate that a generated null assertion is thrown.
    methodThatAcceptsNonNull(null);
  } catch (err) {
    error = err;
  }
  if (error is AssertionError) {
    print('--- TEST SUCCEEDED ---');
  } else {
    print('--- TEST FAILED ---');
  }
}
