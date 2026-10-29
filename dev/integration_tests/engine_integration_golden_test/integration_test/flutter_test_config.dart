// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter_test/flutter_test.dart';
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_goldens/flutter_goldens.dart' as flutter_goldens;

/// Configures [goldenFileComparator] for the test suite using `package:flutter_goldens`.
///
/// On CI/LUCI, if `GOLDCTL` environment variable is present, screenshots taken with
/// `matchesGoldenFile` will be uploaded to Skia Gold.
///
/// On Windows, runs with the engine's D3D11 feature level capped (via the
/// `FLUTTER_WINDOWS_MAX_D3D_FEATURE_LEVEL` environment variable) render
/// differently, so they use a separate set of goldens.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final String? maxFeatureLevel = Platform.environment['FLUTTER_WINDOWS_MAX_D3D_FEATURE_LEVEL'];
  final namePrefix = maxFeatureLevel == null
      ? 'engine_integration_golden'
      : 'engine_integration_golden_feature_level_$maxFeatureLevel';
  return flutter_goldens.testExecutable(testMain, namePrefix: namePrefix);
}
