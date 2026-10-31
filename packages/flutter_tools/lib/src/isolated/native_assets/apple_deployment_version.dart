// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';

import '../../base/common.dart';
import '../../base/version.dart';

/// Resolves an app deployment target, retaining the native-assets platform floor.
AppleVersion parseAppleDeploymentVersion(
  String? deploymentTarget, {
  required String platform,
  required int minimumVersion,
}) {
  final minimum = AppleVersion(minimumVersion);
  final String? target = deploymentTarget?.trim();
  if (target == null || target.isEmpty) {
    return minimum;
  }

  Never invalidTarget() => throwToolExit(
    'Invalid $platform deployment target "$deploymentTarget". '
    'Expected one to three numeric components, such as 16, 16.4, or 17.2.1, '
    'each between 0 and 2147483647.',
  );

  final Version? parsed = Version.parse(target);
  if (parsed == null || Version.versionPattern.firstMatch(target)?.end != target.length) {
    invalidTarget();
  }
  final AppleVersion version;
  try {
    version = AppleVersion(parsed.major, minor: parsed.minor, patch: parsed.patch);
  } on ArgumentError {
    invalidTarget();
  }
  return version < minimum ? minimum : version;
}
