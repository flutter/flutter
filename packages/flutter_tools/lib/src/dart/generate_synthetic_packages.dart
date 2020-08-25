// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/localizations.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';

Future<void> generateLocalizationsSyntheticPackage(FlutterProject flutterProject) async {
  final Environment environment = Environment(
    artifacts: globals.artifacts,
    logger: globals.logger,
    cacheDir: globals.cache.getRoot(),
    engineVersion: globals.flutterVersion.engineRevision,
    fileSystem: globals.fs,
    flutterRootDir: globals.fs.directory(Cache.flutterRoot),
    outputDir: globals.fs.directory(getBuildDirectory()),
    processManager: globals.processManager,
    projectDir: flutterProject.directory,
  );
  final BuildResult result = await globals.buildSystem.build(
    const GenerateLocalizationsTarget(),
    environment,
  );
  if (result.hasException) {
    throwToolExit('Generating synthetic localizations package has failed.');
  }
}
