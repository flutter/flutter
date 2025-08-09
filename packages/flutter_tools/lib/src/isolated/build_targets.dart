// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/build_targets.dart';
import '../build_system/targets/common.dart';
import '../build_system/targets/dart_plugin_registrant.dart';
import '../build_system/targets/linux.dart';
import '../build_system/targets/localizations.dart';
import '../build_system/targets/web.dart';
import '../web/compiler_config.dart';

class BuildTargetsImpl extends BuildTargets {
  const BuildTargetsImpl();

  @override
  Target get generateLocalizationsTarget => const GenerateLocalizationsTarget();

  @override
  Target get dartPluginRegistrantTarget => const DartPluginRegistrantTarget();

  @override
  Target webServiceWorker(
    FileSystem fileSystem,
    List<WebCompilerConfig> compileConfigs,
    Analytics analytics,
  ) => WebServiceWorker(fileSystem, compileConfigs, analytics);

  @override
  Target buildFlutterBundle({
    required TargetPlatform platform,
    required BuildMode mode,
    bool buildAOTAssets = true,
    @Deprecated(
      'Use the build environment `outputDir` instead. '
      'This feature was deprecated after v3.31.0-1.0.pre.',
    )
    Directory? assetDir,
  }) {
    if (!buildAOTAssets || mode == BuildMode.debug) {
      return mode == BuildMode.debug
          ? CopyFlutterBundle(assetDir: assetDir)
          : ReleaseCopyFlutterBundle(assetDir: assetDir);
    }

    switch (platform) {
      case TargetPlatform.linux_x64:
      case TargetPlatform.linux_arm64:
        return mode == BuildMode.profile
            ? ProfileBundleLinuxAssets(platform, unpackDesktopEmbedder: false)
            : ReleaseBundleLinuxAssets(platform, unpackDesktopEmbedder: false);
      case _:
        // Fall back to just copying the bundle assets until support for other platforms is implemented.
        return ReleaseCopyFlutterBundle(assetDir: assetDir);
    }
  }
}
