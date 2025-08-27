// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'package:flutter/foundation.dart';

/// Whether or not Flutter CI has configured Impeller for this test run.
///
/// This is intended only to be used for a migration effort to enable Impeller
/// on Flutter CI.
///
/// See also: https://github.com/flutter/flutter/issues/143616
bool get impellerEnabled {
  if (kIsWeb) {
    return false;
  }
  return io.Platform.environment.containsKey('FLUTTER_TEST_IMPELLER');
}
