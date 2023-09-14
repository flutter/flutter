// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../version.dart';

/// This function is called from within the context runner to perform
/// checks that are necessary for determining if a no-op version of
/// [Analytics] gets returned.
Analytics getAnalytics({
  required bool runningOnBot,
  required FlutterVersion flutterVersion,
  required bool suppressEnvFlag,
}) {
  final String version =
      flutterVersion.getVersionString(redactUnknownBranches: true);
  if (
      // Ignore local user branches.
      version.startsWith('[user-branch]') ||
          // Many CI systems don't do a full git checkout.
          version.endsWith('/unknown') ||
          // Ignore bots.
          runningOnBot ||
          // Ignore when suppressed by FLUTTER_SUPPRESS_ANALYTICS.
          suppressEnvFlag) {
    return NoOpAnalytics();
  }
  return Analytics(
    tool: DashTool.flutterTool,
    flutterChannel: flutterVersion.channel,
    flutterVersion: flutterVersion.frameworkVersion,
    dartVersion: flutterVersion.dartSdkVersion,
  );
}
