// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart';
import 'package:logging/logging.dart';

import '../package_graph/apply_builders.dart';

/// Checks that all configuration is for valid builder keys.
void validateBuilderConfig(
    Iterable<BuilderApplication> builders,
    BuildConfig rootPackageConfig,
    Map<String, Map<String, dynamic>> builderConfigOverrides,
    Logger logger) {
  final builderKeys = builders.map((b) => b.builderKey).toSet();
  for (final key in builderConfigOverrides.keys) {
    if (!builderKeys.contains(key)) {
      logger.warning('Overriding configuration for `$key` but this is not a '
          'known Builder');
    }
  }
  for (final target in rootPackageConfig.buildTargets.values) {
    for (final key in target.builders.keys) {
      if (!builderKeys.contains(key)) {
        logger.warning('Configuring `$key` in target `${target.key}` but this '
            'is not a known Builder');
      }
    }
  }
  for (final key in rootPackageConfig.globalOptions.keys) {
    if (!builderKeys.contains(key)) {
      logger.warning('Configuring `$key` in global options but this is not a '
          'known Builder');
    }
  }
}
