// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher throwsAssertionWith(String messageSubString) {
  if (kIsWasm) {
    // dart2wasm doesn't include all necessary information in the assertion's
    // message string.
    // See https://github.com/dart-lang/sdk/issues/55317
    return throwsA(isA<AssertionError>());
  }
  return throwsA(
      isA<AssertionError>().having(
          (AssertionError e) => e.toString(),
          'description',
          contains(messageSubString),
      ),
  );
}
