// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('BuildConfigOverrides');

Future<Map<String, BuildConfig>> findBuildConfigOverrides(
    PackageGraph packageGraph,
    String configKey,
    RunnerAssetReader reader) async {
  final configs = <String, BuildConfig>{};
  final configFiles =
      reader.findAssets(Glob('*.build.yaml'), package: packageGraph.root.name);
  await for (final id in configFiles) {
    final packageName = p.basename(id.path).split('.').first;
    final packageNode = packageGraph.allPackages[packageName];
    if (packageNode == null) {
      _log.warning('A build config override is provided for $packageName but '
          'that package does not exist. '
          'Remove the ${p.basename(id.path)} override or add a dependency '
          'on $packageName.');
      continue;
    }
    final yaml = await reader.readAsString(id);
    final config = BuildConfig.parse(
      packageName,
      packageNode.dependencies.map((n) => n.name),
      yaml,
      configYamlPath: id.path,
    );
    configs[packageName] = config;
  }
  if (configKey != null) {
    final id = AssetId(packageGraph.root.name, 'build.$configKey.yaml');
    if (!await reader.canRead(id)) {
      _log.warning('Cannot find ${id.path} for specified config.');
      throw CannotBuildException();
    }
    final yaml = await reader.readAsString(id);
    final config = BuildConfig.parse(
      packageGraph.root.name,
      packageGraph.root.dependencies.map((n) => n.name),
      yaml,
      configYamlPath: id.path,
    );
    if (config.builderDefinitions.isNotEmpty) {
      _log.warning(
          'Ignoring `builders` configuration in `build.$configKey.yaml` - '
          'overriding builder configuration is not supported.');
    }
    configs[packageGraph.root.name] = config;
  }
  return configs;
}
