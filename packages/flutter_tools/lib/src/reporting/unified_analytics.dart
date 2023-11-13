// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../base/io.dart';
import '../build_info.dart';
import '../dart/language_version.dart';
import '../globals.dart' as globals;
import '../version.dart';

/// This function is called from within the context runner to perform
/// checks that are necessary for determining if a no-op version of
/// [Analytics] gets returned.
///
/// When [enableAsserts] is set to `true`, various assert statements
/// will be enabled to ensure usage of this class is within GA4 limitations.
///
/// For testing purposes, pass in a [FakeAnalytics] instance initialized with
/// an in-memory [FileSystem] to prevent writing to disk.
Analytics getAnalytics({
  required bool runningOnBot,
  required FlutterVersion flutterVersion,
  required Map<String, String> environment,
  required String? clientIde,
  bool enableAsserts = false,
  FakeAnalytics? analyticsOverride,
}) {
  final String version = flutterVersion.getVersionString(redactUnknownBranches: true);
  final bool suppressEnvFlag = environment['FLUTTER_SUPPRESS_ANALYTICS']?.toLowerCase() == 'true';

  if (// Ignore local user branches.
      version.startsWith('[user-branch]') ||
      // Many CI systems don't do a full git checkout.
      version.endsWith('/unknown') ||
      // Ignore bots.
      runningOnBot ||
      // Ignore when suppressed by FLUTTER_SUPPRESS_ANALYTICS.
      suppressEnvFlag) {
    return NoOpAnalytics();
  }

  // Providing an override of the [Analytics] instance is preferred when
  // running tests for this function to prevent writing to the filesystem
  if (analyticsOverride != null) {
    return analyticsOverride;
  }

  return Analytics(
    tool: DashTool.flutterTool,
    flutterChannel: flutterVersion.channel,
    flutterVersion: flutterVersion.frameworkVersion,
    dartVersion: flutterVersion.dartSdkVersion,
    enableAsserts: enableAsserts,
    clientIde: clientIde,
  );
}

/// Function to safely grab the max rss from [ProcessInfo].
int? getMaxRss(ProcessInfo processInfo) {
  try {
    return globals.processInfo.maxRss;
  } on Exception catch (error) {
    globals.printTrace('Querying maxRss failed with error: $error');
  }
  return null;
}

/// Get the analytics related informatin for null safety analysis within
/// a flutter package for reporting.
Map<String, Object>? getNullSafetyAnalysisInfo({
  required PackageConfig packageConfig,
  required NullSafetyMode nullSafetyMode,
  required String currentPackage,
}) {
  if (packageConfig.packages.isEmpty) {
    return null;
  }
  int migrated = 0;
  LanguageVersion? languageVersion;
  for (final Package package in packageConfig.packages) {
    final LanguageVersion? packageLanguageVersion = package.languageVersion;
    if (package.name == currentPackage) {
      languageVersion = packageLanguageVersion;
    }
    if (packageLanguageVersion != null &&
        packageLanguageVersion.major >= nullSafeVersion.major &&
        packageLanguageVersion.minor >= nullSafeVersion.minor) {
      migrated += 1;
    }
  }
  final Map<String, Object> results = <String, Object>{
    'runtimeMode': nullSafetyMode.toString(),
    'nullSafeMigratedLibraries': migrated,
    'nullSafeTotalLibraries': packageConfig.packages.length,
  };
  if (languageVersion != null) {
    final String formattedVersion = '${languageVersion.major}.${languageVersion.minor}';
    results['languageVersion'] = formattedVersion;
  }

  return results;
}
