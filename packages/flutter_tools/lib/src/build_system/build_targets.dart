// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../base/file_system.dart';
import '../web/compiler_config.dart';
import 'build_system.dart';

/// Commonly used build [Target]s.
abstract class BuildTargets {
  const BuildTargets();

  Target get copyFlutterBundle;
  Target get releaseCopyFlutterBundle;
  Target get generateLocalizationsTarget;
  Target get dartPluginRegistrantTarget;
  Target webServiceWorker(
    FileSystem fileSystem,
    List<WebCompilerConfig> compileConfigs,
    Analytics analytics,
  );
}
