// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/localizations.dart';

Future<void> generateLocalizationsSyntheticPackage(
  Environment environment,
  BuildSystem buildSystem,
) async {
  assert(environment != null);
  assert(buildSystem != null);

  final BuildResult result = await buildSystem.build(
    const GenerateLocalizationsTarget(),
    environment,
  );

  if (result != null && result.hasException) {
    throwToolExit('Generating synthetic localizations package has failed.');
  }
}
