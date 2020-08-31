// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/localizations.dart';

Future<void> generateLocalizationsSyntheticPackage({
  @required Environment environment,
  @required BuildSystem buildSystem,
}) async {
  assert(environment != null);
  assert(buildSystem != null);

  final FileSystem fileSystem = environment.fileSystem;
  final File l10nYamlFile = fileSystem.file(
    fileSystem.path.join(environment.projectDir.path, 'l10n.yaml'));

  // If pubspec.yaml has generate:true and if l10n.yaml exists in the
  // root project directory, check to see if a synthetic package should
  // be generated for gen_l10n.
  if (!l10nYamlFile.existsSync()) {
    return;
  }

  final YamlNode yamlNode = loadYamlNode(l10nYamlFile.readAsStringSync());
  if (yamlNode.value != null && yamlNode is! YamlMap) {
    throwToolExit(
      'Expected ${l10nYamlFile.path} to contain a map, instead was $yamlNode'
    );
  }

  BuildResult result;
  // If an l10n.yaml file exists but is empty, attempt to build synthetic
  // package with default settings.
  if (yamlNode.value == null) {
    result = await buildSystem.build(
      const GenerateLocalizationsTarget(),
      environment,
    );
  } else {
    final YamlMap yamlMap = yamlNode as YamlMap;
    final Object value = yamlMap['synthetic-package'];
    if (value is! bool && value != null) {
      throwToolExit(
        'Expected "synthetic-package" to have a bool value, '
        'instead was "$value"'
      );
    }

    // Generate gen_l10n synthetic package only if synthetic-package: true or
    // synthetic-package is null.
    final bool isSyntheticL10nPackage = value as bool ?? true;
    if (!isSyntheticL10nPackage) {
      return;
    }
  }

  result = await buildSystem.build(
    const GenerateLocalizationsTarget(),
    environment,
  );

  if (result == null || result.hasException) {
    throwToolExit('Generating synthetic localizations package has failed.');
  }
}
