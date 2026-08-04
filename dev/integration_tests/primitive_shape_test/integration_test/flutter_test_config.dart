// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_goldens/flutter_goldens.dart' as flutter_goldens;

/// Configures [goldenFileComparator] for the test suite using `package:flutter_goldens`.
///
/// On CI/LUCI, if `GOLDCTL` environment variable is present, screenshots taken with
/// `matchesGoldenFile` will be uploaded to Skia Gold.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return flutter_goldens.testExecutable(testMain, namePrefix: 'primitive_shape');
}
